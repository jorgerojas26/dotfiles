// herdr-toggle.go — toggle a persistent tool as a named tab in the workspace
// you invoke it from.
//
// Approach: each tool lives as its own named tab (label = tool name) inside
// the CURRENT workspace. First press creates the tab (or focuses the existing
// one) and starts the command there; pressing again returns you to the tab you
// were on, exactly where you left it. The tool keeps running in the
// background; if it was quit inside its tab, toggling it on restarts it in
// your current directory. Switching tools works as an LIFO stack: if you are
// on the mprocs tab and press ctrl+\ (lazysql), you get lazysql and the next
// lazysql press returns you to mprocs.
//
// This replaces herdr-toggle.py, which kept every tool instance in a shared
// hidden "tools" workspace (one tab per project/tool) to leave project layouts
// untouched. The new design keeps each tool per checkout — its own named tab
// in the tab bar of the workspace you toggled from — and drops the extra
// "tools" sidebar row entirely.
//
// The whole toggle talks to the herdr daemon over its UNIX-socket API (one
// short-lived connection per request, sub-millisecond acks). No herdr CLI
// spawns on the hot path. State is a small JSON file keyed by workspace id,
// so nothing is lost across toggles and stale workspaces are pruned.
//
// Runs as a herdr custom command (type = "shell"), e.g.:
//
//	[[keys.command]]
//	key = "ctrl+\\"
//	type = "shell"
//	command = "~/.dotfiles/scripts/shell/herdr-toggle lazysql 'export PATH=\"$HOME/.go/bin:$PATH\" && lazysql'"
//	description = "lazysql (toggle)"
//
// Build:  go build -o herdr-toggle herdr-toggle.go
// Usage:  herdr-toggle <name> '<shell command>'
package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const requestTimeout = 3 * time.Second

var shells = map[string]bool{
	"zsh": true, "bash": true, "fish": true, "sh": true, "dash": true, "ksh": true,
}

// herdr daemon response/request types -------------------------------------------------

type workspaceInfo struct {
	WorkspaceID string `json:"workspace_id"`
	Label       string `json:"label"`
	Focused     bool   `json:"focused"`
}

type tabInfo struct {
	TabID       string `json:"tab_id"`
	WorkspaceID string `json:"workspace_id"`
	Label       string `json:"label"`
	Focused     bool   `json:"focused"`
}

type paneInfo struct {
	PaneID string `json:"pane_id"`
	TabID  string `json:"tab_id"`
}

type workspaceListResult struct {
	Workspaces []workspaceInfo `json:"workspaces"`
}

type tabListResult struct {
	Tabs []tabInfo `json:"tabs"`
}

type paneListResult struct {
	Panes []paneInfo `json:"panes"`
}

type tabCreatedResult struct {
	Tab      tabInfo  `json:"tab"`
	RootPane paneInfo `json:"root_pane"`
}

type paneCurrentResult struct {
	Pane paneInfo `json:"pane"`
}

type procInfoResult struct {
	ProcessInfo struct {
		ForegroundProcesses []struct {
			Name string `json:"name"`
		} `json:"foreground_processes"`
	} `json:"process_info"`
}

// Client is a thin client for the herdr daemon's UNIX-socket API. The daemon
// serves one request per connection, so each call dials fresh, sends one
// newline-framed {id, method, params} JSON line, and reads until the response
// carrying our id (unsolicited event lines with other ids are skipped).
type Client struct {
	sock string
	seq  int
}

func (c *Client) call(method string, params any, out any) error {
	c.seq++
	id := fmt.Sprintf("t%d", c.seq)

	conn, err := net.DialTimeout("unix", c.sock, requestTimeout)
	if err != nil {
		return err
	}
	defer conn.Close()
	conn.SetDeadline(time.Now().Add(requestTimeout))

	req, err := json.Marshal(map[string]any{"id": id, "method": method, "params": params})
	if err != nil {
		return err
	}
	if _, err := conn.Write(append(req, '\n')); err != nil {
		return err
	}

	sc := bufio.NewScanner(conn)
	sc.Buffer(make([]byte, 64*1024), 1024*1024)
	for sc.Scan() {
		var frame map[string]json.RawMessage
		if err := json.Unmarshal(sc.Bytes(), &frame); err != nil {
			continue
		}
		var fid string
		if err := json.Unmarshal(frame["id"], &fid); err != nil || fid != id {
			continue // unsolicited event line
		}
		if _, hasErr := frame["error"]; hasErr {
			return fmt.Errorf("%s refused: %s", method, strings.TrimSpace(sc.Text()))
		}
		if out == nil {
			return nil
		}
		return json.Unmarshal(frame["result"], out)
	}
	if err := sc.Err(); err != nil {
		return err
	}
	return errors.New(method + ": no response from daemon")
}

