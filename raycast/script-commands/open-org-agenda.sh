#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Agenda
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.description Opens the org-agenda buffer in neovide
# @raycast.author Jorge Rojas

appName="neovide"

neovide_is_running=$(if pgrep -x "$appName" >/dev/null; then echo "true"; else echo "false"; fi)

if [ "$neovide_is_running" == "true" ]; then
    osascript -e 'tell application "Neovide" to activate'
else
    neovide --neovim-bin 'nvim -c "lua require(\"orgmode\").agenda:agenda()"' --size 1024x1024
fi
