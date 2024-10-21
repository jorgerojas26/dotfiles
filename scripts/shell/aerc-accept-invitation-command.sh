#!/bin/bash

aerc ":accept"
sleep 1
aerc :send-keys ":wq" "<Enter>"
aerc :send-keys y "<Enter>"
sleep 1
aerc :send
aerc :q
aerc :pipe /Users/jorgerojas/.dotfiles/scripts/shell/aerc-to-calcurse.sh
sleep 0.1
aerc :send-keys q
