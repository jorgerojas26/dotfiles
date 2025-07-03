#!/bin/bash

echo "Getting next appointment..."
next_appointment=$(calcurse -n)
echo "$next_appointment"

title="Next appointment"
summary=$(echo "$next_appointment" | awk -F '|' '{print $1}' | sed 's/Summary: //g' | tr -d '\n' | sed 's/next appointment:   //g')
organizer=$(echo "$next_appointment" | awk -F '|' '{print $2}')
# attendees=$(echo "$next_appointment" | awk -F '|' '{print $3}' | sed 's/,$//')
location=$(echo "$next_appointment" | awk -F '|' '{print $4}' | sed 's/Location: //g' | tr -d '\n' | sed 's/ //g')

message="$summary$organizer\n$location"
echo "$message"

## Check if there is a location and if so, add it to the notification
if [ -n "$location" ]; then
    terminal-notifier -title "$title" -message '"'"$message"'"' -open "$location" -sound "Funk"
else
    terminal-notifier -title "$title" -message '"'"$message"'"' -sound "Funk"
fi
