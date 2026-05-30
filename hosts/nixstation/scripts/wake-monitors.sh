#!/usr/bin/env bash
set -u

outputs=(DP-1 DP-2 DP-3 HDMI-A-1)

for output in "${outputs[@]}"; do
  hyprctl dispatch dpms on "$output" >/dev/null 2>&1 || true
done

# The center ASUS PB278 on DP-3 sometimes misses the first DPMS resume.
# Power-cycle just that output and reassert the current static layout.
for _ in 1 2 3; do
  sleep 0.5
  hyprctl dispatch dpms off DP-3 >/dev/null 2>&1 || true
  sleep 0.5
  hyprctl keyword monitor "DP-3,preferred,1440x0,1" >/dev/null 2>&1 || true
  hyprctl dispatch dpms on DP-3 >/dev/null 2>&1 || true
done

for output in "${outputs[@]}"; do
  hyprctl dispatch dpms on "$output" >/dev/null 2>&1 || true
done
