#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Emacs Mu4e
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author Jorge Rojas

appName="emacsclient"

emacs_is_running=$(if pgrep -x "$appName" >/dev/null; then echo "true"; else echo "false"; fi)

# if [ "$emacs_is_running" == "true" ]; then
#     frontApp=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')
#
#     if [ "$frontApp" == "Emacs-arm64-11" ]; then
#
#         # Check if the Emacs window is visible
#         emacs_window_is_visible=$(osascript -e 'tell application "Emacs" to get visible of front window')
#
#         if [ "$emacs_window_is_visible" == "true" ]; then
#             osascript -e 'tell application "Emacs" to set visible of front window to false'
#         else
#             open -a "Emacs"
#             osascript -e 'tell application "Emacs" to set visible of front window to true'
#         fi
#
#     else
#         osascript -e 'tell application "Emacs" to set visible of front window to true'
#         open -a "Emacs"
#     fi
# else
#     /Applications/Emacs.app/Contents/MacOS/bin-arm64-11/emacsclient -c -e "(org-journal-new-entry nil)" -e "(add-to-list 'default-frame-alist '(height . 100))" -e "(select-frame-set-input-focus (selected-frame))" &
# fi

if [ "$emacs_is_running" == "true" ]; then
    open -a "Emacs"
else
    /Applications/Emacs.app/Contents/MacOS/bin-arm64-11/emacsclient -c -e "(mu4e)" -e "(add-to-list 'default-frame-alist '(height . 100))" -e "(select-frame-set-input-focus (selected-frame))"
fi
