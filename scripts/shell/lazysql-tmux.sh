#!/bin/bash

# Nombre del popup
popup_name="lazysql"

# Verifica si el popup ya existe y está visible
popup_id=$(tmux list-panes -a -F "#{pane_id}:#{pane_title}" | grep ":${popup_name}$" | cut -d: -f1)

if [ -n "$popup_id" ]; then
    # Si el popup está abierto, ciérralo
    tmux kill-pane -t "$popup_id"
else
    # Si el popup no está abierto, ábrelo
    tmux display-popup -E -d '#{pane_current_path}' -w 90% -h 90% -T "${popup_name}" "lazysql"
fi
