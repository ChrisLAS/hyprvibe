#!/bin/bash

# Monitor Setup Helper Script
# This script helps you configure monitors for different hosts

set -e

HOSTNAME=$(hostname)
CONFIG_DIR="/home/chrisf/.config/hypr"

echo "=== Monitor Setup Helper for $HOSTNAME ==="

# Function to detect monitors
detect_monitors() {
    echo "Detecting monitors..."
    hyprctl monitors
    echo ""
    echo "Monitor names and their current configuration:"
    hyprctl monitors | grep -E "(Monitor|resolution|refreshRate)" | sed 's/^/  /'
}

# Function to generate monitor configuration
generate_monitor_config() {
    local host=$1
    local config_file="$CONFIG_DIR/hyprland-monitors-$host.lua"
    
    echo "Generating monitor configuration for $host..."
    echo "-- Auto-generated monitor configuration for $host" > "$config_file"
    echo "-- Generated on $(date)" >> "$config_file"
    echo "" >> "$config_file"
    
    # Get monitor information
    hyprctl monitors | while IFS= read -r line; do
        if [[ $line =~ ^Monitor\ ([^:]+): ]]; then
            monitor_name="${BASH_REMATCH[1]}"
            echo "Found monitor: $monitor_name"
            echo "-- hl.monitor({ output = \"$monitor_name\", mode = \"resolution@refresh\", position = \"x,y\", scale = 1 })" >> "$config_file"
        fi
    done
    
    echo "" >> "$config_file"
    echo "-- Example configuration (uncomment and modify as needed):" >> "$config_file"
    echo '-- hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1 })' >> "$config_file"
    echo '-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "2560x0", scale = 1 })' >> "$config_file"
    echo '-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "5120x0", scale = 1 })' >> "$config_file"
    
    echo "Configuration written to $config_file"
    echo "Please edit this file with your actual monitor settings."
}

# Function to apply monitor configuration
apply_monitor_config() {
    local host=$1
    local config_file="$CONFIG_DIR/hyprland-monitors-$host.lua"
    
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Monitor configuration file not found: $config_file"
        exit 1
    fi
    
    echo "Applying monitor configuration from $config_file..."
    
    # Evaluate each active hl.monitor declaration.
    while IFS= read -r line; do
        if [[ $line =~ ^[[:space:]]*hl\.monitor\( ]]; then
            echo "Applying: $line"
            hyprctl eval "$line"
        fi
    done < "$config_file"
    
    echo "Monitor configuration applied!"
}

# Function to show current monitor status
show_status() {
    echo "Current monitor configuration:"
    hyprctl monitors
}

# Main script logic
case "${1:-help}" in
    "detect")
        detect_monitors
        ;;
    "generate")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 generate <hostname>"
            echo "Example: $0 generate nixstation"
            exit 1
        fi
        generate_monitor_config "$2"
        ;;
    "apply")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 apply <hostname>"
            echo "Example: $0 apply nixstation"
            exit 1
        fi
        apply_monitor_config "$2"
        ;;
    "status")
        show_status
        ;;
    "setup")
        if [[ -z "$2" ]]; then
            echo "Usage: $0 setup <hostname>"
            echo "Example: $0 setup nixstation"
            exit 1
        fi
        detect_monitors
        generate_monitor_config "$2"
        echo ""
        echo "Next steps:"
        echo "1. Edit $CONFIG_DIR/hyprland-monitors-$2.lua with your monitor settings"
        echo "2. Run: $0 apply $2"
        ;;
    "help"|*)
        echo "Usage: $0 <command> [hostname]"
        echo ""
        echo "Commands:"
        echo "  detect                    - Detect and display current monitors"
        echo "  generate <hostname>       - Generate monitor config template for host"
        echo "  apply <hostname>          - Apply monitor config for host"
        echo "  status                    - Show current monitor status"
        echo "  setup <hostname>          - Full setup process for host"
        echo "  help                      - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 setup nixstation       # Full setup for nixstation"
        echo "  $0 setup rvbee            # Full setup for rvbee"
        echo "  $0 detect                 # Just detect monitors"
        echo "  $0 apply nixstation       # Apply existing config"
        ;;
esac
