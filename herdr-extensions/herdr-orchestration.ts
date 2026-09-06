// herdr-orchestration: replace native pi subagent delegation with herdr-spawned workers.
//
// MANAGED COPY: ~/.dotfiles/herdr-extensions/herdr-orchestration.ts (versioned in the
// dotfiles repo). Pi loads it via settings.json "extensions". Keep edits HERE; the
// auto-discovered ~/.pi/agent/extensions must NOT contain this file (double load).
//
// This extension sits beside the herdr-managed files (herdr-agent-state.ts, the
// *_bridge.ts hooks) as the documented customization point. It registers tools
// that drive the herdr CLI from inside a herdr pane:
//
//   herdr_delegate        spawn one isolated pi worker, run, return its handoff
//   herdr_fleet           spawn N isolated pi workers in a dedicated tab, parallel
//   herdr_worker_status   inspect spawned/visible workers (list/get/read)
//   herdr_worker_steer    inject a prompt or keys into a running worker
//   /herdr-workers        TUI widget: live sidebar state of agents in this session
//
// Design contract (mirrors gentle-pi subagent discipline, herdr execution layer):
//   - Worktrees are OPT-IN (worktree: true): isolated branches for real
//     parallel work on the same repo. Sequential/directed work (gentle-ai)
//     writes in-tree by default, like native subagents did.
//   - Results return via a file handoff INSIDE the worker's cwd
//     (<cwd>/.herdr-handoff/<name>.md), so the worker's own cwd-guard never
//     blocks on writes outside its tree, and the parent's tree stays clean.
//   - Workers never commit; the parent reviews the worktree diff and merges.
//   - Fail fast when NOT inside herdr (HERDR_ENV != 1): no silent fallback.
//   - gentle-ai artifacts (sdd-*, jd-*, review-*) are untouched; this is a
//     routing-layer swap, so gentle-pi updates keep working.
//
// Environment:
//   HERDR_ORCH_BIN                 herdr binary (default: "herdr" from PATH)
//   HERDR_ORCH_BLOCK_NATIVE=1      hard-block native subagent tools (agent,
//                                  subagent_run, subagent_*) with a reason.
//   HERDR_ORCH_KEEP_HANDOFF=1      default keepHandoff=true for all calls.
//   HERDR_ORCH_STATE_EXT           path to herdr's agent-state extension that
//                                  yolo workers re-attach via -e (default:
//                                  ~/.pi/agent/extensions/herdr-agent-state.ts)
// @ts-nocheck

import { execFile, execFileSync } from "node:child_process";
import net from "node:net";
import { promisify } from "node:util";
import { existsSync } from "node:fs";
import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { Type } from "typebox";

const execFileAsync = promisify(execFile);

const NATIVE_DELEGATION_TOOLS = new Set([
  "agent",
  "subagent_run",
  "subagent_list_agents",
  "subagent_status",
  "subagent_result",
  "subagent_list_tasks",
  "subagent_cancel",
  "subagent_send_message",
]);

const NAME_PATTERN = "^[a-z][a-z0-9_-]{0,31}$";
const HANDOFF_DIR_NAME = ".herdr-handoff";
const MAX_RESULT_BYTES = 48_000;

function enabled() {
  return process.env.HERDR_ENV === "1" && !!process.env.HERDR_PANE_ID && !!process.env.HERDR_SOCKET_PATH;
}

// ---------------------------------------------------------------------------
// herdr CLI
// ---------------------------------------------------------------------------

function herdrBin() {
  return process.env.HERDR_ORCH_BIN || "herdr";
}

function parseBody(raw, args) {
  let body;
  try {
    body = JSON.parse(raw);
  } catch {
    throw new Error(`herdr ${args.join(" ")} returned non-JSON output: ${raw.slice(0, 300)}`);
  }
  if (body?.error) {
    const e = body.error;
    throw new Error(`herdr ${args[0] ?? ""} ${args[1] ?? ""}: ${e.code ?? "error"} — ${e.message ?? JSON.stringify(e)}`);
  }
  return body?.result ?? body ?? {};
}

async function run(cmdArgs, opts = {}) {
  const { cwd, timeout, signal } = opts;
  try {
    const { stdout } = await execFileAsync(herdrBin(), cmdArgs, {
      cwd,
      timeout,
      signal,
      maxBuffer: 16 * 1024 * 1024,
      env: process.env,
    });
    return parseBody(stdout, cmdArgs);
  } catch (err) {
    const stderr = err?.stderr ? String(err.stderr) : "";
    if (err?.signal === "SIGTERM" || err?.killed) {
      throw new Error(`herdr ${cmdArgs.join(" ")} timed out or was aborted`);
    }
    if (stderr.trim()) {
      let parsed;
      try {
        parsed = JSON.parse(stderr);
      } catch {
        /* plain text stderr below */
      }
      const msg = parsed?.error?.message ?? stderr.trim().split("\n").slice(0, 5).join(" ");
      throw new Error(`herdr ${cmdArgs[0] ?? ""} ${cmdArgs[1] ?? ""}: ${msg}`);
    }
    throw err;
  }
}

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

function pick(obj, keys) {
  for (const k of keys) {
    const v = obj?.[k];
    if (v !== undefined && v !== null) return v;
  }
  return undefined;
}

function agentOf(result) {
  if (!result) return {};
  if (result.pane_id || result.agent_status || result.name) return result;
  return result.agent ?? result.info ?? {};
}

function settle(result) {
  return pick(agentOf(result), ["agent_status", "status"]) ?? "unknown";
}

function defaultName(tag = "hw") {
  return `${tag}${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`.slice(0, 32);
}

function tabLabelFor(task, opts = {}) {
  const { name, fallback = "worker" } = opts;
  let base;
  if (name) {
    base = String(name).toLowerCase().replace(/[^\p{L}\p{N}-]/gu, "-").replace(/-+/g, "-").replace(/^-|-$/g, "").slice(0, 28);
  }
  base = base || slugLabelTokens(task) || fallback;
  let label = base;
  let n = 2;
  while (USED_TAB_LABELS.has(label)) {
    label = `${base.slice(0, Math.max(1, 28 - String(n).length - 1))}-${n}`;
    n += 1;
  }
  USED_TAB_LABELS.add(label);
  return label;
}

const TAB_STOP_WORDS = new Set([
  "you", "are", "the", "a", "an", "of", "for", "to", "as", "your", "please",
  "this", "that", "with", "from", "be", "is", "it", "on", "in", "at", "and",
  "or", "by", "about", "into", "per", "its", "our", "we", "will", "can",
  "should", "must", "has", "have", "had", "not", "no", "then", "than", "so",
  "but", "do", "does", "did", "my", "me", "i", "also", "only", "just",
  "all", "each", "every",
]);
const USED_TAB_LABELS = new Set();

function slugLabelTokens(task) {
  const cleaned = String(task ?? "").toLowerCase().replace(/[^\p{L}\p{N}\s-]/gu, " ");
  const picked = [];
  for (const raw of cleaned.split(/\s+/)) {
    const tok = raw.replace(/-+/g, "-").replace(/^-|-$/g, "");
    if (!tok) continue;
    if (TAB_STOP_WORDS.has(tok)) continue;
    picked.push(tok);
    if (picked.length >= 4) break;
  }
  if (!picked.length) {
    for (const raw of cleaned.split(/\s+/)) {
      const tok = raw.replace(/-+/g, "-").replace(/^-|-$/g, "");
      if (!tok) continue;
      picked.push(tok);
      if (picked.length >= 3) break;
    }
  }
  return picked.join("-").replace(/-+/g, "-").replace(/^-|-$/g, "").slice(0, 28);
}

