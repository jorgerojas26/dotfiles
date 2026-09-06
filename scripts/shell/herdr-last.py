#!/usr/bin/env python3
"""herdr-last.py — tmux-style "last workspace" for herdr.

The recency tracking lives in the jorgerojas.last-workspace plugin
(~/.dotfiles/.config/herdr/plugins-local/last-workspace/): a manifest hook on
`workspace.focused` keeps prev-workspace/current-workspace state files under
~/.herdr. This script is just the keybinding client: it reads prev-workspace
and focuses it over herdr's socket API (one request per connection).

Wire it up as a herdr custom command (type = "shell"), e.g.:
    [[keys.command]]
    key = "prefix+space"
    type = "shell"
    command = "~/.dotfiles/scripts/shell/herdr-last.py workspace"
    description = "last workspace"
"""

import json
import os
import pathlib
import socket
import sys
import time

STATE_DIR = pathlib.Path(
    os.environ.get(
        "HERDR_LAST_STATE_DIR",
        "~/.local/state/herdr/plugins/jorgerojas.last-workspace",
    )
).expanduser()
PREV_FILE = STATE_DIR / "prev-workspace"

_config_path = os.environ.get("HERDR_CONFIG_PATH", "")
_config_dir = (
    str(pathlib.Path(_config_path).expanduser().parent) if _config_path else "~/.config/herdr"
)
_socket_env = os.environ.get("HERDR_SOCKET_PATH", "")
HERDR_SOCKET = (
    pathlib.Path(_socket_env).expanduser()
    if _socket_env
    else pathlib.Path(_config_dir).expanduser() / "herdr.sock"
)

FOCUS_TIMEOUT = 2.0


def focus_workspace(ws_id, timeout=FOCUS_TIMEOUT):
    """One-shot focus request (herdr serves one request per connection)."""
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(timeout)
        s.connect(str(HERDR_SOCKET))
        s.sendall(
            (
                json.dumps(
                    {"id": "hlw", "method": "workspace.focus", "params": {"workspace_id": ws_id}}
                )
                + "\n"
            ).encode()
        )
        buf = b""
        while b"\n" not in buf:
            chunk = s.recv(65536)
            if not chunk:
                break
            buf += chunk
        s.close()
        obj = json.loads(buf.split(b"\n", 1)[0].decode("utf-8", "replace"))
        return bool(obj.get("result"))
    except (OSError, EOFError, json.JSONDecodeError):
        return False


def main():
    try:
        ws = PREV_FILE.read_text().strip()
    except OSError:
        print("herdr-last: no prev-workspace state yet (plugin hook not fired?)", file=sys.stderr)
        return 1
    if not ws:
        return 1

    deadline = time.time() + 2.0
    while time.time() < deadline:
        if focus_workspace(ws):
            return 0
        time.sleep(0.1)  # server briefly busy; retry with the same target
    return 1


if __name__ == "__main__":
    sys.exit(main())
