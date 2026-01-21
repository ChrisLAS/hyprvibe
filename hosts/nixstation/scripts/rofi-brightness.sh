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

adjust_kernel() {
  local arg="$1"
  brightnessctl set "$arg" >/dev/null 2>&1 || false
}

adjust_ddc() {
  local req="$1" # "+5" "-5" or absolute 0-100
  local ok=0
  # Determine absolute target per display and set
  while read -r busdev; do
    [ -n "$busdev" ] || continue
    busnum="${busdev##*-}"
    # Read current and max
    read -r cur max < <(ddcutil --bus "$busnum" getvcp 0x10 --terse 2>/dev/null | awk '{print $(NF-1), $NF}')
    # Fallback if parsing fails
    cur=${cur:-0}; max=${max:-100}
    # Compute new absolute value
    local target
    if [[ "$req" =~ ^[+-] ]]; then
      local delta=${req}
      # Strip sign for arithmetic, then reapply
      target=$(( cur + delta ))
    else
      target=$req
    fi
    # Clamp 0..max
    if [ "$target" -lt 0 ]; then target=0; fi
    if [ "$target" -gt "$max" ]; then target=$max; fi
    if ddcutil --bus "$busnum" setvcp 0x10 "$target" >/dev/null 2>&1; then
      ok=1
    fi
  done < <(ddcutil detect --terse 2>/dev/null | awk '/I2C bus:/ {print $3}')
  [ $ok -eq 1 ]
}

act() {
  case "$1" in
    "+5%")  if has_kernel_backlight; then adjust_kernel "+5%"; else adjust_ddc "+5"; fi ;;
    "-5%")  if has_kernel_backlight; then adjust_kernel "5%-"; else adjust_ddc "-5"; fi ;;
    "25%")  if has_kernel_backlight; then adjust_kernel "25%"; else adjust_ddc "25"; fi ;;
    "50%")  if has_kernel_backlight; then adjust_kernel "50%"; else adjust_ddc "50"; fi ;;
    "75%")  if has_kernel_backlight; then adjust_kernel "75%"; else adjust_ddc "75"; fi ;;
    "100%") if has_kernel_backlight; then adjust_kernel "100%"; else adjust_ddc "100"; fi ;;
  esac
}

current="$(get_percent || echo "?")"
if ! command -v rofi >/dev/null 2>&1; then
  command -v notify-send >/dev/null 2>&1 && notify-send "Brightness" "rofi not found"
  exit 1
fi

choice=$(printf "%s\n" "+5%" "-5%" "25%" "50%" "75%" "100%" | rofi -dmenu -p "Brightness (${current}% )" -i)
if [ -n "${choice:-}" ]; then
  if act "$choice"; then
    newp=$(get_percent || echo "?")
    command -v notify-send >/dev/null 2>&1 && notify-send "Brightness" "Set to: $choice (now ${newp}%)"
  else
    command -v notify-send >/dev/null 2>&1 && notify-send "Brightness" "Adjustment failed"
    exit 1
  fi
else
  command -v notify-send >/dev/null 2>&1 && notify-send "Brightness" "Cancelled"
fi


