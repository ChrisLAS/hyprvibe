#!/usr/bin/env bash
set -euo pipefail

# Rofi menu for power profile switching
# Similar to rofi-brightness.sh but for power profiles

get_current_profile() {
  if command -v powerprofilesctl >/dev/null 2>&1; then
    powerprofilesctl get 2>/dev/null || echo "unknown"
  else
    # Fallback: check CPU governor
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown"
  fi
}

get_battery_status() {
  if command -v upower >/dev/null 2>&1; then
    BATTERY=$(upower -e | grep -i battery | head -1)
    if [ -n "$BATTERY" ]; then
      upower -i "$BATTERY" | grep -E 'state|percentage' | head -2 | \
        awk -F: '{print $2}' | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
    fi
  elif [ -f /sys/class/power_supply/BAT0/status ]; then
    STATUS=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "unknown")
    CAPACITY=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "?")
    echo "$STATUS $CAPACITY%"
  else
    echo "AC power"
  fi
}

current="$(get_current_profile)"
battery_info="$(get_battery_status)"

if ! command -v rofi >/dev/null 2>&1; then
  command -v notify-send >/dev/null 2>&1 && notify-send "Power Profile" "rofi not found"
  exit 1
fi

# Show menu with current status
choice=$(printf "%s\n%s\n%s\n%s" \
  "Performance" \
  "Balanced" \
  "Power Saver" \
  "Status" | \
  rofi -dmenu -p "Power Profile (Current: ${current})" -i -lines 4)

if [ -z "${choice:-}" ]; then
  command -v notify-send >/dev/null 2>&1 && notify-send "Power Profile" "Cancelled"
  exit 0
fi

case "$choice" in
  "Performance")
    power-profile performance
    ;;
  "Balanced")
    power-profile balanced
    ;;
  "Power Saver")
    power-profile power-saver
    ;;
  "Status")
    # Show detailed status
    status_msg="Profile: $(power-profile status)"
    command -v notify-send >/dev/null 2>&1 && \
      notify-send "Power Profile Status" "$status_msg\nBattery: $battery_info" -t 5000
    echo "$status_msg"
    ;;
  *)
    command -v notify-send >/dev/null 2>&1 && notify-send "Power Profile" "Unknown choice: $choice"
    exit 1
    ;;
esac
