#!/usr/bin/env bash
set -euo pipefail

# Launch Slack and Telegram on right vertical monitor (HDMI-A-1)
# Slack on top half, Telegram on bottom half

# Focus the right vertical monitor
hyprctl dispatch focusmonitor HDMI-A-1

# Launch Slack and position it on top half
slack &
sleep 2
# Move to HDMI-A-1 monitor first, then position
hyprctl dispatch movewindow mon:HDMI-A-1
hyprctl dispatch movewindow exact 4000 0
hyprctl dispatch resizeactive exact 1440 1280

# Launch Telegram and position it on bottom half
Telegram &
sleep 2
# Move to HDMI-A-1 monitor first, then position
hyprctl dispatch movewindow mon:HDMI-A-1
hyprctl dispatch movewindow exact 4000 1280
hyprctl dispatch resizeactive exact 1440 1280

# Focus back to the main monitor (DP-3)
hyprctl dispatch focusmonitor DP-3
