#!/usr/bin/env bash
set -euo pipefail

state="off"
if dunstctl is-paused >/dev/null 2>&1; then
  if dunstctl is-paused | grep -qi true; then
    state="paused"
  else
    state="on"
  fi
fi

icon="🔔"
case "$state" in
  paused) icon="🔕" ;;
  on) icon="🔔" ;;
  off) icon="🔔" ;;
esac

echo "{\"text\": \"$icon\", \"tooltip\": \"Notifications: $state (click to toggle)\"}"

