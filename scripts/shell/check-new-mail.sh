#!/bin/bash

/opt/homebrew/bin/mbsync -a

/opt/homebrew/bin/mu index

# Search for new (unread) emails and extract the message IDs
unread_emails=$(/opt/homebrew/bin/mu find flag:unread --fields "f|s|t|i|l")

# Check if there are any new emails
if [[ -z "$unread_emails" ]]; then
    echo "No new email found."
    return
fi

# Loop through the unread emails (message IDs)
while IFS= read -r msgid; do
    # Extract email subject, sender, and body using the message ID
    sender=$(awk -F '|' '{print $1}' <<<"$msgid")
    subject=$(awk -F '|' '{print $2}' <<<"$msgid")
    to=$(awk -F '|' '{print $3}' <<<"$msgid" | awk -F '<' '{print $2}' | awk -F '>' '{print $1}')
    msgId=$(awk -F '|' '{print $4}' <<<"$msgid")
    file_path=$(awk -F '|' '{print $5}' <<<"$msgid")

    # Print the email details
    echo "New email from $sender:"
    echo "Subject: $subject"
    echo "To: $to"
    echo "Message ID: $msgId"
    echo "Path: $file_path"

    # Send a notification using terminal-notifier
    /opt/homebrew/bin/terminal-notifier -title "New email for: $to" -subtitle "$sender" -message "Subject: $subject" -sound "default" -appIcon "/Users/jorgerojas/.dotfiles/scripts/shell/mail-icon.svg" -execute "/Users/jorgerojas/.dotfiles/raycast/script-commands/open-aerc.sh"

    # Mark the email as read by renaming the file to add the 'S' flag
    if [[ "$file_path" == *"new"* ]]; then
        new_file_path=$(echo "$file_path" | sed 's/\/new\//\/cur\//')
        mv "$file_path" "$new_file_path:2,S" # Moves file to 'cur' directory and adds the 'S' flag
    elif [[ "$file_path" == *"cur"* && "$file_path" != *"S"* ]]; then
        mv "$file_path" "$file_path:2,S" # Adds the 'S' flag to the file if it's in 'cur' without the flag
    fi
done <<<"$unread_emails"
