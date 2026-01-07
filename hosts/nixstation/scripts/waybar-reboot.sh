#!/usr/bin/env bash
set -euo pipefail

# Simple GUI confirm using wofi (Wayland-native dmenu)
choice=$(printf "No\nYes" | wofi --dmenu --prompt "Reboot?" --insensitive)
if [[ "${choice:-}" == "Yes" ]]; then
  systemctl reboot
fi


