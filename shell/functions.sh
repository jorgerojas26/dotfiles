function cdd() {
    cd "$(ls -d -- */ | fzf)" || echo "Invalid directory"
}

function j() {
    fname=$(declare -f -F _z)

    [ -n "$fname" ] || source "$DOTLY_PATH/modules/z/z.sh"

    _z "$1"
}

function recent_dirs() {
    # This script depends on pushd. It works better with autopush enabled in ZSH
    escaped_home=$(echo $HOME | sed 's/\//\\\//g')
    selected=$(dirs -p | sort -u | fzf)

    cd "$(echo "$selected" | sed "s/\~/$escaped_home/")" || echo "Invalid directory"
}

function depersonalize_infobip_token_from_datadog() {
    cat $1 | sed -E 's/.*push\/([A-Z0-9-]+)\/depersonalize.*/\1/' | awk 'BEGIN{printf "["} {printf "\"%s\", ",$1} END{printf "\b\b]"}' >depersonalized.json

}

function do_bell() {
    echo -e "\a"
}

function reload_emacs() {
    /Applications/Emacs.app/Contents/MacOS/bin-arm64-11/emacsclient -e "(kill-emacs)"
    /Applications/Emacs.app/Contents/MacOS/Emacs --daemon
}
