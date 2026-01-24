#!/usr/bin/env bash
set -euo pipefail

# Simple GUI confirm using vicinae (dmenu mode)
choice=$(printf "No\nYes" | vicinae dmenu -p "Reboot?")
if [[ "${choice:-}" == "Yes" ]]; then
  systemctl reboot
fi


