#!/bin/bash

# Read email content from stdin (piped from aerc)
ics_content=$(cat)

# echo "$ics_content"

my_timezone=$(readlink /etc/localtime | awk -F 'zoneinfo\/' '{print $2}' | tr -d '\n')

summary=$(echo "$ics_content" | awk -F 'SUMMARY:' '{print $2}' | tr -d '\n')
start=$(echo "$ics_content" | awk -F 'DTSTART;TZID' '{print $2}' | awk -F ':' '{print $2}' | tr -d '\n')
end=$(echo "$ics_content" | awk -F 'DTEND;TZID' '{print $2}' | awk -F ':' '{print $2}' | tr -d '\n')
organizer=$(echo "$ics_content" | awk -F 'ORGANIZER;CN=' '{print $2}' | awk -F ':' '{print $1}' | tr -d '\n')
attendees=$(echo "$ics_content" | awk -F 'mailto:' '{for (i=2; i<=NF; i++) printf "%s, ", $i}' | sed 's/,$//')
timezone=$(echo "$ics_content" | awk -F 'TZID:' '{print $2}' | tr -d '\n')
location=$(echo "$ics_content" | awk -F 'X-GOOGLE-CONFERENCE:' '{print $2}' | tr -d '\n')

formatted_start=$(echo "$start" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)T\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\2\/\3\/\1 \4:\5/')
formatted_end=$(echo "$end" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)T\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\2\/\3\/\1 \4:\5/')
converted_start="$formatted_start"
converted_end="$formatted_end"

if [[ "$timezone" != "$my_timezone" ]]; then
    converted_start=$(gdate --date="TZ=\"$timezone\" $formatted_start" +"%m/%d/%Y %H:%M")
    converted_end=$(gdate --date="TZ=\"$timezone\" $formatted_end" +"%m/%d/%Y %H:%M")
fi

description="Summary: $summary | "
description+="Organizer: $organizer | "
description+="Attendees: $attendees | "
description+="Location: $location"

description=$(echo "$description" | tr -d '\r')

echo "$description"

apts_file="$HOME/.local/share/calcurse/apts"

start_date=$(echo "$converted_start" | awk '{print $1}')
start_date_time=$(echo "$converted_start" | awk '{print $2}')
end_date=$(echo "$converted_end" | awk '{print $1}')
end_date_time=$(echo "$converted_end" | awk '{print $2}')

new_appointment=$(echo "$start_date @ $start_date_time -> $end_date @ $end_date_time|$description")
new_appointment=$(echo "$new_appointment")
echo "$new_appointment"

# grep -v -i "$summary" ~/.local/share/calcurse/apts >~/.local/share/calcurse/apts.tmp && mv ~/.local/share/calcurse/apts.tmp ~/.local/share/calcurse/apts

echo "$new_appointment" >>"$apts_file"
