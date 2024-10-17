# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#!/usr/bin/env zsh
# Uncomment for debuf with `zprof`
# zmodload zsh/zprof

# ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
# plugins+=(zsh-vi-mode)

export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="robbyrussell"
ZSH_THEME="powerlevel10k/powerlevel10k"
source $ZSH/oh-my-zsh.sh

source "$DOTFILES_PATH/shell/init.sh"

fpath=("$DOTFILES_PATH/shell/zsh/themes" "$DOTFILES_PATH/shell/zsh/completions" "$DOTLY_PATH/shell/zsh/themes" "$DOTLY_PATH/shell/zsh/completions" $fpath)

source $DOTFILES_PATH/shell/zsh/completions/fzf-zsh-completion.sh
bindkey '^I' fzf_completion
export FZF_COMPLETION_OPTS='--border --info=inline --preview="bat --color=always {}"'


# autoload -Uz promptinit && promptinit
# prompt ${DOTLY_THEME:-codely}

source "$DOTLY_PATH/shell/zsh/bindings/dot.zsh"
source "$DOTLY_PATH/shell/zsh/bindings/reverse_search.zsh"
source "$DOTFILES_PATH/shell/zsh/key-bindings.zsh"



# ZSH Ops
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FCNTL_LOCK
setopt +o nomatch
# setopt autopushd

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Start Zim
source "$ZIM_HOME/init.zsh"

# Async mode for autocompletion
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_HIGHLIGHT_MAXLENGTH=300



export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# eval "$(starship init zsh)"

# autoload -U add-zsh-hook
# load-nvmrc() {
#   [[ -a .nvmrc ]] || return
#   local node_version="$(nvm version)"
#   local nvmrc_path="$(nvm_find_nvmrc)"
#
#   if [ -n "$nvmrc_path" ]; then
#     local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
#
#     if [ "$nvmrc_node_version" = "N/A" ]; then
#       nvm install
#     elif [ "$nvmrc_node_version" != "$node_version" ]; then
#       nvm use
#     fi
#   elif [ "$node_version" != "$(nvm version default)" ]; then
#     echo "Reverting to nvm default version"
#     nvm use default
#   fi
# }
# add-zsh-hook chpwd load-nvmrc
# load-nvmrc
export EDITOR=nvim

export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_SDK_ROOT/emulator
export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH="/opt/homebrew/opt/mongodb-community@4.4/bin:$PATH"
export PATH=$PATH:/flutter/bin
export PATH=$PATH:/opt/homebrew/bin
eval "$(/opt/homebrew/bin/brew shellenv)"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH=:"/usr/local/go/bin:$PATH"
export PATH="$HOME/.go/bin:$PATH"
# export PATH="$HOME/user/.local/bin:$PATH"
export PATH=$PATH:/Users/jorgerojas/.config/emacs/bin

eval "$(rbenv init -)"

alias lg="lazygit"
alias findp="sudo lsof -i -P -n | grep LISTEN | grep "

# if [ -n "$TMUX" ]; then
#     eval "$(tmux show-environment -s NVIM_LISTEN_ADDRESS 2> /dev/null)"
# else
#     export NVIM_LISTEN_ADDRESS=/tmp/nvimsocket
# fi
#
# if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
#     export VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
#     export EDITOR="nvr -cc split --remote-wait +'set bufhidden=wipe'"
# else
#     export VISUAL="nvim"
#     export EDITOR="nvim"
# fi
#
# export EDITOR="$VISUAL"

# source /opt/homebrew/opt/powerlevel10k/powerlevel10k.zsh-theme


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
#
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"


# pnpm
export PNPM_HOME="/Users/jorgerojas/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
# bun completions
[ -s "/Users/jorgerojas/.bun/_bun" ] && source "/Users/jorgerojas/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

PROMPT='%{$fg[yellow]%}[%D{%f/%m/%y} %D{%L:%M:%S}] '$PROMPT


