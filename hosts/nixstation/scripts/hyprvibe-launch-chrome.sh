#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  set -- about:blank
fi

exec /run/current-system/sw/bin/flatpak run com.google.Chrome "$@"
