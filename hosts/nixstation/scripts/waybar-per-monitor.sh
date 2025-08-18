#!/usr/bin/env bash
set -euo pipefail

# Kill any existing waybar instances
pkill waybar || true

# Wait a moment for waybar to fully terminate
sleep 1

# Launch waybar for each monitor with different configurations
# Main monitor (DP-3) gets full config, others get simple config

# Launch for DP-1 (top monitor) - simple
WAYBAR_OUTPUT_NAME="DP-1" waybar -c ~/.config/waybar/waybar-simple.json -s ~/.config/waybar/style.css &

# Launch for DP-2 (left vertical) - simple  
WAYBAR_OUTPUT_NAME="DP-2" waybar -c ~/.config/waybar/waybar-simple.json -s ~/.config/waybar/style.css &

# Launch for DP-3 (main center) - full config
WAYBAR_OUTPUT_NAME="DP-3" waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css &

# Launch for HDMI-A-1 (right vertical) - simple
WAYBAR_OUTPUT_NAME="HDMI-A-1" waybar -c ~/.config/waybar/waybar-simple.json -s ~/.config/waybar/style.css &
