#!/usr/bin/env bash
set -euo pipefail

hyprctl dispatch 'hl.dsp.focus({ monitor = "DP-3" })'
mpv &
sleep 1
hyprctl dispatch 'hl.dsp.window.move({ x = 1440, y = 0 })'
hyprctl dispatch 'hl.dsp.window.resize({ x = 2560, y = 1440 })'
