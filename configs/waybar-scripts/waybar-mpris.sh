#!/usr/bin/env bash
set -euo pipefail

status=$(playerctl -p playerctld status 2>/dev/null || echo "Stopped")
case "$status" in
  Playing) icon="▶️" ;;
  Paused)  icon="⏸️" ;;
  *)       icon="🎵" ;;
esac

title=$(playerctl -p playerctld metadata title 2>/dev/null || true)
if command -v jq >/dev/null 2>&1; then
  esc_title=$(printf '%s' "$title" | jq -Rsa .)
else
  esc_title="\"${title//\"/\\\"}\""
fi

if [[ -n "$title" ]]; then
  printf '{"text":"%s","tooltip":%s}\n' "$icon" "$esc_title"
else
  printf '{"text":"%s","tooltip":"MPRIS"}\n' "$icon"
fi


