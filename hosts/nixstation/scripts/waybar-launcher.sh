#!/usr/bin/env bash
set -euo pipefail

# Kill any existing waybar instances
pkill waybar || true

# Get the monitor name from the environment variable
MONITOR="${WAYBAR_OUTPUT_NAME:-}"

# Main monitor (DP-3) gets the full configuration
if [[ "$MONITOR" == "DP-3" ]]; then
    waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css &
else
    # All other monitors get the simple configuration
    waybar -c ~/.config/waybar/waybar-simple.json -s ~/.config/waybar/style.css &
fi
