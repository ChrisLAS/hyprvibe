#!/usr/bin/env bash

# Custom Waybar clock module with multi-timezone tooltip
# This script outputs JSON with both text and tooltip

# Get current time in local timezone
current_time=$(date '+%I:%M %p')
current_date=$(date '+%Y-%m-%d')

# Get current time in local timezone
current_time=$(date '+%I:%M %p')

# Get times in different timezones
pacific_time=$(TZ='America/Los_Angeles' date '+%I:%M %p')
central_time=$(TZ='America/Chicago' date '+%I:%M %p')
eastern_time=$(TZ='America/New_York' date '+%I:%M %p')
london_time=$(TZ='Europe/London' date '+%I:%M %p')
utc_time=$(TZ='UTC' date '+%I:%M %p')

# Get timezone abbreviations
pacific_tz=$(TZ='America/Los_Angeles' date '+%Z')
central_tz=$(TZ='America/Chicago' date '+%Z')
eastern_tz=$(TZ='America/New_York' date '+%Z')
london_tz=$(TZ='Europe/London' date '+%Z')

# Get current date and day of week
current_date=$(date '+%Y-%m-%d')
day_of_week=$(date '+%A')
current_time_24=$(date '+%H:%M:%S')

# Generate calendar (simple version)
calendar=$(cal | sed 's/^/  /')

# Create tooltip content with proper escaping (simplified HTML)
tooltip="${day_of_week}, ${current_date} | ${current_time_24}

Time Zones:
🌅 Pacific (${pacific_tz}): ${pacific_time}
🌆 Central (${central_tz}): ${central_time}
🌃 Eastern (${eastern_tz}): ${eastern_time}
🌍 London (${london_tz}): ${london_time}
🌐 UTC: ${utc_time}

Calendar:
${calendar}"

# Escape the tooltip content for JSON (preserve formatting with \n)
escaped_tooltip=$(echo "$tooltip" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\n/\\n/g')

# Output JSON for Waybar
echo "{\"text\": \"󰅐 ${current_time}\", \"tooltip\": \"${escaped_tooltip}\"}"
