#! /bin/bash

# Reading the .env file
while read -r line || [[ -n "$line" ]]; do

	# Splitting line into name and value
	IFS='=' read -ra parts <<<"$line"
	name="${parts[0]}"
	value="${parts[1]}"

	# Adding your suffix to each variable
	new_name="${name}_STAGING"

	# Adding each variable using GitHub CLI
	gh secret set "$new_name" -b"$value"

done <"$1"
