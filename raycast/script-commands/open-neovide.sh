#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Agenda
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.description Opens neovide as a terminal emulator
# @raycast.author Jorge Rojas

# open -a "/Applications/Neovide.app" --args -- -u "$HOME/.config/neoterm/neoterm.lua"
open -a "/Applications/Neovide.app" --args -- --clean -u "$HOME/.config/neoterm/neoterm.lua"
