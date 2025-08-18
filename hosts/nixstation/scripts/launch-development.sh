#!/usr/bin/env bash
set -euo pipefail

# Launch development tools on left vertical monitor (DP-2)
# Cursor editor on top half, terminal on bottom half

# Focus the left vertical monitor
hyprctl dispatch focusmonitor DP-2

# Launch Cursor editor and position it on top half
cursor &
sleep 2
hyprctl dispatch movewindow exact 0 0
hyprctl dispatch resizeactive exact 1440 1280

# Launch terminal and position it on bottom half
kitty &
sleep 2
hyprctl dispatch movewindow exact 0 1280
hyprctl dispatch resizeactive exact 1440 1280

# Focus back to the main monitor (DP-3)
hyprctl dispatch focusmonitor DP-3
