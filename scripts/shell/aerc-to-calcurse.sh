#!/bin/bash

# Read email content from stdin (piped from aerc)
ics_content=$(cat)

# ics_content='BEGIN:VCALENDAR
# PRODID:-//Proton AG//macos-mail 5.0.34.3//EN
# VERSION:2.0
# METHOD:REQUEST
# CALSCALE:GREGORIAN
# BEGIN:VTIMEZONE
# TZID:America/Caracas
# LAST-MODIFIED:20240317T125125Z
# X-LIC-LOCATION:America/Caracas
# BEGIN:STANDARD
# TZNAME:-04
# TZOFFSETFROM:-0400
# TZOFFSETTO:-0400
# DTSTART:19700101T000000
# END:STANDARD
# END:VTIMEZONE
# BEGIN:VEVENT
# SUMMARY:Invitacion de prueba
# STATUS:CONFIRMED
# DTSTART;TZID=America/Caracas:20241019T170000
# DTEND;TZID=America/Caracas:20241019T173000
# ORGANIZER;CN=jorge@andinotechnologies.com:mailto:jorge@andinotechnologies.com
# ATTENDEE;CN=jorgeluisrojasb@gmail.com;ROLE=REQ-PARTICIPANT;RSVP=TRUE;PARTSTAT=NEEDS-ACTION;X-PM-TOKEN=38a76a23e9a3f948c7e3440a2fe4b2b4302d4d5d:mailto:jorgeluisrojasb@gmail.com
# UID:H8kddX6zc3GK1-ZEO0GOJPWoIWk-@proton.me
# SEQUENCE:0
# DTSTAMP:20241019T203711Z
# X-PM-SHARED-EVENT-ID:JnPoyUrXEvi9mZRcF9WyCyOg2ky05LfUdkPQodPGbg2N0-G2lDTF7J2wiB8OtS4MxfvhEJkVxDx13qIkaTxSX6MpdHrRfeqPxmUS8uyt_N8=
# X-PM-SESSION-KEY:UyXJ87a0aj9XsnadL8wyMqqh9apG8u9ve+z30IjU0PA=
# END:VEVENT
# END:VCALENDAR'

echo "$ics_content"

my_timezone=$(readlink /etc/localtime | awk -F 'zoneinfo\/' '{print $2}' | tr -d '\n')

summary=$(echo "$ics_content" | awk -F 'SUMMARY:' '{print $2}' | tr -d '\n')
start=$(echo "$ics_content" | awk -F 'DTSTART;TZID' '{print $2}' | awk -F ':' '{print $2}' | tr -d '\n')
end=$(echo "$ics_content" | awk -F 'DTEND;TZID' '{print $2}' | awk -F ':' '{print $2}' | tr -d '\n')
organizer=$(echo "$ics_content" | awk -F 'ORGANIZER;CN=' '{print $2}' | awk -F ':' '{print $1}' | tr -d '\n')
# attendees=$(echo "$ics_content" | awk -F 'mailto:' '{print $2}' | tr -d '\n')
attendees=$(echo "$ics_content" | awk -F 'mailto:' '{for (i=2; i<=NF; i++) printf "%s, ", $i}' | sed 's/,$//')
timezone=$(echo "$ics_content" | awk -F 'TZID:' '{print $2}')
location=$(echo "$ics_content" | awk -F 'X-GOOGLE-CONFERENCE:' '{print $2}' | tr -d '\n')

formatted_start=$(echo "$start" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)T\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5/')
formatted_end=$(echo "$end" | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)T\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5/')

echo "$timezone"

if [[ "$timezone" != "$my_timezone" ]]; then
    formatted_start=$(date --date="TZ=\"$timezone\" $formatted_start" +"%m/%d/%Y %H:%M")
    formatted_end=$(date --date="TZ=\"$timezone\" $formatted_end" +"%m/%d/%Y %H:%M")
fi

description="Summary: $summary | "
description+="Organizer: $organizer | "
description+="Attendees: $attendees | "
description+="Location: $location"

echo "$description"

apts_file="$HOME/.local/share/calcurse/apts"

start_date=$(echo "$formatted_start" | awk '{print $1}')
start_date_time=$(echo "$formatted_start" | awk '{print $2}')
end_date=$(echo "$formatted_end" | awk '{print $1}')
end_date_time=$(echo "$formatted_end" | awk '{print $2}')

new_appointment=$(echo "$start_date @ $start_date_time -> $end_date @ $end_date_time|$description")
new_appointment=$(echo "$new_appointment" | tr -d '\r')
echo "$new_appointment"

echo "$new_appointment" >>"$apts_file"
