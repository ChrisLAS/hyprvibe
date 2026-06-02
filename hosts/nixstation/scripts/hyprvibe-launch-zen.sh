#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  set -- about:blank
fi

exec flatpak run app.zen_browser.zen "$@"
