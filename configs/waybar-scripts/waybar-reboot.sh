#!/usr/bin/env bash
set -euo pipefail

choice=$(printf "No\nYes" | vicinae dmenu -p "Reboot?")
if [[ "${choice:-}" == "Yes" ]]; then
  systemctl reboot
fi


