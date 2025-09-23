#!/usr/bin/env bash
set -euo pipefail

# Launch Slack and Telegram on right vertical monitor (HDMI-A-1)
# Slack on top half, Telegram on bottom half

# Focus the right vertical monitor (HDMI-A-1)
hyprctl dispatch focusmonitor HDMI-A-1

# Launch Slack first
flatpak run com.slack.Slack &
sleep 2

# Wait for Slack to start, then launch Telegram
flatpak run org.telegram.desktop &
