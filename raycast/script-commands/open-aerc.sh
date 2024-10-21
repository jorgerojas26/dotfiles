#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Aerc
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author Jorge Rojas

osascript <<EOF
tell application "iTerm"
    create window with default profile
    tell current session of current window
        write text "aerc; exit"
    end tell
end tell
EOF
