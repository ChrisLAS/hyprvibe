#!/usr/bin/env bash
set -euo pipefail

# Kill any existing waybar instances
pkill waybar || true

# Wait a moment for waybar to fully terminate
sleep 1

# Launch waybar for each monitor with different configurations
# Main monitor (DP-3) gets full config, others get simple config
# Use -b flag to bind each instance to its specific monitor

# Launch for DP-1 (top monitor) - simple
waybar -c ~/.config/waybar/waybar-simple.json -s ~/.config/waybar/style.css -b DP-1 &

# Launch for DP-2 (left vertical) - simple  
waybar -c ~/.config/waybar/waybar-simple.json -s ~/.config/waybar/style.css -b DP-2 &

# Launch for DP-3 (main center) - full config
waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css -b DP-3 &

# Launch for HDMI-A-1 (right vertical) - simple
waybar -c ~/.config/waybar/waybar-simple.json -s ~/.config/waybar/style.css -b HDMI-A-1 &
