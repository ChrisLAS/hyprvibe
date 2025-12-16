#!/usr/bin/env bash
# WiFi management script for waybar using rofi and nmcli

# Check if NetworkManager is available
if ! command -v nmcli &> /dev/null; then
    notify-send "WiFi Manager" "NetworkManager (nmcli) is not available"
    exit 1
fi

# Get WiFi device name
WIFI_DEVICE=$(nmcli -t -f DEVICE,TYPE device | grep -E ':wifi$' | cut -d: -f1 | head -n1)

if [ -z "$WIFI_DEVICE" ]; then
    notify-send "WiFi Manager" "No WiFi device found"
    exit 1
fi

# Check if WiFi is enabled
WIFI_ENABLED=$(nmcli radio wifi)
if [ "$WIFI_ENABLED" != "enabled" ]; then
    # Ask to enable WiFi
    if rofi -dmenu -p "WiFi is disabled. Enable?" -lines 2 -width 300 <<< "Yes\nNo" | grep -q "Yes"; then
        nmcli radio wifi on
        sleep 2
    else
        exit 0
    fi
fi

# Function to scan and show networks
show_wifi_networks() {
    # Scan for networks
    nmcli device wifi rescan 2>/dev/null
    sleep 2
    
    # Get list of networks - store raw colon-separated data for accurate SSID extraction
    RAW_NETWORKS=$(nmcli -t -f SSID,SIGNAL,SECURITY device wifi list | sort -t: -k2 -rn)
    
    # Format for display (colon-separated input, space-formatted output)
    NETWORKS=$(echo "$RAW_NETWORKS" | \
        awk -F: '{printf "%-30s %3s%% %s\n", $1, $2, $3}')
    
    if [ -z "$NETWORKS" ]; then
        notify-send "WiFi Manager" "No networks found. Try scanning again."
        exit 1
    fi
    
    # Show in rofi
    SELECTED=$(echo "$NETWORKS" | rofi -dmenu -p "Select WiFi Network" -lines 10 -width 500 -i)
    
    if [ -z "$SELECTED" ]; then
        exit 0
    fi
    
    # Extract signal strength from selected line (more reliable than SSID for matching)
    SELECTED_SIGNAL=$(echo "$SELECTED" | awk '{print $2}' | sed 's/%//')
    
    # Find matching network in raw data using signal strength (handles SSIDs with spaces)
    SSID=$(echo "$RAW_NETWORKS" | awk -F: -v sig="$SELECTED_SIGNAL" '$2 == sig {print $1; exit}')
    
    # Fallback: extract SSID directly if signal match fails (works for most SSIDs)
    if [ -z "$SSID" ] || [ "$SSID" = "" ]; then
        SSID=$(echo "$SELECTED" | awk '{for(i=1;i<NF-1;i++) printf "%s ", $i; print ""}' | sed 's/[[:space:]]*$//')
        # Remove trailing spaces
        SSID=$(echo "$SSID" | xargs)
    fi
    
    # Check if already connected
    CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes:' | cut -d: -f2)
    if [ "$CURRENT_SSID" = "$SSID" ]; then
        notify-send "WiFi Manager" "Already connected to $SSID"
        exit 0
    fi
    
    # Check if network requires password (colon-separated format)
    SECURITY=$(echo "$RAW_NETWORKS" | awk -F: -v ssid="$SSID" '$1 == ssid {print $3; exit}')
    
    if [ "$SECURITY" != "--" ] && [ -n "$SECURITY" ]; then
        # Check if this is a saved/known network first
        if nmcli -t -f NAME connection show | grep -q "^$SSID$"; then
            # Try connecting to saved network first (may prompt for password if needed)
            if nmcli connection up "$SSID" 2>&1; then
                notify-send "WiFi Manager" "Connected to $SSID"
            else
                # Saved connection failed, try with password prompt
                PASSWORD=$(rofi -dmenu -password -p "Password for $SSID:" -width 400)
                if [ -z "$PASSWORD" ]; then
                    exit 0
                fi
                nmcli device wifi connect "$SSID" password "$PASSWORD" 2>&1 | \
                    notify-send "WiFi Manager" "$(cat)"
            fi
        else
            # New network, ask for password
            PASSWORD=$(rofi -dmenu -password -p "Password for $SSID:" -width 400)
            if [ -z "$PASSWORD" ]; then
                exit 0
            fi
            # Connect with password
            CONNECT_OUTPUT=$(nmcli device wifi connect "$SSID" password "$PASSWORD" 2>&1)
            if [ $? -eq 0 ]; then
                notify-send "WiFi Manager" "Connected to $SSID" -t 3000
            else
                notify-send "WiFi Manager" "Failed to connect: $CONNECT_OUTPUT" -t 5000
            fi
        fi
    else
        # Open network, connect without password
        CONNECT_OUTPUT=$(nmcli device wifi connect "$SSID" 2>&1)
        if [ $? -eq 0 ]; then
            notify-send "WiFi Manager" "Connected to $SSID" -t 3000
        else
            notify-send "WiFi Manager" "Failed to connect: $CONNECT_OUTPUT" -t 5000
        fi
    fi
}

# Function to show current connection and options
show_wifi_menu() {
    CURRENT=$(nmcli -t -f active,ssid dev wifi | grep '^yes:' | cut -d: -f2)
    if [ -z "$CURRENT" ]; then
        CURRENT="Not connected"
    fi
    
    MENU_OPTIONS="Connect to Network\nDisconnect\nToggle WiFi"
    if [ "$CURRENT" != "Not connected" ]; then
        MENU_OPTIONS="Current: $CURRENT\n$MENU_OPTIONS"
    fi
    
    SELECTED=$(echo -e "$MENU_OPTIONS" | rofi -dmenu -p "WiFi Manager" -lines 5 -width 300)
    
    case "$SELECTED" in
        "Connect to Network")
            show_wifi_networks
            ;;
        "Disconnect")
            nmcli device disconnect "$WIFI_DEVICE" 2>&1 | \
                notify-send "WiFi Manager" "$(cat)"
            ;;
        "Toggle WiFi")
            if [ "$WIFI_ENABLED" = "enabled" ]; then
                nmcli radio wifi off
                notify-send "WiFi Manager" "WiFi disabled"
            else
                nmcli radio wifi on
                notify-send "WiFi Manager" "WiFi enabled"
            fi
            ;;
    esac
}

# Main execution
show_wifi_menu
