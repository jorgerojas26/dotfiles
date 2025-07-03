function cd() {
    new_directory="$*"
    if [ $# -eq 0 ]; then
        new_directory=${HOME}
    fi
    builtin cd "${new_directory}" && eza --icons
}

function cdd() {
    cd "$(ls -d -- */ | fzf)" || echo "Invalid directory"
}

# function j() {
#     fname=$(declare -f -F _z)
#
#     [ -n "$fname" ] || source "$DOTLY_PATH/modules/z/z.sh"
#
#     _z "$1"
# }

function recent_dirs() {
    # This script depends on pushd. It works better with autopush enabled in ZSH
    escaped_home=$(echo $HOME | sed 's/\//\\\//g')
    selected=$(dirs -p | sort -u | fzf)

    cd "$(echo "$selected" | sed "s/\~/$escaped_home/")" || echo "Invalid directory"
}

# function depersonalize_infobip_token_from_datadog() {
#     cat $1 | sed -E 's/.*push\/([A-Z0-9-]+)\/depersonalize.*/\1/' | awk 'BEGIN{printf "["} {printf "\"%s\", ",$1} END{printf "\b\b]"}' >depersonalized.json
#
# }

# function do_bell() {
#     echo -e "\a"
# }

function reload_emacs() {
    /Applications/Emacs.app/Contents/MacOS/bin-arm64-11/emacsclient -e "(kill-emacs)"
    /Applications/Emacs.app/Contents/MacOS/Emacs --daemon
}

function gpg-reload() {
    pkill scdaemon
    pkill gpg-agent
    gpg-connect-agent /bye >/dev/null 2>&1
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
    gpgconf --reload gpg-agent
}

timezsh() {
    shell=${1-$SHELL}
    for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

work() {
    # Check if a Task ID was provided
    if [[ -z "$1" ]]; then
        echo "Error: Please provide a Task ID."
        echo "Usage: ttime <task_id> [duration]"
        echo "Example: ttime 7"      # Uses default 1h duration
        echo "Example: ttime 12 30m" # Uses 30m duration
        return 1                     # Exit the function with an error status
    fi

    local task_id=$1
    # Use the second argument as duration, or default to '1h' if not provided
    local duration=${2:-1h}

    echo "Starting timer for task $task_id ($duration)..."

    # Execute the command sequence
    task "$task_id" start &&
        echo "Task $task_id started. Countdown running..." &&
        countdown "$duration" &&
        echo "Countdown finished. Stopping task $task_id..." &&
        task "$task_id" stop &&
        echo "Task $task_id stopped."
}
