#!/usr/bin/env bash
set -euo pipefail

# Prefer playerctld to unify active player selection
status=$(playerctl -p playerctld status 2>/dev/null || echo "Stopped")
case "$status" in
  Playing) icon="▶️" ;;
  Paused)  icon="⏸️" ;;
  *)       icon="🎵" ;;
esac

title=$(playerctl -p playerctld metadata title 2>/dev/null || true)
# Escape quotes for JSON
title=${title//"/\"}

if [[ -n "$title" ]]; then
  printf '{"text":"%s","tooltip":"%s"}\n' "$icon" "$title"
else
  printf '{"text":"%s","tooltip":"MPRIS"}\n' "$icon"
fi