function truncate(text, max = MAX_RESULT_BYTES) {
  if (typeof text !== "string") return String(text ?? "");
  return text.length > max ? `${text.slice(0, max)}\n…[truncated ${text.length - max} chars]` : text;
}

function isGitRepo(dir) {
  try {
    execFileSync("git", ["-C", dir, "rev-parse", "--show-toplevel"], { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

function sessionId(ctx) {
  try {
    const id = ctx?.sessionManager?.getSessionId?.();
    if (typeof id === "string" && id.length > 0) return id.replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, 48);
  } catch {
    /* ignore */
  }
  return "default";
}

async function mkdirHandoff(workerCwd) {
  const dir = path.join(workerCwd, HANDOFF_DIR_NAME);
  await fs.mkdir(dir, { recursive: true });
  return dir;
}

function buildWorkerPrompt(task, context, surfaces, meta) {
  const surfaceLines = Array.isArray(surfaces) && surfaces.length
    ? surfaces.map((s) => `- ${s}`)
    : ["- (none specified — work under the working directory; if the task requires touching paths outside it, stop and say so in the result instead of editing silently)"];
  return [
    "You are a herdr-orchestrated worker spawned by the parent pi session of this machine.",
    "",
    "## Task",
    task,
    "",
    "## Context",
    typeof context === "string" && context.length > 0 ? context : "(none provided by parent)",
    "",
    "## Working directory",
    meta.workerCwd,
    "",
    "## Allowed edit surfaces",
    ...surfaceLines,
    "",
    "## Constraints",
    "- Do NOT commit, push, tag, publish, install, or otherwise mutate anything outside the work.",
    "- Do NOT run herdr control commands (herdr agent / pane / workspace / worktree / session). Control belongs to the parent session.",
    "- Stay inside the allowed edit surfaces. If the task requires leaving them, record `interaction_required` in the result instead of editing silently.",
    "- Do not touch the parent's working tree; you are in an isolated checkout.",
    "",
    "## Handoff",
    "When finished, write your complete result as Markdown to EXACTLY this path:",
    meta.handoffPath,
    "The file MUST contain these sections:",
    "## Summary",
    "## Files changed",
    "## Evidence  (commands run, test output, diffs)",
    "## Status  (one of: done | blocked | interaction_required)",
    "Then reply with ONLY the handoff file path.",
    "Do NOT attempt to exit or close this session — the parent closes it deterministically when it has read the handoff. Spend zero effort on exit logistics.",
    "If you cannot proceed, still write the file with Status: interaction_required (or blocked if you are waiting on an approvable action) and stop there.",
  ].join("\n");
}

// ---------------------------------------------------------------------------
// background focus guard: workers must never steal the user's pane focus.
// herdr honors --no-focus, but this guard makes "completely in background" a
// guarantee: if a worker pane ever ends up focused, restore the focus that
// existed before the spawn. It never overrides USER navigation to other panes.
// ---------------------------------------------------------------------------

function deepFind(obj, key) {
  if (!obj || typeof obj !== "object") return undefined;
  if (Array.isArray(obj)) {
    for (const v of obj) {
      const r = deepFind(v, key);
      if (r !== undefined) return r;
    }
    return undefined;
  }
  if (key in obj) return obj[key];
  for (const v of Object.values(obj)) {
    const r = deepFind(v, key);
    if (r !== undefined) return r;
  }
  return undefined;
}

async function snapshotFocus() {
  try {
    const res = await run(["api", "snapshot"], { timeout: 15_000 });
    const fp = deepFind(res, "focused_pane_id");
    return typeof fp === "string" && fp.length > 0 ? fp : undefined;
  } catch {
    return undefined;
  }
}

function socketSendRequest(method, params, timeoutMs = 3000) {
  const socketPath = process.env.HERDR_SOCKET_PATH;
  if (!socketPath) return Promise.resolve(false);
  const endpoint = process.platform === "win32" ? `\\\\.\\pipe\\${socketPath}` : socketPath;
  return new Promise((resolve) => {
    let done = false;
    let timer;
    const finish = (ok) => {
      if (done) return;
      done = true;
      if (timer) clearTimeout(timer);
      socket.destroy();
      resolve(ok);
    };
    const socket = net.createConnection(endpoint);
    socket.on("error", () => finish(false));
    socket.on("connect", () => socket.write(`${JSON.stringify({ id: `herdr-orch:${Date.now()}:${Math.random().toString(36).slice(2)}`, method, params })}\n`));
    socket.on("data", () => finish(true));
    socket.on("end", () => finish(false));
    timer = setTimeout(() => finish(false), timeoutMs);
    timer.unref?.();
  });
}

async function restoreFocus(beforeFocus, ourPanes) {
  if (!beforeFocus || !ourPanes || ourPanes.size === 0) return;
  try {
    const now = await snapshotFocus();
    if (now && now !== beforeFocus && ourPanes.has(now)) {
      await socketSendRequest("pane.focus", { pane_id: beforeFocus });
    }
  } catch {
    /* best effort */
  }
}

// Yolo worker profile: lean pi, structurally unable to prompt.
//   -ne  no extensions (cwd-guard / pix gates / ask bridges / gentle-pi are gone)
//   -a   per-run trust override (no "Trust project folder?" in untrusted dirs)
//   -xt  physically remove the asking tools
//   -e   re-attach ONLY herdr's state reporter (never prompts), so herdr keeps
//        accurate agent states and session paths despite -ne.
function resolveWorkerArgs(params) {
  const extra = Array.isArray(params.piArgs) ? params.piArgs : [];
  if (params.yolo === false) return extra;
  const stateExt = process.env.HERDR_ORCH_STATE_EXT
    ?? path.join(os.homedir(), ".pi", "agent", "extensions", "herdr-agent-state.ts");
  const args = ["-ne", "-a", "-xt", "ask_user,ask_user_choice,ask_user_question"];
  if (existsSync(stateExt)) args.push("-e", stateExt);
  return args.concat(extra);
}

// Create an isolated git worktree for the worker. Returns { cwd, workspaceId, created }.
async function prepareWorktree(name, params, baseCwd, onUpdate) {
  const repo = params.worktree === true ? baseCwd : undefined;
  let root = repo;
  if (repo !== undefined) {
    try {
      root = execFileSync("git", ["-C", repo, "rev-parse", "--show-toplevel"], {
        encoding: "utf8",
        stdio: ["ignore", "pipe", "ignore"],
      }).trim();
    } catch {
      root = undefined;
    }
  }
  if (!root) {
    onUpdate?.({ content: [{ type: "text", text: "→ not a git repo; worker will run in the given cwd without worktree isolation" }] });
    return { cwd: baseCwd, workspaceId: undefined, created: false, repo: undefined };
  }
  const branch = params.worktreeBranch || `herdr/${name}`;
  const base = params.worktreeBase || "HEAD";
  const fallbackPath = path.join(path.dirname(root), `${path.basename(root)}-herdr-${name}`);
  const wtPath = params.worktreePath || fallbackPath;
  onUpdate?.({ content: [{ type: "text", text: `→ worktree ${branch} @ ${wtPath}` }] });
  const res = await run(["worktree", "create", "--cwd", root, "--branch", branch, "--base", base, "--path", wtPath, "--no-focus"], { timeout: 120_000 });
  const wtObj = typeof res?.worktree === "object" ? res.worktree : undefined;
  const resolvedPath = pick(wtObj, ["path", "cwd", "checkout_path", "dir"])
    ?? pick(res, ["path", "cwd", "checkout_path", "worktree_path"])
    ?? wtPath;
  const ws = typeof res?.workspace === "object"
    ? pick(res.workspace, ["workspace_id", "id"]) ?? res.workspace
    : (res?.workspace ?? res?.workspace_id);
  return { cwd: resolvedPath, workspaceId: ws, created: true, repo: root, branch };
}

function worktreeHasChanges(cwd) {
  try {
    const status = execFileSync("git", ["-C", cwd, "status", "--porcelain", "--", ".", ":(exclude).herdr-handoff"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    });
    return status.trim().length > 0;
  } catch {
    return true; // conservative: if we cannot tell, keep the lane
  }
}

// Reclaim the worktree when the worker is done and there is NOTHING left to
// review (no edits; only the handoff, which is removed on read). Dirty lanes
// are always kept — the parent lands them through herdr_finalize.
async function cleanupWorktree(meta, params) {
  if (!meta.worktree?.created) return { cleanup: "skipped", reason: "no worktree" };
  if (!meta.worktree.workspaceId) {
    return { cleanup: "skipped", reason: "worktree workspace id unknown — remove manually" };
  }
  if (worktreeHasChanges(meta.worktree.cwd)) {
    return { cleanup: "kept", reason: "worktree has uncommitted changes — keep for review/finalize" };
  }
  try {
    await run(["worktree", "remove", "--workspace", meta.worktree.workspaceId], { timeout: 60_000 });
    return { cleanup: "removed", reason: undefined };
  } catch (err) {
    return { cleanup: "skipped", reason: err.message };
  }
}

async function readHandoff(meta, onUpdate, deadlineMs = 60_000) {
  const deadline = Date.now() + deadlineMs;
  while (Date.now() < deadline) {
    try {
      const text = await fs.readFile(meta.handoffPath, "utf8");
      return text;
    } catch {
      await new Promise((r) => setTimeout(r, 750));
    }
  }
  onUpdate?.({ content: [{ type: "text", text: "→ settled but handoff file not found; reading pane scrollback" }] });
  return undefined;
}

    // The FILE is the completion signal. `agent prompt --wait` can return early on a
    // transient idle while the worker is still going; poll the handoff for a grace
    // window, and if the worker is still active without a handoff, nudge it once to
    // finish before declaring no_handoff.
    async function waitForHandoff(meta, name, onUpdate, signal) {
      const found = await readHandoff(meta, onUpdate);
      if (found !== undefined) return found;
      let state = "unknown";
      try {
        const info = await run(["agent", "get", name], { timeout: 20_000, signal });
        state = settle(info);
      } catch { /* agent may have ended */ }
      if (state === "working" || state === "idle") {
        onUpdate?.({ content: [{ type: "text", text: `→ ${name} still active without a handoff; nudging it to finish` }] });
        await run(["agent", "prompt", name,
          `Finish now: write your handoff file to ${meta.handoffPath} (Status: interaction_required if blocked). The parent will close this session; do not exit yourself.`,
        ], { timeout: 20_000, signal }).catch(() => {});
        return readHandoff(meta, onUpdate);
      }
      return found;
    }

    // --- pane/tab reclaim -----------------------------------------------------
    // A done worker's session is closed with ctrl+d; without explicit cleanup the
    // tab lingers as an idle shell tab forever (observed: ~20 orphaned worker tabs
    // in one workspace). Wait for the agent record to disappear, then close the
    // tab we created. Tabs the user is actively looking at are never closed.

    async function waitAgentGone(name, timeoutMs = 20_000) {
      const deadline = Date.now() + timeoutMs;
      while (Date.now() < deadline) {
        try {
          const list = await run(["agent", "list"], { timeout: 10_000 }).catch(() => null);
          const agents = list?.agents ?? [];
          if (!agents.some((a) => a.agent === name || a.name === name)) return true;
        } catch { /* keep polling */ }
        await new Promise((r) => setTimeout(r, 700));
      }
      return false;
    }

    async function closeTab(tabId) {
      if (!tabId) return false;
      try {
        await run(["tab", "close", tabId], { timeout: 30_000 });
        return true;
      } catch {
        return false;
      }
    }

    async function tabFocused(tabId) {
      if (!tabId) return false;
      try {
        const res = await run(["tab", "list"], { timeout: 15_000 });
        const tabs = res?.tabs ?? [];
        const t = tabs.find((x) => x.tab_id === tabId || x.id === tabId);
        return !!t?.focused;
      } catch {
        return false;
      }
    }

    async function createWorkerTab(meta, signal) {
      const ws = process.env.HERDR_WORKSPACE_ID;
      if (!ws) throw new Error("delegation needs HERDR_WORKSPACE_ID to create a tab");
      const tabRes = await run(["tab", "create", "--workspace", ws, "--label", meta.tabLabel, "--cwd", meta.workerCwd, "--no-focus"], { timeout: 60_000, signal });
      const tabId = pick(tabRes?.tab, ["tab_id", "id"]) ?? tabRes?.tab_id;
      const paneId = pick(tabRes?.root_pane, ["pane_id", "id"]) ?? tabRes?.root_pane ?? pick(tabRes?.pane, ["pane_id"]);
      if (!paneId) throw new Error("herdr tab create returned no root pane id");
      return { tabId, paneId };
    }

    const PANE_RETRYABLE = /not an available shell|pane not found|no longer available/i;

    // Start the pi agent, retrying ONCE on a transient pane-allocation failure
    // ("pane W:pN is not an available shell"). The bad tab is closed first — that
    // reclaims its pane slot — then a fresh tab is used. Same worker name stays
    // valid because the failed start never registered the agent.
    async function startAgentInPane(name, meta, onUpdate, signal) {
      const buildArgs = () => {
        const args = ["agent", "start", name, "--kind", "pi", "--pane", meta.paneId, "--timeout", String(meta.startupTimeoutMs)];
        if (meta.workerArgs.length) args.push("--", ...meta.workerArgs);
        return args;
      };
      try {
        return { started: await run(buildArgs(), { timeout: meta.startupTimeoutMs + 30_000, signal }), retried: false };
      } catch (err) {
        const msg = String(err?.message ?? "");
        if (!PANE_RETRYABLE.test(msg)) throw err;
        onUpdate?.({ content: [{ type: "text", text: `→ pane allocation failed (${msg.slice(0, 140)}); retrying ${name} on a fresh tab` }] });
        if (meta.tabId) await closeTab(meta.tabId).catch(() => {});
        const fresh = await createWorkerTab(meta, signal);
        meta.tabId = fresh.tabId;
        meta.paneId = fresh.paneId;
        const started = await run(buildArgs(), { timeout: meta.startupTimeoutMs + 30_000, signal });
        return { started, retried: true };
      }
    }

// Spawn + run one worker end to end. Returns a per-worker record.
async function delegateOne(name, params, meta, onUpdate, signal) {
  const focusBefore = await snapshotFocus();
  const ourPanes = new Set();
  const record = {
    worker: name,
    status: "pending",
    paneId: undefined,
    tabId: undefined,
    worktreeCwd: meta.workerCwd,
    worktreeBranch: meta.worktree?.branch,
    worktreeCreated: !!meta.worktree?.created,
    error: undefined,
    result: undefined,
  };

  try {
    // 1. create a named tab for the worker (background; the focus guard keeps
    //    the user's pane focused under --no-focus)
    onUpdate?.({ content: [{ type: "text", text: `→ spawning ${name} in tab "${meta.tabLabel}"` }] });
    if (meta.existingPaneId) {
      meta.paneId = meta.existingPaneId;
    } else {
      const created = await createWorkerTab(meta, signal);
      meta.tabId = created.tabId;
      meta.paneId = created.paneId;
    }
    record.tabId = meta.tabId;
    record.paneId = meta.paneId;
    ourPanes.add(meta.paneId);

    // 2. start the pi agent in that pane (auto-retries once on a dead pane)
    onUpdate?.({ content: [{ type: "text", text: `→ starting pi agent ${name}` }] });
    const { started, retried } = await startAgentInPane(name, meta, onUpdate, signal);
    record.tabId = meta.tabId;
    record.paneId = meta.paneId;
    if (retried) record.startRetried = true;
    ourPanes.add(meta.paneId);
    await restoreFocus(focusBefore, ourPanes);
    onUpdate?.({ content: [{ type: "text", text: `→ ${name} ready (${settle(started)}) in ${meta.paneId}` }] });


    // 3. send the delegation contract
    const prompt = buildWorkerPrompt(params.task, params.context, params.allowedEditSurfaces, meta);
    onUpdate?.({ content: [{ type: "text", text: `→ prompted ${name}; waiting up to ${Math.round(meta.waitTimeoutMs / 1000)}s` }] });
    await run(["agent", "prompt", name, prompt, "--wait", "--timeout", String(meta.waitTimeoutMs)], { timeout: meta.waitTimeoutMs + 30_000, signal });

    // 4. settle → handoff. A transient guard/approval "blocked" can still deliver
    //    the handoff a few seconds later, so grace-poll before declaring
    //    interaction_required.
    const info = await run(["agent", "get", name], { timeout: 30_000, signal }).catch(() => ({}));
    const status = settle(info) || "done";
    // The handoff FILE is the completion signal; keep polling the whole window.
    // --wait can return early on a transient idle, so a short window would
    // false-negative slow workers.
    const text = await waitForHandoff(meta, name, onUpdate, signal);
    if (text !== undefined) {
      record.status = "done";
      record.result = { summary: text.split("\n").slice(0, 8).join("\n"), body: truncate(text) };
      // Free the pane: the worker replied with the path and is idle at its prompt.
      await run(["agent", "send-keys", name, "ctrl+d"], { timeout: 15_000 }).catch(() => {});
      // Reclaim the tab once pi has fully exited, unless the parent asked to
      // keep it or the user is looking at that tab right now.
      if (!params.keepTab && meta.tabId) {
        let focused = false;
        try { focused = await tabFocused(meta.tabId); } catch { /* assume not focused */ }
        if (!focused) {
          await waitAgentGone(name).catch(() => {});
          record.tabClosed = await closeTab(meta.tabId).catch(() => false);
          if (!record.tabClosed) record.tabCleanupNote = `tab left open (close manually: herdr tab close ${meta.tabId})`;
        } else {
          record.tabCleanupNote = "tab is focused — kept for you";
        }
      } else if (meta.tabId) {
        record.tabCleanupNote = params.keepTab ? "kept per keepTab" : undefined;
      }
      return record;
    }
    if (status === "blocked") {
      record.status = "interaction_required";
      record.result = {
        summary: "Worker is blocked waiting for an approvable action and has not delivered a handoff file.",
        tail: truncate(await agentTail(name), MAX_RESULT_BYTES),
      };
      if (meta.tabId) record.tabCleanupNote = `tab kept (close manually: herdr tab close ${meta.tabId})`;
      return record;
    }
    record.status = "no_handoff";
    record.result = { summary: "Worker settled without writing the handoff file.", tail: truncate(await agentTail(name), MAX_RESULT_BYTES) };
    if (meta.tabId) record.tabCleanupNote = `tab kept (close manually: herdr tab close ${meta.tabId})`;
    return record;

  } catch (err) {
    record.status = "error";
    record.error = err?.message ?? String(err);
    record.result = { summary: record.error, tail: truncate(await agentTail(name).catch(() => ""), 6_000) };
    if (meta.tabId) record.tabCleanupNote = `tab kept (close manually: herdr tab close ${meta.tabId})`;
    return record;

  } finally {
    await restoreFocus(focusBefore, ourPanes);
    if (record.status === "done" && !meta.keepHandoff) {
      await fs.rm(meta.handoffPath, { force: true }).catch(() => {});
      await fs.rmdir(meta.handoffDir, { recursive: false }).catch(() => {});
    }
    if (record.status !== "done" || meta.worktree?.created) {
      const cleanup = await cleanupWorktree(meta, params).catch((e) => ({ cleanup: "skipped", reason: e.message }));
      if (cleanup?.cleanup === "removed") record.worktreeRemoved = true;
      else if (cleanup?.cleanup === "skipped") record.cleanupNote = cleanup.reason;
    }
  }
}

// Validate runtime preconditions exactly once per call.
function guard() {
  if (!enabled()) {
    return "pi is not running inside a herdr pane (HERDR_ENV, HERDR_PANE_ID, HERDR_SOCKET_PATH). Launch pi inside a herdr pane to delegate; outside herdr, delegation tools fail fast by design (no native subagent fallback).";
  }
  return undefined;
}

function makeResult(record, singleMeta) {
  const parts = [`[worker: ${record.worker}]`, `status: ${record.status}`];
  if (record.tabId) parts.push(`tab: ${record.tabId}`);
  if (record.paneId) parts.push(`pane: ${record.paneId}`);
  if (record.worktreeCreated && record.worktreeCwd) parts.push(`worktree: ${record.worktreeCwd} (branch ${record.worktreeBranch ?? "?"})`);
  if (record.cleanupNote) parts.push(`cleanup: ${record.cleanupNote}`);
  if (record.tabClosed) parts.push(`tab closed: ${record.tabId}`);
  if (record.tabCleanupNote) parts.push(`tab: ${record.tabCleanupNote}`);
  if (record.startRetried) parts.push("note: agent start retried on a fresh tab (pane allocation)");
  if (record.error) parts.push(`error: ${record.error}`);
  if (record.result?.tail) parts.push("--- agent tail ---\n" + record.result.tail);
  if (record.result?.summary) parts.push("--- result summary ---\n" + record.result.summary);
  if (record.result?.body) parts.push("--- handoff body ---\n" + record.result.body);
  const text = parts.join("\n\n");
  return {
    content: [{ type: "text", text }],
    details: {
      worker: record.worker,
      status: record.status,
      tabId: record.tabId,
      paneId: record.paneId,
      worktreeCwd: record.worktreeCwd,
      worktreeCreated: record.worktreeCreated,
      worktreeRemoved: record.worktreeRemoved ?? false,
      tabClosed: record.tabClosed ?? false,
      tabCleanupNote: record.tabCleanupNote,
      startRetried: record.startRetried ?? false,
      error: record.error,
      handoff: singleMeta?.handoffPath,
      handoffBody: record.result?.body,
    },
  };
}

// ---------------------------------------------------------------------------
// tools
// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------
// finalize: close worktree lanes (commit parent-side, merge, cleanup)
// ---------------------------------------------------------------------------

async function ensureInfoExclude(gitCommonDir, pattern) {
  try {
    const infoPath = path.join(gitCommonDir, "info", "exclude");
    let cur = "";
    try { cur = await fs.readFile(infoPath, "utf8"); } catch { /* missing file */ }
    if (!cur.split("\n").includes(pattern)) {
      await fs.appendFile(infoPath, `${cur.endsWith("\n") || !cur ? "" : "\n"}${pattern}\n`);
    }
    return true;
  } catch {
    return false;
  }
}

function gitOut(cwd, args) {
  return execFileSync("git", ["-C", cwd, ...args], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).trim();
}

function gitTry(cwd, args) {
  try {
    return { ok: true, out: gitOut(cwd, args), err: "" };
  } catch (e) {
    return { ok: false, out: "", err: String(e?.stderr ?? e?.message ?? e).trim() };
  }
}

function findWorktreePath(repo, branch) {
  const r = gitTry(repo, ["worktree", "list", "--porcelain"]);
  if (!r.ok) return undefined;
  let cur;
  for (const line of r.out.split("\n")) {
    if (line.startsWith("worktree ")) cur = line.slice("worktree ".length).trim();
    else if (line.startsWith("branch refs/heads/") && line.endsWith(branch)) return cur;
  }
  return undefined;
}

function defaultWtPath(repo, branch) {
  const name = branch.replace(/^herdr\//, "");
  return path.join(path.dirname(repo), `${path.basename(repo)}-herdr-${name}`);
}

function branchOfWorktree(wtPath) {
  const r = gitTry(wtPath, ["branch", "--show-current"]);
  return r.ok ? r.out : "";
}

function resolveLanes(params, repo) {
  const lanes = [];
  if (Array.isArray(params.worktreePaths)) {
    for (const wt of params.worktreePaths) lanes.push({ branch: undefined, wtPath: wt });
  }
  if (Array.isArray(params.names)) {
    for (const n of params.names) lanes.push({ branch: `herdr/${n}`, wtPath: undefined });
  }
  if (params.all) {
    const r = gitTry(repo, ["worktree", "list", "--porcelain"]);
    if (r.ok) {
      let cur;
      for (const line of r.out.split("\n")) {
        if (line.startsWith("worktree ")) cur = line.slice("worktree ".length).trim();
        else if (line.startsWith("branch refs/heads/herdr/")) {
          lanes.push({ branch: line.slice("branch refs/heads/".length).trim(), wtPath: cur });
        }
      }
    }
  }
  return lanes;
}

async function removeWorktreeViaHerdr(repo, lane) {
  try {
    const list = await run(["worktree", "list", "--cwd", repo], { timeout: 30_000 });
    const entries = Array.isArray(list?.worktrees) ? list.worktrees : [];
    const hit = entries.find((e) =>
      (lane.branch && e?.branch === lane.branch)
      || (lane.wtPath && (e?.path === lane.wtPath || path.basename(e?.path ?? "") === path.basename(lane.wtPath)))
    );
    const wsId = hit?.open_workspace_id ?? hit?.workspace_id;
    if (!wsId) return false;
    await run(["worktree", "remove", "--workspace", wsId], { timeout: 60_000 });
    return true;
  } catch {
    return false;
  }
}

async function finalizeLane(repo, target, lane, params) {
  const out = { lane: lane.branch ?? lane.wtPath, branch: lane.branch, wtPath: lane.wtPath, status: "pending" };
  if (!lane.wtPath) {
    lane.wtPath = findWorktreePath(repo, lane.branch)
      ?? (existsSync(defaultWtPath(repo, lane.branch)) ? defaultWtPath(repo, lane.branch) : undefined);
  }
  if (!lane.wtPath || !existsSync(lane.wtPath)) { out.status = "missing"; return out; }
  if (!lane.branch) lane.branch = branchOfWorktree(lane.wtPath);
  out.branch = lane.branch;
  out.wtPath = lane.wtPath;
  if (!lane.branch) { out.status = "error"; out.error = "cannot resolve branch for worktree"; return out; }
  if (lane.branch === target) { out.status = "skipped"; out.detail = "lane branch equals target"; return out; }

  // .herdr-handoff must never land in a commit. Plain `git add -A` skips it when
  // the repo gitignores it; for repos that don't, add a repo-local ignore first.
  // (Reproduced: a `:(exclude)` pathspec on `git add` makes git treat the pathspec
  // list as explicit and it hard-errors on the ignored directory.)
  const commonDir = gitTry(lane.wtPath, ["rev-parse", "--git-common-dir"]);
  if (commonDir.ok && commonDir.out) {
    await ensureInfoExclude(path.resolve(lane.wtPath, commonDir.out), ".herdr-handoff/");
  }
  const porcelain = gitTry(lane.wtPath, ["status", "--porcelain", "--", "."]).out ?? "";
  const ahead = gitTry(repo, ["rev-list", "--count", `${target}..${lane.branch}`]);
  const hasLocal = porcelain.trim().length > 0;
  const hasCommits = ahead.ok && Number(ahead.out) > 0;
  if (!hasLocal && !hasCommits) { out.status = "nothing_to_finalize"; return out; }

  const laneName = lane.branch.replace(/^herdr\//, "") || lane.wtPath;
  const msg = params.message ? `${params.message} (${lane.branch})` : `herdr/${laneName}`;
  const untracked = porcelain.split("\n").filter((l) => l.startsWith("?? ")).map((l) => l.slice(3));
  const stat = gitTry(lane.wtPath, ["diff", "--stat"]).out || "(no tracked diff)";
  out.plan = { hasLocalChanges: hasLocal, commitsAhead: hasCommits, target, diffStat: stat.slice(0, 3000), untracked };
  if (params.dryRun !== false) { out.status = "planned"; return out; }

  if (hasLocal) {
    const add = gitTry(lane.wtPath, ["add", "-A"]);
    if (!add.ok) { out.status = "error"; out.error = add.err.slice(0, 1500); return out; }
    const cm = gitTry(lane.wtPath, ["commit", "-m", msg]);
    if (!cm.ok) { out.status = "error"; out.error = cm.err.slice(0, 1500); return out; }
  }
  const mg = gitTry(repo, ["merge", "--no-ff", lane.branch, "-m", msg]);
  if (!mg.ok) {
    gitTry(repo, ["merge", "--abort"]);
    out.status = "conflict";
    out.error = mg.err.slice(0, 2000);
    return out;
  }
  let removed = await removeWorktreeViaHerdr(repo, lane);
  let cleanupNote;
  if (!removed) {
    const gm = gitTry(repo, ["worktree", "remove", lane.wtPath]);
    removed = gm.ok;
    if (!gm.ok) cleanupNote = gm.err.slice(0, 500);
  }
  const del = gitTry(repo, ["branch", "-D", lane.branch]);
  out.status = "merged";
  out.merged = { worktreeRemoved: removed, cleanupNote, branchDeleted: del.ok };
  return out;
}


export default function (pi) {
  const running = enabled();

  if (process.env.HERDR_ORCH_BLOCK_NATIVE === "1") {
    pi.on("tool_call", async (event) => {
      if (NATIVE_DELEGATION_TOOLS.has(event?.toolName)) {
        return {
          block: true,
          reason: "Native subagent tools are disabled by herdr-orchestration (HERDR_ORCH_BLOCK_NATIVE=1). Delegate through herdr_delegate / herdr_fleet; see the herdr-orchestration skill.",
        };
      }
    });
  }

  pi.registerTool({
    name: "herdr_delegate",
    label: "Herdr Delegate",
    description:
      "Spawn ONE pi worker through herdr in its own NAMED TAB (label auto-derived from the task; isolated worktree opt-in; prompt, wait, file handoff) and return its result inline. Workers run in yolo mode by default: a lean pi process (-ne: no extensions, -a: per-run trust override, -xt ask_user,ask_user_choice,ask_user_question) that cannot prompt for permission. This is the herdr-backed replacement for native pi subagents.",
    promptGuidelines: [
      "Use herdr_delegate for substantial implementation, exploration, or review work that would previously go to a pi subagent.",
      "Prefer herdr_fleet when several independent workers should run in parallel (e.g., judgment-day dual review).",
    ],
    parameters: Type.Object({
      task: Type.String({ description: "Self-contained instruction for the worker: what to do and the acceptance criteria. The worker starts cold; include everything it needs." }),
      context: Type.Optional(Type.String({ description: "Relevant background the parent already knows (prior decisions, constraints, references)." })),
      allowedEditSurfaces: Type.Optional(Type.Array(Type.String({ description: "Repository-relative paths/globs the worker may edit; everything else is off-limits unless the task demands it (then it must report instead)." }))),
      cwd: Type.Optional(Type.String({ description: "Base directory for the work. Defaults to the parent's cwd." })),
      worktree: Type.Optional(Type.Boolean({ default: false, description: "Run the worker in an isolated git worktree (branch herdr/<name>) of the repo containing cwd — opt-in. Use true ONLY for real parallel work on the same repo; sequential/directed work should write in-tree (default). Falls back to same-dir when cwd is not in a git repo." })),
      worktreeBranch: Type.Optional(Type.String({ description: "Branch for the isolated worktree (default herdr/<name>)." })),
      worktreeBase: Type.Optional(Type.String({ description: "Ref the worktree is created from (default HEAD)." })),
      worktreePath: Type.Optional(Type.String({ description: "Explicit checkout path for the worktree (default: sibling of the repo named <repo>-herdr-<name>)." })),
      name: Type.Optional(Type.String({ pattern: NAME_PATTERN, description: "Unique worker name (default auto). Must match [a-z][a-z0-9_-]{0,31}." })),
      label: Type.Optional(Type.String({ description: "Descriptive label for the worker's TAB; default: derived from the task (first words, slugified)." })),
      direction: Type.Optional(Type.Union([Type.Literal("right"), Type.Literal("down")], { default: "right", description: "Deprecated — single workers now run in their own named tab; kept for schema compatibility." })),
      startupTimeoutMs: Type.Optional(Type.Integer({ default: 120000, minimum: 5000, maximum: 300000, description: "Max ms to wait for the pi agent to become ready after spawn." })),
      yolo: Type.Optional(Type.Boolean({ default: true, description: "Lean worker: pi -ne (no extensions) + -a (per-run trust override) + -xt ask_user,ask_user_choice,ask_user_question (asking tools physically removed). Re-attaches herdr's state reporter via -e so the sidebar stays accurate. Set false for the full extension-loaded worker." })),
      piArgs: Type.Optional(Type.Array(Type.String(), { description: "Extra CLI args appended to the spawn command after the yolo profile (or used alone when yolo: false)." })),
      timeoutMs: Type.Optional(Type.Integer({ default: 600000, minimum: 5000, description: "Max ms to wait for the worker to settle after the prompt." })),
      cleanup: Type.Optional(Type.Union([Type.Literal("keep"), Type.Literal("remove")], { default: "keep", description: "Worktrees with uncommitted changes are always kept for herdr_finalize; clean ones are reclaimed automatically once the worker is done." })),
      keepTab: Type.Optional(Type.Boolean({ default: false, description: "Keep the worker's tab open after a 'done' result (debugging/inspection) instead of closing it once the session fully exits." })),
      keepHandoff: Type.Optional(Type.Boolean({ default: false, description: "Keep the .herdr-handoff file instead of deleting it after reading (debugging)." })),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const err = guard();
      if (err) return { content: [{ type: "text", text: err }], details: { status: "not_in_herdr" } };

      const name = params.name || defaultName();
      const baseCwd = params.cwd || ctx.cwd || process.cwd();
      const worktree = await prepareWorktree(name, params, baseCwd, onUpdate);
      const handoffDir = await mkdirHandoff(worktree.cwd);
      const handoffPath = path.join(handoffDir, `${name}.md`);
      const meta = {
        workerCwd: worktree.cwd,
        worktree,
        workerArgs: resolveWorkerArgs(params),
        tabLabel: params.label || tabLabelFor(params.task, { name: params.name, fallback: "worker" }),
        startupTimeoutMs: params.startupTimeoutMs ?? 120000,
        waitTimeoutMs: params.timeoutMs ?? 600000,
        handoffPath,
        handoffDir,
        keepHandoff: params.keepHandoff || process.env.HERDR_ORCH_KEEP_HANDOFF === "1",
      };
      const record = await delegateOne(name, params, meta, onUpdate, signal);
      return makeResult(record, meta);
    },
  });

  pi.registerTool({
    name: "herdr_fleet",
    label: "Herdr Fleet",
    description:
      "Spawn N isolated pi workers in a dedicated tab (one worktree + pane each), prompt all of them, wait in parallel, and return every handoff. Workers run yolo (lean pi, no prompts) by default. Use for parallel exploration or independent review lanes (e.g., judgment-day dual review: two workers, same evidence, isolated branches).",
    parameters: Type.Object({
      workers: Type.Array(Type.Object({
        name: Type.Optional(Type.String({ pattern: NAME_PATTERN })),
        task: Type.String({ description: "Self-contained task + acceptance criteria for THIS worker." }),
        context: Type.Optional(Type.String()),
        allowedEditSurfaces: Type.Optional(Type.Array(Type.String())),
      }), { description: "One spec per worker (1-6 recommended; each adds a pane + pi process)." }),
      cwd: Type.Optional(Type.String({ description: "Base directory for all workers (default parent cwd)." })),
      worktree: Type.Optional(Type.Boolean({ default: false, description: "Isolated worktrees per worker (branch herdr/<name>). Recommend true when multiple workers touch the SAME repo — in-tree parallel writes would collide. Leave false for non-git cwd or repos worked by a single worker." })),
      worktreeBase: Type.Optional(Type.String({ description: "Ref all worktrees are created from (default HEAD)." })),
      startupTimeoutMs: Type.Optional(Type.Integer({ default: 120000, minimum: 5000, maximum: 300000 })),
      timeoutMs: Type.Optional(Type.Integer({ default: 900000, minimum: 5000 })),
      cleanup: Type.Optional(Type.Union([Type.Literal("keep"), Type.Literal("remove")], { default: "keep", description: "Worktrees with uncommitted changes are always kept for herdr_finalize; clean ones are reclaimed automatically once workers are done." })),
      keepTab: Type.Optional(Type.Boolean({ default: false, description: "Keep the fleet tab open after all workers finish (debugging) instead of closing it once the sessions fully exit." })),
      keepHandoff: Type.Optional(Type.Boolean({ default: false })),
      tabLabel: Type.Optional(Type.String({ description: "Label for the fleet tab; default: derived from the first worker task." })),
      yolo: Type.Optional(Type.Boolean({ default: true, description: "Lean workers (pi -ne -a -xt ask_*); see herdr_delegate for details." })),
      piArgs: Type.Optional(Type.Array(Type.String(), { description: "Extra CLI args appended to every worker spawn (or used alone when yolo: false)." })),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const err = guard();
      if (err) return { content: [{ type: "text", text: err }], details: { status: "not_in_herdr" } };

      const workers = Array.isArray(params.workers) && params.workers.length ? params.workers : [{ task: "(no workers provided)" }];
      const baseCwd = params.cwd || ctx.cwd || process.cwd();
      const ws = process.env.HERDR_WORKSPACE_ID;
      if (!ws) return { content: [{ type: "text", text: "fleet needs HERDR_WORKSPACE_ID; cannot determine the tab workspace" }], details: { status: "not_in_herdr" } };
      const fleetNames = workers.map((w) => w.name).filter(Boolean);
      const tabLabel = params.tabLabel || (fleetNames.length === workers.length && fleetNames.length > 0
        ? tabLabelFor(workers[0].task ?? "", { name: `${fleetNames[0]}-x${workers.length}`, fallback: "fleet" })
        : tabLabelFor(workers.map((w) => w.task ?? "").join(" "), "fleet"));
      const keepHandoff = params.keepHandoff || process.env.HERDR_ORCH_KEEP_HANDOFF === "1";
      const keepTab = params.keepTab === true;
      const focusBefore = await snapshotFocus();
      const ourPanes = new Set();

      onUpdate?.({ content: [{ type: "text", text: `→ fleet: creating tab "${tabLabel}" with ${workers.length} workers` }] });
      const tab = await run(["tab", "create", "--workspace", ws, "--label", tabLabel, "--cwd", baseCwd, "--no-focus"], { timeout: 60_000, signal });
      const rootPane = pick(tab, ["root_pane_id", "root_pane"]) ?? pick(tab?.pane, ["pane_id"]);
      if (rootPane) ourPanes.add(rootPane);

      // prepare worktrees + panes for every worker (a failing pane split must not
      // orphan its freshly created worktree — clean it up and keep the fleet going)
      const metas = [];
      const prepErrors = [];
      let prevPane = rootPane;
      for (let i = 0; i < workers.length; i += 1) {
        const spec = workers[i];
        const name = spec.name || defaultName(`hw${i}`);
        const wtParams = { ...params, task: spec.task, context: spec.context, allowedEditSurfaces: spec.allowedEditSurfaces };
        let wt;
        try {
          wt = await prepareWorktree(name, wtParams, baseCwd, onUpdate);
          const handoffDir = await mkdirHandoff(wt.cwd);
          const handoffPath = path.join(handoffDir, `${name}.md`);
          let paneId = prevPane;
          if (i > 0) {
            const direction = i % 2 === 1 ? "down" : "right";
            let split;
            try {
              split = await run(["pane", "split", "--pane", prevPane, "--direction", direction, "--cwd", wt.cwd, "--no-focus"], { timeout: 60_000, signal });
            } catch (err) {
              const alt = direction === "down" ? "right" : "down";
              onUpdate?.({ content: [{ type: "text", text: `→ pane split failed; retrying ${alt} (${String(err?.message ?? err).slice(0, 100)})` }] });
              split = await run(["pane", "split", "--pane", prevPane, "--direction", alt, "--cwd", wt.cwd, "--no-focus"], { timeout: 60_000, signal });
            }
            paneId = pick(split?.pane, ["pane_id", "id"]) ?? split?.pane_id;
          }
          if (paneId) ourPanes.add(paneId);
          prevPane = paneId;
          metas.push({
            name,
            paneId,
            workerArgs: resolveWorkerArgs(params),
            workerCwd: wt.cwd,
            worktree: wt,
            startupTimeoutMs: params.startupTimeoutMs ?? 120000,
            waitTimeoutMs: params.timeoutMs ?? 900000,
            handoffPath,
            handoffDir,
            keepHandoff,
          });
        } catch (err) {
          const msg = String(err?.message ?? err);
          onUpdate?.({ content: [{ type: "text", text: `→ worker ${name} prep failed: ${msg.slice(0, 140)}` }] });
          if (wt?.created) {
            await cleanupWorktree({ worktree: wt }, params).catch(() => {});
          }
          prepErrors.push({ worker: name, error: msg });
        }
      }

      // start all agents, then prompt all (no wait), then wait in parallel
      await restoreFocus(focusBefore, ourPanes);
      for (const m of metas) {
        onUpdate?.({ content: [{ type: "text", text: `→ starting pi agent ${m.name} in ${m.paneId}` }] });
        const startArgs = ["agent", "start", m.name, "--kind", "pi", "--pane", m.paneId, "--timeout", String(m.startupTimeoutMs)];
        if (m.workerArgs.length) startArgs.push("--", ...m.workerArgs);
        await run(startArgs, { timeout: m.startupTimeoutMs + 30_000, signal });
      }
      for (let i = 0; i < workers.length; i += 1) {
        const m = metas[i];
        const spec = workers[i];
        const prompt = buildWorkerPrompt(spec.task, spec.context, spec.allowedEditSurfaces, m);
        onUpdate?.({ content: [{ type: "text", text: `→ prompted ${m.name}` }] });
        await run(["agent", "prompt", m.name, prompt], { timeout: 30_000, signal });
      }

      const settled = await Promise.all(
        metas.map(async (m) => {
          try {
            await run(["agent", "wait", m.name, "--timeout", String(m.waitTimeoutMs)], { timeout: m.waitTimeoutMs + 30_000, signal });
          } catch {
            /* wait failure handled below via state read */
          }
          return m;
        })
      );

      const records = [];
      for (const m of settled) {
        const recordPending = {
          worker: m.name,
          status: "pending",
          paneId: m.paneId,
          worktreeCwd: m.workerCwd,
          worktreeBranch: m.worktree?.branch,
          worktreeCreated: !!m.worktree?.created,
        };
        let info = {};
        try {
          info = await run(["agent", "get", m.name], { timeout: 30_000, signal });
        } catch {
          /* agent may have exited after writing handoff */
        }
        const status = settle(info) || "done";
        const text = await readHandoff(m, onUpdate);
        if (text === undefined) {
          recordPending.status = status === "blocked" ? "interaction_required" : "no_handoff";
          recordPending.result = { summary: `Worker ${status} without a handoff file.`, tail: truncate(await agentTail(m.name), 6000) };
        } else {
          recordPending.status = "done";
          recordPending.result = { summary: text.split("\n").slice(0, 8).join("\n"), body: truncate(text) };
          if (!keepHandoff) await fs.rm(m.handoffPath, { force: true }).catch(() => {});
          await run(["agent", "send-keys", m.name, "ctrl+d"], { timeout: 15_000, signal }).catch(() => {});
        }
        records.push(recordPending);
      }

      await restoreFocus(focusBefore, ourPanes);

      // Reclaim the fleet tab when every lane was collected and the user is not
      // looking at that tab right now.
      const tabId = pick(tab, ["tab_id", "id"]) ?? pick(tab?.tab, ["tab_id", "id"]);
      let tabClosed = false;
      let tabCleanupNote;
      const allDone = records.length > 0 && records.every((r) => r.status === "done");
      if (allDone && !keepTab && tabId) {
        let focused = false;
        try { focused = await tabFocused(tabId); } catch { /* assume not focused */ }
        if (!focused) {
          try { for (const r of records) await waitAgentGone(r.worker); } catch { /* best effort */ }
          tabClosed = await closeTab(tabId).catch(() => false);
          if (!tabClosed) tabCleanupNote = `tab close failed — close manually: herdr tab close ${tabId}`;
        } else {
          tabCleanupNote = "tab is focused — kept for you";
        }
      } else if (tabId) {
        tabCleanupNote = keepTab ? "kept per keepTab" : allDone ? "reclaim skipped" : "some workers not done — tab kept for inspection";
      }
      const tabLine = tabId
        ? `\n[fleet tab ${tabId}] ${tabClosed ? "closed" : `kept${tabCleanupNote ? ` (${tabCleanupNote})` : ""}`}`
        : "";

      const text = records.map((r) => {
        const head = `[${r.worker}] status: ${r.status} | pane: ${r.paneId} | worktree: ${r.worktreeCwd} (branch ${r.worktreeBranch ?? "?"})`;
        const body = r.result?.body ? `\n--- handoff body ---\n${r.result.body}` : r.result?.tail ? `\n--- tail ---\n${r.result.tail}` : "";
        return head + body;
      }).join("\n\n");
      const prepNotes = prepErrors.map((e) => `\n[prep failed: ${e.worker}] ${e.error}`).join("");
      return {
        content: [{ type: "text", text: (text || "(no workers collected)") + prepNotes + tabLine }],
        details: { workers: records, prepErrors, tab: tabLabel, tabId, tabClosed, tabCleanupNote },
      };
    },
  });

  pi.registerTool({
    name: "herdr_worker_status",
    label: "Herdr Worker Status",
    description: "Inspect herdr agents in the current session. With a name, shows one worker (state, pane, cwd, recent output). Without a name, lists everyone the session sees. Use after a timeout or before steering.",
    parameters: Type.Object({
      name: Type.Optional(Type.String({ description: "Worker name (or agent name) to inspect in detail." })),
      lines: Type.Optional(Type.Integer({ default: 80, description: "Recent-output lines when a name is given." })),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const err = guard();
      if (err) return { content: [{ type: "text", text: err }], details: { status: "not_in_herdr" } };
      if (params.name) {
        const info = await run(["agent", "get", params.name], { timeout: 30_000, signal }).catch((e) => ({ error: e.message }));
        const tail = await agentTail(params.name, params.lines ?? 80);
        return {
          content: [{ type: "text", text: JSON.stringify(info, null, 2) + (tail ? "\n--- recent output ---\n" + truncate(tail) : "") }],
          details: { info, tail: truncate(tail, 10000) },
        };
      }
      const list = await run(["agent", "list"], { timeout: 30_000, signal });
      const agents = list?.agents ?? [];
      const lines = agents.map((a) => `- ${a.agent.padEnd(10)} ${(a.agent_status ?? "?").padEnd(9)} pane=${a.pane_id}${a.name ? ` name=${a.name}` : ""} cwd=${a.cwd ?? ""}`);
      return {
        content: [{ type: "text", text: lines.length ? lines.join("\n") : "(no agents visible)" }],
        details: { agents },
      };
    },
  });

  pi.registerTool({
    name: "herdr_worker_steer",
    label: "Herdr Worker Steer",
    description: "Interrupt or redirect a running herdr worker: inject a follow-up prompt (action=prompt) or send logical keys like esc / ctrl+c (action=keys). Use when a worker is stuck, blocked, or needs a correction.",
    parameters: Type.Object({
      name: Type.String({ description: "Worker name to steer." }),
      action: Type.Optional(Type.Union([Type.Literal("prompt"), Type.Literal("keys")], { default: "prompt" })),
      text: Type.Optional(Type.String({ description: "Follow-up instruction (action=prompt)." })),
      keys: Type.Optional(Type.String({ description: "Logical key sequence, e.g. 'esc' or 'ctrl+c' (action=keys)." })),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const err = guard();
      if (err) return { content: [{ type: "text", text: err }], details: { status: "not_in_herdr" } };
      if (params.action === "keys") {
        const keys = params.keys || "esc";
        await run(["agent", "send-keys", params.name, keys], { timeout: 30_000, signal });
        return { content: [{ type: "text", text: `sent keys '${keys}' to ${params.name}` }], details: { steered: params.name, keys } };
      }
      const text = params.text || "Please finish up now: write your handoff file (status: interaction_required if blocked). The parent will close this session; do not exit yourself.";
      await run(["agent", "prompt", params.name, text], { timeout: 30_000, signal });
      return { content: [{ type: "text", text: `follow-up prompt sent to ${params.name}` }], details: { steered: params.name } };
    },
  });


  pi.registerTool({
    name: "herdr_finalize",
    label: "Herdr Finalize",
    description:
      "Close worktree lanes (worktree: true) from herdr_delegate/herdr_fleet: commit the lane's changes parent-side, merge its branch into the repo's target branch (default: current), remove the worktree, delete the branch. dryRun default shows the plan per lane (status, diff stat, target) without mutating; set dryRun: false to execute. Merge conflicts abort and keep the lane intact.",
    promptGuidelines: [
      "Use herdr_finalize after collecting worktree lanes (worktree: true) once the parent and user agree to land them.",
      "Run it dry first (default), then execute after the user approves.",
    ],
    parameters: Type.Object({
      names: Type.Optional(Type.Array(Type.String({ description: "Worker names to finalize; each maps to its herdr/<name> branch and matching worktree." }))),
      worktreePaths: Type.Optional(Type.Array(Type.String({ description: "Explicit worktree checkout paths instead of names (any branch)." }))),
      all: Type.Optional(Type.Boolean({ default: false, description: "Finalize every herdr/* worktree lane in the repo containing cwd." })),
      cwd: Type.Optional(Type.String({ description: "Repo directory (default: parent cwd). Lanes are resolved and merged here." })),
      targetBranch: Type.Optional(Type.String({ description: "Branch to merge lanes into (default: current branch of the repo)." })),
      message: Type.Optional(Type.String({ description: "Commit/merge message prefix (default: 'herdr/<lane>')." })),
      dryRun: Type.Optional(Type.Boolean({ default: true, description: "Plan only (status, diff stat, target). No commits, merges, or removals." })),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const repo = gitTry(params.cwd || ctx.cwd || process.cwd(), ["rev-parse", "--show-toplevel"]);
      if (!repo.ok) {
        return { content: [{ type: "text", text: `herdr_finalize needs a git repo: ${repo.err}` }], details: { status: "not_a_repo" } };
      }
      const root = repo.out;
      const target = params.targetBranch || gitTry(root, ["branch", "--show-current"]).out;
      if (!target) {
        return { content: [{ type: "text", text: "herdr_finalize needs a target branch (repo is on detached HEAD); pass targetBranch." }], details: { status: "no_target" } };
      }
      const lanes = resolveLanes(params, root);
      if (!lanes.length) {
        return { content: [{ type: "text", text: "No lanes selected: pass names, worktreePaths, or all: true." }], details: { status: "no_lanes" } };
      }
      const executing = params.dryRun === false;
      onUpdate?.({ content: [{ type: "text", text: `→ finalizing ${lanes.length} lane(s) into ${target} (${executing ? "EXECUTE" : "dry-run"})` }] });
      const results = [];
      for (const lane of lanes) {
        const r = await finalizeLane(root, target, lane, params);
        results.push(r);
        onUpdate?.({ content: [{ type: "text", text: `→ ${r.lane}: ${r.status}${r.error ? " — " + r.error.slice(0, 180) : ""}` }] });
      }
      const lines = results.map((r) => {
        const head = `[${r.lane}] ${r.status}`;
        if (r.error) return `${head}\n  error: ${r.error}`;
        if (r.plan) {
          return `${head} (dry-run)\n  changes: ${r.plan.hasLocalChanges ? "uncommitted" : "none"}${r.plan.untracked?.length ? ` (${r.plan.untracked.length} untracked)` : ""} | commits ahead: ${r.plan.commitsAhead} | target: ${r.plan.target}\n  diff stat:\n${r.plan.diffStat}`;
        }
        if (r.merged) {
          return `${head}\n  merged into ${target}; worktree removed: ${r.merged.worktreeRemoved}; branch deleted: ${r.merged.branchDeleted}${r.merged.cleanupNote ? `\n  cleanup note: ${r.merged.cleanupNote}` : ""}`;
        }
        if (r.detail) return `${head}\n  ${r.detail}`;
        return head;
      });
      return {
        content: [{ type: "text", text: lines.join("\n\n") }],
        details: { dryRun: !executing, target, results },
      };
    },
  });


  pi.registerCommand("herdr-workers", {
    description: "Show live herdr agent states for this session as a TUI widget (sidebar-style snapshot).",
    hidden: false,
    handler: async (_args, ctx) => {
      if (!running) {
        ctx.ui?.notify?.("not inside herdr", "info");
        return;
      }
      try {
        const list = await run(["agent", "list"], { timeout: 30_000 });
        const agents = list?.agents ?? [];
        const lines = agents.length ? agents.map((a) => `${(a.agent_status ?? "?").padEnd(9)} ${String(a.agent ?? "").padEnd(12)} pane=${a.pane_id} ${a.cwd ?? ""}${a.name ? ` (${a.name})` : ""}`) : ["(no agents)"];
        ctx.ui?.setWidget?.("herdr-workers", lines);
        ctx.ui?.setStatus?.("herdr-workers", `${agents.length} agents`);
      } catch (e) {
        ctx.ui?.notify?.(`herdr agent list failed: ${e?.message ?? e}`, "error");
      }
    },
  });
}