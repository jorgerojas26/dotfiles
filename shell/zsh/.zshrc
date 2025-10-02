# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# PLUGIN MANAGER
source $(brew --prefix)/opt/antidote/share/antidote/antidote.zsh

export NVM_LAZY_LOAD=true
antidote load

# POWERLEVEL10K
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


source "$DOTFILES_PATH/shell/init.sh"

fpath=("$DOTFILES_PATH/shell/zsh/themes" "$DOTFILES_PATH/shell/zsh/completions" "$DOTLY_PATH/shell/zsh/themes" "$DOTLY_PATH/shell/zsh/completions" $fpath)

# source "$DOTLY_PATH/shell/zsh/bindings/dot.zsh"
# source "$DOTLY_PATH/shell/zsh/bindings/reverse_search.zsh"
# source "$DOTFILES_PATH/shell/zsh/key-bindings.zsh"

export XDG_CONFIG_HOME="$HOME/.config"

# EDITOR
export EDITOR=nvim

# PATH
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
export PATH="/Users/jorgerojas/.local/bin:$PATH"
# eval "$(/opt/homebrew/bin/brew shellenv)"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH=:"/usr/local/go/bin:$PATH"
export PATH="$HOME/.go/bin:$PATH"





# PLUGIN CONFIGURATION
# FZF-TAB
zstyle ':fzf-tab:complete:*:*' fzf-preview 'preview_file_or_folder $realpath --preview-window=right:70%'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:*' continuous-trigger 'tab'
# zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
# zstyle ':fzf-tab:*' fzf-command fzf-tmux
zstyle ':fzf-tab:complete:*:*' popup-pad 100 100

# AUTO NOTIFY
AUTO_NOTIFY_IGNORE+=("docker" "man" "sleep", "lg", "tmux", "nvim", "nvim .", "vim", "vi", "git", "ssh", "lazygit", "tmux a")


# PNPM
export PNPM_HOME="/Users/jorgerojas/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# NVM
nvm() {
    unset -f nvm
    export NVM_DIR=~/.nvm
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
    nvm "$@"
}
node() {
    unset -f node
    export NVM_DIR=~/.nvm
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
    node "$@"
}
npm() {
    unset -f npm
    export NVM_DIR=~/.nvm
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
    npm "$@"
}


export ZK_NOTEBOOK_DIR="$HOME/second-brain"

. "$HOME/.atuin/bin/env"
zvm_after_init_commands+=(eval "$(atuin init zsh)")
