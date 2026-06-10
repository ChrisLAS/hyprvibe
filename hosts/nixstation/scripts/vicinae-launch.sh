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

ensure_vicinae_server() {
  if timeout 2s vicinae ping >/dev/null 2>&1; then
    return 0
  fi

  # Systemd's packaged unit waits 60s before restart; force an immediate
  # restart so launcher invocations do not dead-air after resume.
  if systemctl --user restart vicinae.service >/dev/null 2>&1; then
    if wait_for_vicinae; then
      return 0
    fi
  else
    vicinae server --replace >/dev/null 2>&1 &
    local server_pid=$!

    for _ in $(seq 1 100); do
      if timeout 2s vicinae ping >/dev/null 2>&1; then
        return 0
      fi
      if ! kill -0 "$server_pid" 2>/dev/null; then
        break
      fi

      sleep 0.1
    done
  fi

  return 0
}

ensure_vicinae_server
exec vicinae "$@"
