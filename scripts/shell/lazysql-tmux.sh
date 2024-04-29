#!/bin/bash

SESSION="lazysql"
WINDOW="lazysql-session"
PROGRAM="lazysql"

tmux has-session -t $SESSION 2>/dev/null

if [ $? != 0 ]; then
	# Si la sesión no existe, crearla y ejecutar lazysql
	tmux new-session -d -s $SESSION 'lazysql'
fi

CURRENT_SESSION=$(tmux display-message -p '#S')

if [ $CURRENT_SESSION != $SESSION ]; then
	# Si la sesión actual no es la de lazysql, cambiar a la sesión de lazysql
	tmux switch-client -t $SESSION
else
	# Si la ventana de lazysql no existe, crearla
	tmux list-windows -t $SESSION | grep -q $WINDOW
	if [ $? != 0 ]; then
		tmux new-window -t $SESSION -n $WINDOW 'lazysql'
	else
		CURRENT_WINDOW=$(tmux display-message -p '#W')

		if [ $CURRENT_WINDOW == $WINDOW ]; then
			tmux switch-client -l
		else
			tmux select-window -t $SESSION:$WINDOW
		fi

	fi

fi
