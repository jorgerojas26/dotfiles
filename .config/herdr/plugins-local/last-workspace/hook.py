#!/usr/bin/env python3
"""herdr last-workspace event hook.

Runs on every `workspace.focused` event (payload arrives via the
HERDR_PLUGIN_EVENT_JSON env var) and maintains two one-line state files:

    current-workspace   id of the focused workspace
    prev-workspace      id of the workspace focused before the current one

The keybinding client (~/.dotfiles/scripts/shell/herdr-last.py) reads
prev-workspace and focuses it. Rapid A->B->A switching naturally leaves
prev = B, so toggling behaves like tmux last-session.
"""

import json
import os
import pathlib
import sys
import tempfile

STATE_DIR = pathlib.Path(
    os.environ.get("HERDR_PLUGIN_STATE_DIR") or os.path.expanduser("~/.herdr")
)


def read(path):
    try:
        return path.read_text().strip()
    except OSError:
        return ""


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=str(path.parent))
    try:
        with os.fdopen(fd, "w") as f:
            f.write(value + "\n")
        os.replace(tmp, path)
    except OSError:
        try:
            os.unlink(tmp)
        except OSError:
            pass


def main():
    try:
        payload = json.loads(os.environ.get("HERDR_PLUGIN_EVENT_JSON", "{}"))
    except json.JSONDecodeError:
        return 1

    data = payload.get("data") or {}
    ws = data.get("workspace_id") or data.get("id")
    if not ws:
        return 1

    cur_file = STATE_DIR / "current-workspace"
    prev_file = STATE_DIR / "prev-workspace"

    prev_ws = read(cur_file)
    if prev_ws and prev_ws != ws:
        write(prev_file, prev_ws)
    write(cur_file, str(ws))
    return 0


if __name__ == "__main__":
    sys.exit(main())
