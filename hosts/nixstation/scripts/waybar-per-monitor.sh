#!/usr/bin/env bash
set -euo pipefail

# Kill any existing waybar instances
pkill waybar || true

# Wait a moment for waybar to fully terminate
sleep 1

# Launch waybar for each monitor with different configurations
# Each monitor gets its own specific config file with output field

# Launch for DP-1 (top monitor) - simple
waybar -c ~/.config/waybar/waybar-simple-dp1.json -s ~/.config/waybar/style.css &

# Launch for DP-2 (left vertical) - simple  
waybar -c ~/.config/waybar/waybar-simple-dp2.json -s ~/.config/waybar/style.css &

# Launch for DP-3 (main center) - full config
waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css &

# Launch for HDMI-A-1 (right vertical) - simple
waybar -c ~/.config/waybar/waybar-simple-hdmi.json -s ~/.config/waybar/style.css &
