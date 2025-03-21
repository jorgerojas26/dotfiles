# Enable aliases to be sudo’ed
alias sudo='sudo '

alias ls='eza --icons'
alias ..="cd .."
alias ...="cd ../.."
alias ll="eza --icons -l"
alias la="eza --icons -la"
alias ~="cd ~"
alias dotfiles='cd $DOTFILES_PATH'

# Git
alias gaa="git add -A"
alias gc='$DOTLY_PATH/bin/dot git commit'
alias gca="git add --all && git commit --amend --no-edit"
alias gco="git checkout"
alias gd='$DOTLY_PATH/bin/dot git pretty-diff'
alias gs="git status -sb"
alias gf="git fetch --all -p"
alias gps="git push"
alias gpsf="git push --force"
alias gpl="git pull --rebase --autostash"
alias gb="git branch"
alias gl='$DOTLY_PATH/bin/dot git pretty-log'

# Utils
alias k='kill -9'
alias i.='(idea $PWD &>/dev/null &)'
alias c.='(code $PWD &>/dev/null &)'
alias o.='open .'
alias up='dot package update_all'
alias nvim="nvim --listen /tmp/nvim-server-$(tmux display-message -p '#S')-$(tmux display-message -p '#I')-$(tmux display-message -p '#P').pipe"
alias le='~/Library/Android/sdk/tools/emulator -list-avds'
# alias zellij='zellij attach --index 0 --create'
alias zellij='zellij'
alias ec="emacsclient -a '' -c"
alias lg="lazygit"
