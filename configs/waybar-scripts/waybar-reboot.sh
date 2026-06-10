#!/usr/bin/env bash
set -euo pipefail

VICINAE_BIN="${HOME}/.local/bin/vicinae-safe"
if [ -x "$VICINAE_BIN" ]; then
  choice=$(printf "No\nYes" | "$VICINAE_BIN" dmenu -p "Reboot?")
else
  choice=$(printf "No\nYes" | vicinae dmenu -p "Reboot?")
fi
if [[ "${choice:-}" == "Yes" ]]; then
  systemctl reboot
fi

