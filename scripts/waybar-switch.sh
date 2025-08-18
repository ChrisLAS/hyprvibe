#!/bin/bash

# Waybar Configuration Switcher
# This script allows switching between full and simple waybar configurations

CONFIG_DIR="/home/chrisf/.config/waybar"
FULL_CONFIG="$CONFIG_DIR/config"
SIMPLE_CONFIG="$CONFIG_DIR/simple-config"

case "${1:-help}" in
    "full")
        echo "Switching to full waybar configuration..."
        pkill waybar
        sleep 1
        waybar -c "$FULL_CONFIG" -s "$CONFIG_DIR/style.css" &
        echo "Full waybar started"
        ;;
    "simple")
        echo "Switching to simple waybar configuration..."
        pkill waybar
        sleep 1
        waybar -c "$SIMPLE_CONFIG" -s "$CONFIG_DIR/style.css" &
        echo "Simple waybar started"
        ;;
    "status")
        if pgrep waybar > /dev/null; then
            echo "Waybar is running"
            if [ -f "$FULL_CONFIG" ] && [ "$(readlink -f "$CONFIG_DIR/config")" = "$(readlink -f "$FULL_CONFIG")" ]; then
                echo "Current config: Full"
            else
                echo "Current config: Simple"
            fi
        else
            echo "Waybar is not running"
        fi
        ;;
    "help"|*)
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  full    - Switch to full waybar configuration (all modules)"
        echo "  simple  - Switch to simple waybar configuration (workspaces, window, clock only)"
        echo "  status  - Show current waybar status and configuration"
        echo "  help    - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 full    # Switch to full configuration"
        echo "  $0 simple  # Switch to simple configuration"
        ;;
esac
