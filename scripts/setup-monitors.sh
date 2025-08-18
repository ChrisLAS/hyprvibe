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
    local config_file="$CONFIG_DIR/hyprland-monitors-$host.conf"
    
    echo "Generating monitor configuration for $host..."
    echo "# Auto-generated monitor configuration for $host" > "$config_file"
    echo "# Generated on $(date)" >> "$config_file"
    echo "" >> "$config_file"
    
    # Get monitor information
    hyprctl monitors | while IFS= read -r line; do
        if [[ $line =~ ^Monitor\ ([^:]+): ]]; then
            monitor_name="${BASH_REMATCH[1]}"
            echo "Found monitor: $monitor_name"
            echo "# monitor=$monitor_name,resolution@refresh,x,y,scale" >> "$config_file"
        fi
    done
    
    echo "" >> "$config_file"
    echo "# Example configuration (uncomment and modify as needed):" >> "$config_file"
    echo "# monitor=DP-1,2560x1440@144,0x0,1" >> "$config_file"
    echo "# monitor=DP-2,2560x1440@144,2560x0,1" >> "$config_file"
    echo "# monitor=HDMI-A-1,1920x1080@60,5120x0,1" >> "$config_file"
    echo "# monitor=HDMI-A-2,1920x1080@60,5120x1080,1" >> "$config_file"
    
    echo "Configuration written to $config_file"
    echo "Please edit this file with your actual monitor settings."
}

# Function to apply monitor configuration
apply_monitor_config() {
    local host=$1
    local config_file="$CONFIG_DIR/hyprland-monitors-$host.conf"
    
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Monitor configuration file not found: $config_file"
        exit 1
    fi
    
    echo "Applying monitor configuration from $config_file..."
    
    # Extract monitor lines and apply them
    grep "^monitor=" "$config_file" | while read -r line; do
        if [[ $line =~ ^monitor=([^,]+),([^,]+),([^,]+),([^,]+)$ ]]; then
            monitor="${BASH_REMATCH[1]}"
            resolution="${BASH_REMATCH[2]}"
            position="${BASH_REMATCH[3]}"
            scale="${BASH_REMATCH[4]}"
            
            echo "Applying: $monitor -> $resolution at $position with scale $scale"
            hyprctl keyword monitor "$monitor,$resolution,$position,$scale"
        fi
    done
    
    echo "Monitor configuration applied!"
}

# Function to show current monitor status
show_status() {
    echo "Current monitor configuration:"
    hyprctl monitors
    echo ""
    echo "Current monitor keywords:"
    hyprctl getoption monitor | grep -v "Option" | sed 's/^/  /'
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
        echo "1. Edit $CONFIG_DIR/hyprland-monitors-$2.conf with your monitor settings"
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
