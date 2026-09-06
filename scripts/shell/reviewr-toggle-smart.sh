#!/usr/bin/env bash
# reviewr-toggle-smart.sh — a stateless reviewr toggle that is robust to the
# "reviewr stays alive in the background after sending comments" lifecycle.
#
# Why: herdr-reviewr's built-in `toggle` probes live panes by foreground process
# (no state file). After a successful Send, reviewr focuses the agent pane but
# does NOT quit or close its own pane, so the next toggle SEES a "still open"
# reviewr pane and CLOSES it instead of opening a fresh one — the user has to
# press twice. This wrapper tells "open AND focused" (real toggle-off) apart from
# "open but backgrounded / stale after send" (close + reopen fresh).
#
# Bind as a herdr custom command: type = "shell"
#   key = "ctrl+r"   ->   ~/.dotfiles/scripts/shell/reviewr-toggle-smart.sh
#
# Delegates the actual pane open/close to the plugin's own herdr/pane.sh, so
# placement (split/tab/overlay) and normal routing stay identical to the plugin.
# Env: REVR_DRY_RUN=1 prints the decision without touching any pane.

set -u

H="${HERDR_BIN_PATH:-herdr}"
ws="${HERDR_ACTIVE_WORKSPACE_ID:-${HERDR_WORKSPACE_ID:-}}"
STATE_DIR="${HERDR_TOGGLE_STATE_DIR:-$HOME/.herdr/toggles}"
DRY_RUN="${REVR_DRY_RUN:-0}"

# Locate the reviewr plugin root (herdr installs under github/ or the dotfiles copy).
PLUGIN_ROOT="${HERDR_PLUGIN_ROOT:-}"
if [[ -z "$PLUGIN_ROOT" ]]; then
  PLUGIN_ROOT="$(
    ls -d "$HOME/.config/herdr/plugins/github/persiyanov.reviewr-"* \
         "$HOME/.dotfiles/.config/herdr/plugins/github/persiyanov.reviewr-"* 2>/dev/null \
    | head -1
  )"
fi
CONFIG_DIR="${HERDR_PLUGIN_CONFIG_DIR:-$HOME/.config/herdr/plugins/config/persiyanov.reviewr}"
PANESH="${PLUGIN_ROOT:+$PLUGIN_ROOT/herdr/pane.sh}"

if [[ -z "$ws" || -z "$PLUGIN_ROOT" || ! -f "$PANESH" ]]; then
  echo "reviewr-smart: missing context (ws=$ws root=$PLUGIN_ROOT)" >&2
  exit 1
fi

mkdir -p "$STATE_DIR"
echo "$(date -u +%FT%TZ) invoke ws=$ws" >> "$STATE_DIR/reviewr-toggle-smart.log"

# One pane-list snapshot for the whole run.
panes_json="$("$H" pane list --workspace "$ws" 2>/dev/null)" || { echo "reviewr-smart: pane list failed" >&2; exit 1; }

reviewr_present=0
reviewr_focused=0
while IFS= read -r p; do
  [ -n "$p" ] || continue
  info="$("$H" pane process-info --pane "$p" 2>/dev/null)" || continue
  cnt="$(printf '%s' "$info" | jq -r '[.result.process_info.foreground_processes[]
      | select((((.argv0 // "")|split("/")|last) == "herdr-reviewr"))
      | select(((.argv // [])|index("--resolve-plugin-config")) == null)
    ] | length // empty' 2>/dev/null || echo 0)"
  [[ -z "$cnt" || "$cnt" == 0 ]] && continue
  reviewr_present=1
  if printf '%s' "$panes_json" | jq -e --arg p "$p" '.result.panes[] | select(.pane_id==$p) | .focused' >/dev/null 2>&1; then
    reviewr_focused=1
  fi
done <<EOF
$(printf '%s' "$panes_json" | jq -r '.result.panes[].pane_id // empty')
EOF

export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"
export HERDR_BIN_PATH="$H"
export HERDR_PLUGIN_ROOT="$PLUGIN_ROOT"
export HERDR_PLUGIN_CONFIG_DIR="$CONFIG_DIR"
export HERDR_WORKSPACE_ID="$ws"
export HERDR_PLUGIN_CONTEXT_JSON="{\"focused_pane_id\":\"${HERDR_ACTIVE_PANE_ID:-}\",\"focused_pane_cwd\":\"${HERDR_ACTIVE_PANE_CWD:-}\"}"

pane() { bash "$PANESH" "$1" >/dev/null 2>&1 || echo "reviewr-smart: pane.sh $1 failed" >&2; }

# Focused reviewr pane -> real toggle-off.
if [[ $reviewr_focused -eq 1 ]]; then
  echo "reviewr-smart: reviewr focused -> close (toggle off)"
  [[ $DRY_RUN -eq 1 ]] && exit 0
  pane close
  exit 0
fi

# Reviewr open but backgrounded (the post-send stale case) -> clear it, open fresh.
if [[ $reviewr_present -eq 1 ]]; then
  echo "reviewr-smart: stale background reviewr -> close + open fresh"
  [[ $DRY_RUN -eq 1 ]] && exit 0
  pane close
  pane open
  exit 0
fi

# Nothing open -> open fresh.
echo "reviewr-smart: no reviewr -> open"
[[ $DRY_RUN -eq 1 ]] && exit 0
pane open
exit 0