// tool toggle state ---------------------------------------------------------------

// stateEntry remembers where we came from, per workspace. Keyed by workspace
// id because tabs now live inside the workspace you toggle from (each checkout
// owns its own tool tabs).
type stateEntry struct {
	LastTab    string `json:"last_tab"`    // tab that was active before the tool tab was focused
	OriginPane string `json:"origin_pane"` // exact pane we toggled from (split-tab safe)
}

type toolState map[string]stateEntry

func statePath(name string) string {
	dir := os.Getenv("HERDR_TOGGLE_STATE_DIR")
	if dir == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			home = "~"
		}
		dir = filepath.Join(home, ".herdr", "toggles")
	}
	return filepath.Join(expandPath(dir), name+".json")
}

func loadState(name string) toolState {
	st := toolState{}
	raw, err := os.ReadFile(statePath(name))
	if err != nil {
		return st
	}
	_ = json.Unmarshal(raw, &st)
	return st
}

func saveState(name string, st toolState, live map[string]bool) {
	for ws := range st {
		if !live[ws] {
			delete(st, ws) // workspace closed/recreated: prune stale entries
		}
	}
	raw, err := json.MarshalIndent(st, "", "  ")
	if err != nil {
		return
	}
	_ = os.WriteFile(statePath(name), append(raw, '\n'), 0o644)
}

// helpers ---------------------------------------------------------------------------

func expandPath(p string) string {
	if p == "" {
		return p
	}
	if p == "~" {
		home, err := os.UserHomeDir()
		if err != nil {
			return p
		}
		return home
	}
	if strings.HasPrefix(p, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return p
		}
		return filepath.Join(home, p[2:])
	}
	return p
}

func socketPath() string {
	if p := os.Getenv("HERDR_SOCKET_PATH"); p != "" {
		return expandPath(p)
	}
	dir := "~/.config/herdr"
	if cfg := os.Getenv("HERDR_CONFIG_PATH"); cfg != "" {
		dir = filepath.Dir(expandPath(cfg))
	}
	return filepath.Join(expandPath(dir), "herdr.sock")
}

func shq(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}

func die(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "herdr-toggle: "+format+"\n", args...)
	os.Exit(1)
}

// daemon read helpers ----------------------------------------------------------------

func tabList(cl *Client, wsID string) []tabInfo {
	var res tabListResult
	if err := cl.call("tab.list", map[string]any{"workspace_id": wsID}, &res); err != nil {
		die("tab.list: %v", err)
	}
	return res.Tabs
}

func panes(cl *Client, wsID string) []paneInfo {
	var res paneListResult
	if err := cl.call("pane.list", map[string]any{"workspace_id": wsID}, &res); err != nil {
		die("pane.list: %v", err)
	}
	return res.Panes
}

func paneOfTab(cl *Client, wsID, tabID string) string {
	for _, p := range panes(cl, wsID) {
		if p.TabID == tabID {
			return p.PaneID
		}
	}
	return ""
}

func paneInTab(cl *Client, wsID, tabID, paneID string) bool {
	for _, p := range panes(cl, wsID) {
		if p.PaneID == paneID && p.TabID == tabID {
			return true
		}
	}
	return false
}

func currentPane(cl *Client) string {
	var res paneCurrentResult
	if err := cl.call("pane.current", map[string]any{}, &res); err != nil {
		return ""
	}
	return res.Pane.PaneID
}

func foregroundName(cl *Client, paneID string) string {
	var res procInfoResult
	if err := cl.call("pane.process_info", map[string]any{"pane_id": paneID}, &res); err != nil {
		return ""
	}
	if len(res.ProcessInfo.ForegroundProcesses) == 0 {
		return ""
	}
	return res.ProcessInfo.ForegroundProcesses[0].Name
}

func createToolTab(cl *Client, wsID, name, cwd string) (tabInfo, paneInfo) {
	params := map[string]any{
		"workspace_id": wsID,
		"label":        name,
		"cwd":          cwd,
		"focus":        false,
	}
	var res tabCreatedResult
	if err := cl.call("tab.create", params, &res); err != nil {
		die("tab.create: %v", err)
	}
	return res.Tab, res.RootPane
}

