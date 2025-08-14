#!/usr/bin/env bash
set -euo pipefail

get_percent() {
  if ls /sys/class/backlight >/dev/null 2>&1 && [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then
    brightnessctl -m | awk -F, '{gsub("%","", $4); print $4}' 2>/dev/null || true
  elif command -v ddcutil >/dev/null 2>&1; then
    ddcutil getvcp 0x10 --terse 2>/dev/null | awk '{print $(NF-1)}' || true
  fi
}

adjust_kernel() {
  local arg="$1"
  brightnessctl set "$arg" >/dev/null 2>&1 || false
}

adjust_ddc() {
  local val="$1" # +5 or -5 or absolute 0-100
  # Iterate all detected I2C buses
  while read -r busdev; do
    [ -n "$busdev" ] || continue
    busnum="${busdev##*-}"
    ddcutil --bus "$busnum" setvcp 0x10 "$val" >/dev/null 2>&1 || true
  done < <(ddcutil detect --terse 2>/dev/null | awk '/I2C bus:/ {print $3}')
}

act() {
  case "$1" in
    "+5%")  adjust_kernel "+5%" || adjust_ddc "+5" ;;
    "-5%")  adjust_kernel "5%-" || adjust_ddc "-5" ;;
    "25%")  adjust_kernel "25%" || adjust_ddc "25" ;;
    "50%")  adjust_kernel "50%" || adjust_ddc "50" ;;
    "75%")  adjust_kernel "75%" || adjust_ddc "75" ;;
    "100%") adjust_kernel "100%" || adjust_ddc "100" ;;
  esac
}

current="$(get_percent || echo "?")"
choice=$(printf "%s\n" "+5%" "-5%" "25%" "50%" "75%" "100%" | rofi -dmenu -p "Brightness (${current}% )" -i)
[ -n "${choice:-}" ] && act "$choice"


