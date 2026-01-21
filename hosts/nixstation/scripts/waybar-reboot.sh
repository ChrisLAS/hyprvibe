#!/usr/bin/env bash
set -euo pipefail

# Simple GUI confirm using rofi (already installed)
choice=$(printf "No\nYes" | rofi -dmenu -p "Reboot?" -i)
if [[ "${choice:-}" == "Yes" ]]; then
  systemctl reboot
fi


