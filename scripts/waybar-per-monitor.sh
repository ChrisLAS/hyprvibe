#!/usr/bin/env bash

# Per-Monitor Waybar Launcher
# This script launches different waybar configurations for different monitors

CONFIG_DIR="/home/chrisf/.config/waybar"
FULL_CONFIG="$CONFIG_DIR/config"
SIMPLE_CONFIG="$CONFIG_DIR/simple-config"
STYLE_FILE="$CONFIG_DIR/style.css"

# Function to launch waybar for a specific monitor
launch_waybar_for_monitor() {
    local monitor=$1
    local config=$2
    
    echo "Launching waybar for monitor $monitor with config $config"
    
    # Launch waybar with specific output
    waybar -c "$config" -s "$STYLE_FILE" -o "$monitor" &
}

# Kill existing waybar instances
pkill waybar
sleep 1

# Launch waybar for each monitor with appropriate configuration
# Main monitor (DP-3) gets full waybar
launch_waybar_for_monitor "DP-3" "$FULL_CONFIG"

# Other monitors get simple waybar
launch_waybar_for_monitor "DP-1" "$SIMPLE_CONFIG"
launch_waybar_for_monitor "DP-2" "$SIMPLE_CONFIG"
launch_waybar_for_monitor "HDMI-A-1" "$SIMPLE_CONFIG"

echo "Per-monitor waybar launched successfully"