// main --------------------------------------------------------------------------------

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: herdr-toggle <name> '<shell command>'")
		os.Exit(2)
	}
	name := os.Args[1]
	cmd := ""
	if len(os.Args) > 2 {
		cmd = os.Args[2]
	}

	cwd := os.Getenv("HERDR_ACTIVE_PANE_CWD")
	if cwd == "" {
		cwd, _ = os.UserHomeDir()
	}

	cl := &Client{sock: socketPath()}

	// live workspace ids + focused-workspace fallback (one fast socket call)
	var wss workspaceListResult
	if err := cl.call("workspace.list", map[string]any{}, &wss); err != nil {
		die("cannot reach herdr daemon (%s): %v", cl.sock, err)
	}
	live := make(map[string]bool)
	focused := ""
	for _, w := range wss.Workspaces {
		live[w.WorkspaceID] = true
		if w.Focused {
			focused = w.WorkspaceID
		}
	}

	origin := os.Getenv("HERDR_ACTIVE_WORKSPACE_ID")
	if origin == "" {
		origin = focused
	}
	if origin == "" || !live[origin] {
		die("no origin workspace (set HERDR_ACTIVE_WORKSPACE_ID)")
	}

	state := loadState(name)
	tabs := tabList(cl, origin)
	focusedTab := ""
	var toolTab *tabInfo
	for i := range tabs {
		if tabs[i].Focused {
			focusedTab = tabs[i].TabID
		}
		if tabs[i].Label == name {
			t := tabs[i]
			toolTab = &t
		}
	}

	if toolTab != nil && focusedTab == toolTab.TabID {
		// --- toggle off: back to the tab we toggled from (fallback: first
		// other tab), restoring the exact pane if it is still alive.
		entry, hasEntry := state[origin]
		target := ""
		if hasEntry && entry.LastTab != "" {
			for _, t := range tabs {
				if t.TabID == entry.LastTab {
					target = t.TabID
					break
				}
			}
		}
		if target == "" {
			for _, t := range tabs {
				if t.TabID != toolTab.TabID {
					target = t.TabID
					break
				}
			}
		}
		if target != "" {
			_ = cl.call("tab.focus", map[string]any{"tab_id": target}, nil)
			if hasEntry && entry.OriginPane != "" &&
				paneInTab(cl, origin, target, entry.OriginPane) {
				_ = cl.call("pane.focus", map[string]any{"pane_id": entry.OriginPane}, nil)
			}
		}
		delete(state, origin)
		saveState(name, state, live)
		return
	}

	// --- toggle on: ensure the tool tab exists, (re)start the tool, focus it.
	originPane := currentPane(cl)

	fresh := false
	var toolTabID string
	var toolPane string
	if toolTab == nil {
		t, root := createToolTab(cl, origin, name, cwd)
		toolTab = &t
		toolTabID = t.TabID
		toolPane = root.PaneID
		fresh = true
	} else {
		toolTabID = toolTab.TabID
		toolPane = paneOfTab(cl, origin, toolTabID)
	}

	if toolTabID == "" {
		die("failed to create tab %q", name)
	}
	if toolPane == "" {
		// tab exists but has no pane: stale, recreate it
		_ = cl.call("tab.close", map[string]any{"tab_id": toolTabID}, nil)
		t, root := createToolTab(cl, origin, name, cwd)
		toolTabID, toolPane = t.TabID, root.PaneID
		fresh = true
	}

	if cmd != "" && toolPane != "" {
		if fresh {
			// fresh tab already starts its shell in cwd
			_ = cl.call("pane.send_text", map[string]any{"pane_id": toolPane, "text": cmd + "\n"}, nil)
		} else if shells[foregroundName(cl, toolPane)] {
			// tool was quit inside its tab: restart it in the current directory
			text := fmt.Sprintf("cd %s && %s\n", shq(cwd), cmd)
			_ = cl.call("pane.send_text", map[string]any{"pane_id": toolPane, "text": text}, nil)
		}
	}

	state[origin] = stateEntry{LastTab: focusedTab, OriginPane: originPane}
	saveState(name, state, live)
	_ = cl.call("tab.focus", map[string]any{"tab_id": toolTabID}, nil)
}
