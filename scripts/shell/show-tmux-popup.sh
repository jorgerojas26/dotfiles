#!/bin/zsh

# Default session name is empty
global_session_name=""

# Check for --global argument
if [ "$1" = "--global" ]; then
    global_session_name="$2"
    shift 2 # Remove --global and its value from the arguments
fi

# Exit if no command is provided as an argument.
if [ -z "$1" ]; then
    echo "Error: No command provided." >&2
    echo "Usage: $0 [--global <session_name>] <command> [args...]" >&2
    exit 1
fi

# Get the current path of the calling tmux pane.
current_path=$(tmux display-message -p '#{pane_current_path}')

# Create a unique session name including the parent session and the command.
if [ -n "$global_session_name" ]; then
    session_name="$global_session_name"
else
    session_name="_popup_$(tmux display -p '#S')_$1"
fi

# Check if a session with this name already exists.
if ! tmux has-session -t "$session_name" 2>/dev/null; then
    # If it doesn't exist, create a new detached session.
    # The script's own environment now has the correct TERM and TERM_PROGRAM
    # passed from the tmux.conf binding. We forward them to the new session.
    tmux new-session -d -s "$session_name" -c "$current_path" \
        -e "TERM=${TERM}" \
        -e "TERM_PROGRAM=${TERM_PROGRAM}" \
        "$@"

    # Configure the new session to behave like a popup.
    tmux set-option -t "$session_name" status off
    tmux set-option -t "$session_name" key-table popup
    tmux set-option -t "$session_name" prefix None
    tmux set-option -t "$session_name" allow-passthrough on
fi

# This command is crucial. It tells the client inside the popup window
# to attach to our newly created or already existing session.
exec tmux attach-session -t "$session_name"
