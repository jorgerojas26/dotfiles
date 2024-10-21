#!/bin/bash

next_appointment=$(calcurse -n)

title="Next appointment"
summary=$(echo "$next_appointment" | awk -F '|' '{print $1}' | sed 's/Summary: //g' | tr -d '\n' | sed 's/next appointment:   //g')
organizer=$(echo "$next_appointment" | awk -F '|' '{print $2}')
attendees=$(echo "$next_appointment" | awk -F '|' '{print $3}' | sed 's/,$//')
location=$(echo "$next_appointment" | awk -F '|' '{print $4}' | sed 's/Location: //g' | tr -d '\n' | sed 's/ //g')

message="$summary$organizer\n$location"
echo "$message"

terminal-notifier -title "$title" -message '"'"$message"'"' -open "$location"