# Created by `pipx` on 2024-06-07 20:29:47
export PATH="$PATH:/Users/jorgerojas/.local/bin"
export OLLAMA_API_BASE=http://127.0.0.1:11434


#compdef supabase
compdef _supabase supabase

# zsh completion for supabase                             -*- shell-script -*-

__supabase_debug()
{
    local file="$BASH_COMP_DEBUG_FILE"
    if [[ -n ${file} ]]; then
        echo "$*" >> "${file}"
    fi
}

_supabase()
{
    local shellCompDirectiveError=1
    local shellCompDirectiveNoSpace=2
    local shellCompDirectiveNoFileComp=4
    local shellCompDirectiveFilterFileExt=8
    local shellCompDirectiveFilterDirs=16
    local shellCompDirectiveKeepOrder=32

    local lastParam lastChar flagPrefix requestComp out directive comp lastComp noSpace keepOrder
    local -a completions

    __supabase_debug "\n========= starting completion logic =========="
    __supabase_debug "CURRENT: ${CURRENT}, words[*]: ${words[*]}"

    # The user could have moved the cursor backwards on the command-line.
    # We need to trigger completion from the $CURRENT location, so we need
    # to truncate the command-line ($words) up to the $CURRENT location.
    # (We cannot use $CURSOR as its value does not work when a command is an alias.)
    words=("${=words[1,CURRENT]}")
    __supabase_debug "Truncated words[*]: ${words[*]},"

    lastParam=${words[-1]}
    lastChar=${lastParam[-1]}
    __supabase_debug "lastParam: ${lastParam}, lastChar: ${lastChar}"

    # For zsh, when completing a flag with an = (e.g., supabase -n=<TAB>)
    # completions must be prefixed with the flag
    setopt local_options BASH_REMATCH
    if [[ "${lastParam}" =~ '-.*=' ]]; then
        # We are dealing with a flag with an =
        flagPrefix="-P ${BASH_REMATCH}"
    fi

    # Prepare the command to obtain completions
    requestComp="${words[1]} __complete ${words[2,-1]}"
    if [ "${lastChar}" = "" ]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go completion code.
        __supabase_debug "Adding extra empty parameter"
        requestComp="${requestComp} \"\""
    fi

    __supabase_debug "About to call: eval ${requestComp}"

    # Use eval to handle any environment variables and such
    out=$(eval ${requestComp} 2>/dev/null)
    __supabase_debug "completion output: ${out}"

    # Extract the directive integer following a : from the last line
    local lastLine
    while IFS='\n' read -r line; do
        lastLine=${line}
    done < <(printf "%s\n" "${out[@]}")
    __supabase_debug "last line: ${lastLine}"

    if [ "${lastLine[1]}" = : ]; then
        directive=${lastLine[2,-1]}
        # Remove the directive including the : and the newline
        local suffix
        (( suffix=${#lastLine}+2))
        out=${out[1,-$suffix]}
    else
        # There is no directive specified.  Leave $out as is.
        __supabase_debug "No directive found.  Setting do default"
        directive=0
    fi

    __supabase_debug "directive: ${directive}"
    __supabase_debug "completions: ${out}"
    __supabase_debug "flagPrefix: ${flagPrefix}"

    if [ $((directive & shellCompDirectiveError)) -ne 0 ]; then
        __supabase_debug "Completion received error. Ignoring completions."
        return
    fi

    local activeHelpMarker="_activeHelp_ "
    local endIndex=${#activeHelpMarker}
    local startIndex=$((${#activeHelpMarker}+1))
    local hasActiveHelp=0
    while IFS='\n' read -r comp; do
        # Check if this is an activeHelp statement (i.e., prefixed with $activeHelpMarker)
        if [ "${comp[1,$endIndex]}" = "$activeHelpMarker" ];then
            __supabase_debug "ActiveHelp found: $comp"
            comp="${comp[$startIndex,-1]}"
            if [ -n "$comp" ]; then
                compadd -x "${comp}"
                __supabase_debug "ActiveHelp will need delimiter"
                hasActiveHelp=1
            fi

            continue
        fi

        if [ -n "$comp" ]; then
            # If requested, completions are returned with a description.
            # The description is preceded by a TAB character.
            # For zsh's _describe, we need to use a : instead of a TAB.
            # We first need to escape any : as part of the completion itself.
            comp=${comp//:/\\:}

            local tab="$(printf '\t')"
            comp=${comp//$tab/:}

            __supabase_debug "Adding completion: ${comp}"
            completions+=${comp}
            lastComp=$comp
        fi
    done < <(printf "%s\n" "${out[@]}")

    # Add a delimiter after the activeHelp statements, but only if:
    # - there are completions following the activeHelp statements, or
    # - file completion will be performed (so there will be choices after the activeHelp)
    if [ $hasActiveHelp -eq 1 ]; then
        if [ ${#completions} -ne 0 ] || [ $((directive & shellCompDirectiveNoFileComp)) -eq 0 ]; then
            __supabase_debug "Adding activeHelp delimiter"
            compadd -x "--"
            hasActiveHelp=0
        fi
    fi

    if [ $((directive & shellCompDirectiveNoSpace)) -ne 0 ]; then
        __supabase_debug "Activating nospace."
        noSpace="-S ''"
    fi

    if [ $((directive & shellCompDirectiveKeepOrder)) -ne 0 ]; then
        __supabase_debug "Activating keep order."
        keepOrder="-V"
    fi

    if [ $((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]; then
        # File extension filtering
        local filteringCmd
        filteringCmd='_files'
        for filter in ${completions[@]}; do
            if [ ${filter[1]} != '*' ]; then
                # zsh requires a glob pattern to do file filtering
                filter="\*.$filter"
            fi
            filteringCmd+=" -g $filter"
        done
        filteringCmd+=" ${flagPrefix}"

        __supabase_debug "File filtering command: $filteringCmd"
        _arguments '*:filename:'"$filteringCmd"
    elif [ $((directive & shellCompDirectiveFilterDirs)) -ne 0 ]; then
        # File completion for directories only
        local subdir
        subdir="${completions[1]}"
        if [ -n "$subdir" ]; then
            __supabase_debug "Listing directories in $subdir"
            pushd "${subdir}" >/dev/null 2>&1
        else
            __supabase_debug "Listing directories in ."
        fi

        local result
        _arguments '*:dirname:_files -/'" ${flagPrefix}"
        result=$?
        if [ -n "$subdir" ]; then
            popd >/dev/null 2>&1
        fi
        return $result
    else
        __supabase_debug "Calling _describe"
        if eval _describe $keepOrder "completions" completions $flagPrefix $noSpace; then
            __supabase_debug "_describe found some completions"

            # Return the success of having called _describe
            return 0
        else
            __supabase_debug "_describe did not find completions."
            __supabase_debug "Checking if we should do file completion."
            if [ $((directive & shellCompDirectiveNoFileComp)) -ne 0 ]; then
                __supabase_debug "deactivating file completion"

                # We must return an error code here to let zsh know that there were no
                # completions found by _describe; this is what will trigger other
                # matching algorithms to attempt to find completions.
                # For example zsh can match letters in the middle of words.
                return 1
            else
                # Perform file completion
                __supabase_debug "Activating file completion"

                # We must return the result of this command, so it must be the
                # last command, or else we must store its result to return it.
                _arguments '*:filename:_files'" ${flagPrefix}"
            fi
        fi
    fi
}

# don't run the completion function when being source-ed or eval-ed
if [ "$funcstack[1]" = "_supabase" ]; then
    _supabase
fi
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/jorgerojas/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/jorgerojas/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/jorgerojas/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/jorgerojas/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
