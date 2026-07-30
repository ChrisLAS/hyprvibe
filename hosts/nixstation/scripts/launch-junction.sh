#!/usr/bin/env bash
set -euo pipefail

hyprctl dispatch 'hl.dsp.focus({ monitor = "DP-1" })'
junction &
sleep 1
hyprctl dispatch 'hl.dsp.window.move({ x = 2560, y = -1440 })'
hyprctl dispatch 'hl.dsp.window.resize({ x = 2560, y = 1440 })'
hyprctl dispatch 'hl.dsp.focus({ monitor = "DP-3" })'
