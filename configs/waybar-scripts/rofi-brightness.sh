#!/usr/bin/env bash
set -euo pipefail

get_percent() {
  if ls /sys/class/backlight >/dev/null 2>&1 && [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then
    brightnessctl -m | awk -F, '{gsub("%","", $4); print $4}' 2>/dev/null || true
  elif command -v ddcutil >/dev/null 2>&1; then
    ddcutil getvcp 0x10 --terse 2>/dev/null | awk '{print $(NF-1)}' || true
  fi
}

has_kernel_backlight() {
  ls /sys/class/backlight >/dev/null 2>&1 && [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]
}

adjust_kernel() { brightnessctl set "$1" >/dev/null 2>&1 || false; }

adjust_ddc() {
  local req="$1"; local ok=0
  while read -r busdev; do
    [ -n "$busdev" ] || continue
    busnum="${busdev##*-}"
    read -r cur max < <(ddcutil --bus "$busnum" getvcp 0x10 --terse 2>/dev/null | awk '{print $(NF-1), $NF}')
    cur=${cur:-0}; max=${max:-100}
    local target
    if [[ "$req" =~ ^[+-] ]]; then target=$(( cur + ${req} )); else target=$req; fi
    if [ "$target" -lt 0 ]; then target=0; fi
    if [ "$target" -gt "$max" ]; then target=$max; fi
    if ddcutil --bus "$busnum" setvcp 0x10 "$target" >/dev/null 2>&1; then ok=1; fi
  done < <(ddcutil detect --terse 2>/dev/null | awk '/I2C bus:/ {print $3}')
  [ $ok -eq 1 ]
}

current="$(get_percent || echo "?")"
if ! command -v vicinae >/dev/null 2>&1; then
  command -v notify-send >/dev/null 2>&1 && notify-send "Brightness" "vicinae not found"
  exit 1
fi

choice=$(printf "%s\n" "+5%" "-5%" "25%" "50%" "75%" "100%" | vicinae dmenu -p "Brightness (${current}% )")
if [ -n "${choice:-}" ]; then
  if has_kernel_backlight; then adjust_kernel "$choice"; else adjust_ddc "${choice%%%}"; fi
  newp=$(get_percent || echo "?")
  command -v notify-send >/dev/null 2>&1 && notify-send "Brightness" "Set to: $choice (now ${newp}%)"
else
  command -v notify-send >/dev/null 2>&1 && notify-send "Brightness" "Cancelled"
fi


