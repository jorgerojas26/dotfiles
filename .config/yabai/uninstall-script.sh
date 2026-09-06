#!/bin/zsh --norcs

set -o NO_UNSET -o ERREXIT

if (! sudo -nv) {
  echo "re-run after caching sudo in parent shell, by e.g. running:\n\t sudo -v" >&2
  exit 1
}

autoload -Uz colors && colors

log_op() { echo -n "$fg_bold[default]$*: " }
log_yep() { echo "$fg[green] ?? $fg_no_bold[default] $*" }
log_nope() { echo "$fg_bold[red] ? $fg_no_bold[default] $*" }

is_yabai_running() {
 declare -gA running_yabai

 log_op "Checking for Running yabai"

 eval "running_yabai=($(lsappinfo info yabai -only pid execpath bundlepath  | \
   sed 's/"/[/; s/"=/]=/; s/CFBundleExecutablePath/execpath/;s/LSBundlePath/bundlepath/' )
 )"
 
 if [[ -n ${running_yabai} ]] {
   running_yabai[parent]="$(ps -o ppid= $running_yabai[pid] | xargs ps -o comm= )"
   log_yep $(typeset -p running_yabai | grep -o '(.*)')
   return 0
 } else {
   log_nope
   return 1
 } 
}


cleanup_tcc() {
  local sys_rows user_rows
  local yabai_rows="FROM access WHERE client LIKE '%yabai';"

  echo "== Checking for Privacy [TCC (Transparency, Consent, and Control)] permission db entries =="
  
  log_op "Checking system-wide DB: "
  sys_rows="$(sudo sqlite3 -json /Library/Application\ Support/com.apple.TCC/TCC.db "SELECT * $yabai_rows")"
  if [[ -n "${sys_rows}" ]] {
    log_yep "Found:\n$sys_rows"
    echo "\nRemoving:"
    (set -x ; sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "DELETE $yabai_rows"
    sudo launchctl kickstart -kp system/com.apple.tccd.system)
  } else { log_nope "None found" }

  log_op "Checking user DB: "
  user_rows="$(sqlite3 -json $HOME/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT * $yabai_rows")"
  if [[ -n "${user_rows}" ]] {
    log_yep "Found:\n$user_rows"
    log_op "\nRemoving:"
    (set -x; sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "DELETE $yabai_rows")
  } else { log_nope "None found" }
  
  if [[ -n "${sys_rows}${user_rows}" ]] {
    echo "Restarting user level tccd: "
    (set -x; launchctl kickstart -kp gui/$UID/com.apple.tccd)
  }
}

if (is_yabai_running) {
  log_op "Stopping running yabai:" 
  if [[ $running_yabai[parent] =~ 'launchd$' ]] {
    zsh -xc "$running_yabai[bundlepath] --stop-service" 
    zsh -xc "$running_yabai[bundlepath] --uninstall-service"
  } else {
   zsh -xc "lsappinfo kill yabai"
  }
}

cleanup_tcc

log_op "Checking for SA: "
if [[ -d  /Library/ScriptingAdditions/yabai.osax ]] { 
  log_yep "Removing"
  sudo yabai --uninstall-sa 
  (set -x ; killall Dock )
} else { log_nope "Not found installed" }

log_op "Checking for Homebrew installed yabai"
if (whence brew &> /dev/null && command brew list yabai &> /dev/null) {
  log_yep "Removing"
  brew uninstall -f yabai
  brew cleanup --scrub yabai
} else { log_nope "Installed somehow else?" }

declare -a lo_bins lo_sudoers
lo_bins=($(login -qf $(whoami) $SHELL -c '/usr/bin/which -a yabai' || :))
lo_sudoers=($(sudo grep -l yabai /etc/sudoers /etc/sudoers.d/* || :))

if [[ "${#lo_bins[@]}" > 0 ]] {
  export found_lo=1
  exec >&2
  echo "Found remaining yabai binaries (when initializing under your dot}les) at:" 
  for y in "${lo_bins[@]}"; do echo "  - $y"; done
  echo "\nConsider e.g. \n\trm -f ${lo_bins[@]}"
}

if [[ "${#lo_sudoers[@]}" -gt 0 ]] {
  export found_lo=1
  exec >&2
  echo "== Found remaining sudoers mentions of yabai ==" 
  for sd in "${lo_sudoers[@]}"; do 
    echo "$sd: $(sudo grep yabai "$sd")"
  done
}

if [[ -f $HOME/.yabairc ]] {
  export found_lo=1
  echo "Config still present: " >&2
  ls -l "$HOME/.yabairc" >&2
}

if [[ -n "${found_lo:-}" ]] {
  exit 1
}
