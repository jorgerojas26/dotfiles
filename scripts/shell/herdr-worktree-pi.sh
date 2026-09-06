#!/usr/bin/env bash
# herdr-worktree-pi.sh — one keypress: create a git worktree exactly the way
# herdr does it natively, then open pi in it. No prompts, no confirmations.
#
# Bound in ~/.config/herdr/config.toml as a detached shell custom command
# (config sets new_worktree = "" and takes over prefix+shift+g):
#
#   [[keys.command]]
#   key = "prefix+shift+g"
#   type = "shell"
#   command = "~/.dotfiles/scripts/shell/herdr-worktree-pi.sh"
#   description = "auto worktree + pi"
#
# Flow:
#   1. herdr worktree create (the same engine as the built-in "new worktree"
#      flow): checkout under <worktrees.directory>/<repo>/<branch-slug>,
#      opened as a new workspace grouped under the current one.
#   2. Branch name is auto-generated: <rama-actual>-wt-<YYYYMMDD>, with a
#      -2/-3… suffix when the name is already taken (no interaction).
#   3. Starts the pi agent in the new workspace's root pane via herdr's
#      integration, then focuses the workspace.
#
# Override the name prefix/base with HERDR_WT_PREFIX (default: current branch).
set -u

HERDR_BIN="${HERDR_BIN_PATH:-herdr}"
NOTIFY_TITLE="worktree + pi"

notify() { "$HERDR_BIN" notification show "$NOTIFY_TITLE" --body "$1" >/dev/null 2>&1 || true; }
err() { printf '✗ %s\n' "$*" >&2; notify "$*"; exit 1; }

# --- context (pane where the key was pressed) ---------------------------------
WS_ID="${HERDR_ACTIVE_WORKSPACE_ID:-}"
CWD="${HERDR_ACTIVE_PANE_CWD:-$PWD}"
if [ -z "$WS_ID" ]; then
    WS_ID="$("$HERDR_BIN" workspace list 2>/dev/null | python3 -c 'import sys,json
try:
    d = json.load(sys.stdin); ws = d.get("result", d).get("workspaces", [])
    print(next((w.get("workspace_id", "") for w in ws if w.get("focused")), ""))
except Exception:
    print("")')"
fi
[ -n "$WS_ID" ] || err "no active herdr workspace"
[ -n "$CWD" ] || CWD="$HOME"

# --- repo + auto branch name ---------------------------------------------------
ROOT="$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)" || err "not inside a git repo: $CWD"
CUR="$(git -C "$CWD" branch --show-current 2>/dev/null)"
DATE="$(date +%Y%m%d)"

PREFIX="${HERDR_WT_PREFIX:-}"
[ -z "$PREFIX" ] && PREFIX="${CUR:-wt}"
BRANCH="${PREFIX}-wt-${DATE}"
N=1
while git -C "$ROOT" rev-parse --verify --quiet "refs/heads/$BRANCH" >/dev/null 2>&1; do
    N=$((N + 1))
    BRANCH="${PREFIX}-wt-${DATE}-${N}"
done

# --- herdr worktree create (native) ---------------------------------------------
OUT="$("$HERDR_BIN" worktree create --workspace "$WS_ID" --branch "$BRANCH" --focus 2>&1)" \
    || err "worktree create failed: $(printf '%s' "$OUT" | tail -n 1)"

# Parse workspace / tab / root pane ids from the JSON response (tolerant of the
# exact record layout: prefer result.workspace / result.root_pane, else scan).
read -r WS_NEW TAB_NEW PANE_NEW <<< "$(printf '%s' "$OUT" | python3 -c 'import sys,json
def first(d, key):
    if isinstance(d, dict):
        if isinstance(d.get(key), str):
            return d[key]
        for v in d.values():
            r = first(v, key)
            if r:
                return r
    elif isinstance(d, list):
        for v in d:
            r = first(v, key)
            if r:
                return r
    return ""
try:
    d = json.load(sys.stdin); r = d.get("result", d)
    ws = (r.get("workspace") or {}).get("workspace_id") or first(r, "workspace_id")
    tab = (r.get("tab") or {}).get("tab_id") or first(r, "tab_id")
    pane = (r.get("root_pane") or {}).get("pane_id") or first(r, "pane_id")
    print(ws, tab, pane)
except Exception:
    print("")')"
[ -n "$PANE_NEW" ] || err "worktree created but no root pane returned: $(printf '%s' "$OUT" | tail -n 1)"

# --- wait for the pane shell to reach its prompt --------------------------------
for _ in $(seq 1 20); do
    FG="$("$HERDR_BIN" pane process-info --pane "$PANE_NEW" 2>/dev/null | python3 -c 'import sys,json
try:
    d = json.load(sys.stdin); r = d.get("result", d); pi = r.get("process_info", r)
    fg = pi.get("foreground_processes") or [{}]
    print(fg[0].get("name", "") if fg else "")
except Exception:
    print("")')"
    case " zsh bash fish sh dash ksh tcsh " in
        *" $FG "*) break ;;
    esac
    sleep 0.3
done

# --- start pi through herdr's integration ----------------------------------------
SLUG="$(printf '%s' "$BRANCH" | tr '/' '-' | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_-' '-')"
AGENT_NAME="pi-${SLUG}"
[ "${#AGENT_NAME}" -gt 31 ] && AGENT_NAME="$(printf '%s' "$AGENT_NAME" | cut -c1-31)"

if "$HERDR_BIN" agent start "$AGENT_NAME" --kind pi --pane "$PANE_NEW" --timeout 60000 >/dev/null 2>&1; then
    notify "✓ ${BRANCH} — pi abierto"
else
    FG="$("$HERDR_BIN" pane process-info --pane "$PANE_NEW" 2>/dev/null | python3 -c 'import sys,json
try:
    d = json.load(sys.stdin); r = d.get("result", d); pi = r.get("process_info", r)
    fg = pi.get("foreground_processes") or [{}]
    print(fg[0].get("name", "") if fg else "")
except Exception:
    print("")')"
    case " zsh bash fish sh dash ksh tcsh " in
        *" $FG "*) "$HERDR_BIN" pane run "$PANE_NEW" "pi" >/dev/null 2>&1 && notify "✓ ${BRANCH} — pi lanzado manualmente" ;;
        *) notify "⚠ ${BRANCH}: agent start falló; revisa el tab (pi quizá esté arrancando)" ;;
    esac
fi

if [ -n "$TAB_NEW" ]; then
    "$HERDR_BIN" tab focus "$TAB_NEW" >/dev/null 2>&1
elif [ -n "$WS_NEW" ]; then
    "$HERDR_BIN" workspace focus "$WS_NEW" >/dev/null 2>&1
fi
