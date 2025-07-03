#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Emacs with mu4e
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author Jorge Rojas

appName="emacsclient"

emacs_is_running=$(if pgrep -x "$appName" >/dev/null; then echo "true"; else echo "false"; fi)

if [ "$emacs_is_running" == "true" ]; then
    open -a "Emacs"
else
    /Applications/Emacs.app/Contents/MacOS/bin-arm64-11/emacsclient -c -e "(mu4e)" -e "(add-to-list 'default-frame-alist '(height . 100))" -e "(add-to-list 'default-frame-alist '(width . 90))" -e "(select-frame-set-input-focus (selected-frame))"
fi
