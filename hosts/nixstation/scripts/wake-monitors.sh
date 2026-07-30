#!/usr/bin/env bash
set -u

outputs=(DP-1 DP-2 DP-3 HDMI-A-1)

for output in "${outputs[@]}"; do
  hyprctl dispatch "hl.dsp.dpms({ action = \"on\", monitor = \"$output\" })" >/dev/null 2>&1 || true
done

# The center ASUS PB278 on DP-3 sometimes misses the first DPMS resume.
# Power-cycle just that output and reassert the current static layout.
for _ in 1 2 3; do
  sleep 0.5
  hyprctl dispatch 'hl.dsp.dpms({ action = "off", monitor = "DP-3" })' >/dev/null 2>&1 || true
  sleep 0.5
  hyprctl eval 'hl.monitor({ output = "DP-3", mode = "preferred", position = "1440x0", scale = 1 })' >/dev/null 2>&1 || true
  hyprctl dispatch 'hl.dsp.dpms({ action = "on", monitor = "DP-3" })' >/dev/null 2>&1 || true
done

for output in "${outputs[@]}"; do
  hyprctl dispatch "hl.dsp.dpms({ action = \"on\", monitor = \"$output\" })" >/dev/null 2>&1 || true
done
