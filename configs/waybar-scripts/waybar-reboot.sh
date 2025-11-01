#!/usr/bin/env bash
set -euo pipefail

choice=$(printf "No\nYes" | rofi -dmenu -p "Reboot?" -i)
if [[ "${choice:-}" == "Yes" ]]; then
  systemctl reboot
fi


