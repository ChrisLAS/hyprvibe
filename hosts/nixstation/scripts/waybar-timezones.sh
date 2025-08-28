#!/usr/bin/env bash

# Simple timezone display script for Waybar
# This script outputs just timezone information (no clock display)

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

# Create tooltip content
tooltip="Time Zones:
Pacific (${pacific_tz}): ${pacific_time}
Central (${central_tz}): ${central_time}
Eastern (${eastern_tz}): ${eastern_time}
London (${london_tz}): ${london_time}
UTC: ${utc_time}"

# Use jq to properly format JSON
jq -n -c \
  --arg text "TZ" \
  --arg tooltip "$tooltip" \
  '{"text": $text, "tooltip": $tooltip}'
