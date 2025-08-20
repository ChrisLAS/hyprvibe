#!/usr/bin/env bash

# Logitech Bluetooth Mouse Management Script
# This script helps manage Logitech mouse Bluetooth connections

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logitech MX Vertical MAC address (update this with your mouse's MAC)
MOUSE_MAC="C5:7D:FD:5F:EB:DC"

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Bluetooth is enabled
check_bluetooth() {
    if ! systemctl is-active --quiet bluetooth; then
        error "Bluetooth service is not running"
        return 1
    fi
    success "Bluetooth service is running"
}

# Check mouse connection status
check_mouse_status() {
    log "Checking mouse connection status..."
    
    # Check if mouse is connected via Bluetooth
    if bluetoothctl info "$MOUSE_MAC" | grep -q "Connected: yes"; then
        success "Mouse is connected via Bluetooth"
        return 0
    else
        warning "Mouse is not connected via Bluetooth"
        return 1
    fi
}

# Connect mouse via Bluetooth
connect_mouse() {
    log "Attempting to connect mouse via Bluetooth..."
    
    # Check if mouse is trusted
    if ! bluetoothctl info "$MOUSE_MAC" | grep -q "Trusted: yes"; then
        warning "Mouse is not trusted. Please pair it first."
        return 1
    fi
    
    # Try to connect
    if bluetoothctl connect "$MOUSE_MAC"; then
        success "Mouse connected successfully"
        return 0
    else
        error "Failed to connect mouse"
        return 1
    fi
}

# Disconnect mouse from Bluetooth
disconnect_mouse() {
    log "Disconnecting mouse from Bluetooth..."
    
    if bluetoothctl disconnect "$MOUSE_MAC"; then
        success "Mouse disconnected successfully"
        return 0
    else
        error "Failed to disconnect mouse"
        return 1
    fi
}

# Show mouse battery level (if supported)
show_battery() {
    log "Checking mouse battery level..."
    
    # Try to get battery level via bluetoothctl
    if bluetoothctl info "$MOUSE_MAC" | grep -q "Battery"; then
        bluetoothctl info "$MOUSE_MAC" | grep "Battery"
    else
        warning "Battery information not available"
    fi
}

# Show available Logitech devices
list_devices() {
    log "Available Logitech devices:"
    bluetoothctl devices | grep -i logitech || warning "No Logitech devices found"
}

# Main function
main() {
    case "${1:-help}" in
        "status")
            check_bluetooth
            check_mouse_status
            ;;
        "connect")
            check_bluetooth
            connect_mouse
            ;;
        "disconnect")
            check_bluetooth
            disconnect_mouse
            ;;
        "battery")
            check_bluetooth
            show_battery
            ;;
        "list")
            list_devices
            ;;
        "help"|*)
            echo "Usage: $0 {status|connect|disconnect|battery|list|help}"
            echo ""
            echo "Commands:"
            echo "  status     - Check Bluetooth and mouse connection status"
            echo "  connect    - Connect mouse via Bluetooth"
            echo "  disconnect - Disconnect mouse from Bluetooth"
            echo "  battery    - Show mouse battery level"
            echo "  list       - List available Logitech devices"
            echo "  help       - Show this help message"
            echo ""
            echo "Note: Update MOUSE_MAC variable in this script with your mouse's MAC address"
            ;;
    esac
}

main "$@"
