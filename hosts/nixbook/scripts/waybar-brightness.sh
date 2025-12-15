#!/usr/bin/env bash
set -euo pipefail

adjust() {
  local direction amount
  direction="$1"
  amount="$2"
  if ls /sys/class/backlight >/dev/null 2>&1 && [[ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]]; then
    if [[ "$direction" == "up" ]]; then
      brightnessctl set "+${amount}%" >/dev/null 2>&1 || true
    else
      brightnessctl set "${amount}%-" >/dev/null 2>&1 || true
    fi
  elif command -v ddcutil >/dev/null 2>&1; then
    # DDC/CI: iterate displays and setvcp 10
    # amount 5 or 10; we apply relative +/-
    local rel
    if [[ "$direction" == "up" ]]; then rel="+${amount}"; else rel="-${amount}"; fi
    while read -r busdev; do
      # Extract numeric bus id from device path like /dev/i2c-7
      busnum="${busdev##*-}"
      ddcutil --bus "$busnum" setvcp 10 "${rel}" >/dev/null 2>&1 || true
    done < <(ddcutil detect --terse 2>/dev/null | awk '/I2C bus:/ {print $3}')
  fi
}

if [[ "${1:-}" == "--up" && -n "${2:-}" ]]; then
  adjust up "$2"
elif [[ "${1:-}" == "--down" && -n "${2:-}" ]]; then
  adjust down "$2"
fi

# Prefer kernel backlight via brightnessctl; fallback to DDC/CI via ddcutil
percent=""
if ls /sys/class/backlight >/dev/null 2>&1 && [[ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]]; then
  percent=$(brightnessctl -m | awk -F, '{gsub("%","", $4); print $4}' 2>/dev/null || true)
fi
if [[ -z "${percent}" ]]; then
  if command -v ddcutil >/dev/null 2>&1; then
    # Query first active display's current brightness using terse output: "VCP 10 C <current> <max>"
    percent=$(ddcutil getvcp 10 --terse 2>/dev/null | awk '{print $(NF-1)}' || true)
  fi
fi
if [[ -z "${percent}" ]]; then percent="?"; fi

icon="🌞"
if [[ "$percent" != "?" ]]; then
  if (( percent < 20 )); then icon="🌑"; elif (( percent < 50 )); then icon="🌓"; elif (( percent < 80 )); then icon="🌔"; else icon="🌕"; fi
fi

echo "{\"text\": \"$icon ${percent}%\", \"tooltip\": \"Brightness: ${percent}%\"}"

