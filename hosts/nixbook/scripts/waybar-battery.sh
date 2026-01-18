#!/usr/bin/env bash
set -euo pipefail

# Custom battery module for waybar showing charge/discharge rate
# Reads from /sys/class/power_supply/BAT0

format_output() {
  local text tooltip
  text="$1"
  tooltip="$2"
  echo "{\"text\": \"${text}\", \"tooltip\": \"${tooltip}\"}"
}

# Find battery device
BATTERY=""
for bat in /sys/class/power_supply/BAT*; do
  if [[ -d "$bat" ]]; then
    BATTERY="$bat"
    break
  fi
done

if [[ -z "$BATTERY" ]]; then
  format_output "🔋 N/A" "Battery not found"
  exit 0
fi

# Read battery information
status=""
capacity=""
current_ua=""
voltage_uv=""
power_w=""

if [[ -r "${BATTERY}/status" ]]; then
  status=$(cat "${BATTERY}/status" 2>/dev/null || echo "Unknown")
fi

if [[ -r "${BATTERY}/capacity" ]]; then
  capacity=$(cat "${BATTERY}/capacity" 2>/dev/null || echo "0")
fi

# Try to get power directly, or calculate from current and voltage
if [[ -r "${BATTERY}/power_now" ]]; then
  power_raw=$(cat "${BATTERY}/power_now" 2>/dev/null || echo "0")
  power_w=$(awk -v v="${power_raw}" 'BEGIN{ printf "%.1f", v/1000000 }')
elif [[ -r "${BATTERY}/current_now" && -r "${BATTERY}/voltage_now" ]]; then
  current_raw=$(cat "${BATTERY}/current_now" 2>/dev/null || echo "0")
  voltage_raw=$(cat "${BATTERY}/voltage_now" 2>/dev/null || echo "0")
  # Calculate power: (current in uA * voltage in uV) / 1e12 = watts
  power_w=$(awk -v c="${current_raw}" -v v="${voltage_raw}" 'BEGIN{ printf "%.1f", (c * v) / 1000000000000 }')
fi

# Format output based on status
icon="🔋"
case "$status" in
  Charging)
    icon="⚡"
    if [[ -n "$power_w" && "$power_w" != "0.0" ]]; then
      text="${icon} ${capacity}% (+${power_w}W)"
      tooltip="Battery: ${capacity}%\nStatus: Charging\nRate: +${power_w}W"
    else
      text="${icon} ${capacity}%"
      tooltip="Battery: ${capacity}%\nStatus: Charging"
    fi
    ;;
  Discharging)
    icon="🔋"
    if [[ -n "$power_w" && "$power_w" != "0.0" ]]; then
      text="${icon} ${capacity}% (-${power_w}W)"
      tooltip="Battery: ${capacity}%\nStatus: Discharging\nRate: -${power_w}W"
    else
      text="${icon} ${capacity}%"
      tooltip="Battery: ${capacity}%\nStatus: Discharging"
    fi
    ;;
  Full)
    icon="🔌"
    text="${icon} ${capacity}%"
    tooltip="Battery: ${capacity}%\nStatus: ${status}"
    ;;
  "Not charging")
    icon="🔌"
    text="${icon} ${capacity}%"
    tooltip="Battery: ${capacity}%\nStatus: ${status}"
    ;;
  *)
    icon="🔋"
    text="${icon} ${capacity}%"
    tooltip="Battery: ${capacity}%\nStatus: ${status}"
    ;;
esac

format_output "$text" "$tooltip"
