#!/usr/bin/env bash
set -euo pipefail

ensure_vicinae_server() {
  if vicinae ping >/dev/null 2>&1; then
    return 0
  fi

  vicinae server --replace >/dev/null 2>&1 &
  local server_pid=$!

  for _ in $(seq 1 100); do
    if vicinae ping >/dev/null 2>&1; then
      return 0
    fi

    if ! kill -0 "$server_pid" 2>/dev/null; then
      break
    fi

    sleep 0.1
  done

  return 0
}

ensure_vicinae_server
exec vicinae "$@"
