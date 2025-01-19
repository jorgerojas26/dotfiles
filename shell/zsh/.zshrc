#!/usr/bin/env zsh
# Uncomment for debuf with `zprof`
# zmodload zsh/zprof


# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


if [ -f "$(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ]; then
    source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
    # Following 4 lines modify the escape key to `kj`
    ZVM_VI_ESCAPE_BINDKEY=jk
    ZVM_VI_INSERT_ESCAPE_BINDKEY=$ZVM_VI_ESCAPE_BINDKEY
    ZVM_VI_VISUAL_ESCAPE_BINDKEY=$ZVM_VI_ESCAPE_BINDKEY
    ZVM_VI_OPPEND_ESCAPE_BINDKEY=$ZVM_VI_ESCAPE_BINDKEY

    function zvm_after_lazy_keybindings() {
      # Remap to go to the beginning of the line
      zvm_bindkey vicmd 'gh' beginning-of-line
      # Remap to go to the end of the line
      zvm_bindkey vicmd 'gl' end-of-line
    }

    # Disable the cursor style feature
    # I my cursor above in the cursor section
    # https://github.com/jeffreytse/zsh-vi-mode?tab=readme-ov-file#custom-cursor-style
    #
    # NOTE: My cursor was not blinking when using wezterm with the "wezterm"
    # terminfo, setting it to a blinking cursor below fixed that
    # I also set my term to "xterm-kitty" for this to work
    #
    # This also specifies the blinking cursor
    # ZVM_CURSOR_STYLE_ENABLED=false
    # ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
    # ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
    # ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_BLINKING_UNDERLINE

    # Source .fzf.zsh so that the ctrl+r bindkey is given back fzf
    # zvm_after_init_commands+=('[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh')
fi


# Smarter cd command, it remembers which directories you use most
# frequently, so you can "jump" to them in just a few keystrokes.
# https://github.com/ajeetdsouza/zoxide
# https://github.com/skywind3000/z.lua
# if command -v zoxide &>/dev/null; then
#     eval "$(zoxide init zsh)"
#
#     alias cd='z'
#     # Alias below is same as 'cd -', takes to the previous directory
#     alias cdd='z -'
#
#     #Since I migrated from z.lua, I can import my data
#     # zoxide import --from=z "$HOME/.zlua" --merge
#
#     # Useful commands
#     # z foo<SPACE><TAB>  # show interactive completions
# fi

# export ZSH="$HOME/.oh-my-zsh"
# ZSH_THEME="powerlevel10k/powerlevel10k"
# source $ZSH/oh-my-zsh.sh

source "$DOTFILES_PATH/shell/init.sh"

fpath=("$DOTFILES_PATH/shell/zsh/themes" "$DOTFILES_PATH/shell/zsh/completions" "$DOTLY_PATH/shell/zsh/themes" "$DOTLY_PATH/shell/zsh/completions" $fpath)

export FZF_COMPLETION_OPTS="--preview 'bat --color=always {1}'"
source $DOTFILES_PATH/shell/zsh/completions/fzf-zsh-completion.sh
bindkey '^I' fzf_completion

source "$DOTLY_PATH/shell/zsh/bindings/dot.zsh"
source "$DOTLY_PATH/shell/zsh/bindings/reverse_search.zsh"
source "$DOTFILES_PATH/shell/zsh/key-bindings.zsh"

# ZSH Ops
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FCNTL_LOCK
setopt +o nomatch

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

# Start Zim
source "$ZIM_HOME/init.zsh"

# Async mode for autocompletion
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_HIGHLIGHT_MAXLENGTH=300



export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

  
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
export PATH=$PATH:/Users/jorgerojas/.config/emacs/bin
export XDG_CONFIG_HOME=$HOME/.config

eval "$(rbenv init -)"

alias lg="lazygit"
alias findp="sudo lsof -i -P -n | grep LISTEN | grep "

if [ -n "$TMUX" ]; then
    eval "$(tmux show-environment -s NVIM_LISTEN_ADDRESS 2> /dev/null)"
else
    export NVIM_LISTEN_ADDRESS=/tmp/nvimsocket
fi

if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
    export VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
    export EDITOR="nvr -cc split --remote-wait +'set bufhidden=wipe'"
else
    export VISUAL="nvim"
    export EDITOR="nvim"
fi
#
# export EDITOR="$VISUAL"


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

# don't run the completion function when being source-ed or eval-ed
if [ "$funcstack[1]" = "_supabase" ]; then
    _supabase
fi
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/jorgerojas/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/jorgerojas/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/jorgerojas/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/jorgerojas/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

