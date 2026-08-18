#!/usr/bin/env bash
set -euo pipefail

wait_for_vicinae() {
  for _ in $(seq 1 100); do
    if timeout 2s vicinae ping >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done
  return 1
}

if ! timeout 2s vicinae ping >/dev/null 2>&1; then
  if ! systemctl --user restart vicinae.service >/dev/null 2>&1; then
    vicinae server --replace >/dev/null 2>&1 &
  fi
  wait_for_vicinae || true
fi

exec vicinae "$@"
