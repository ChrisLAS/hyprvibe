#!/usr/bin/env bash
set -euo pipefail

# Launch development tools on left vertical monitor (DP-2)
# Cursor editor on top half, terminal on bottom half

# Focus the left vertical monitor
hyprctl dispatch 'hl.dsp.focus({ monitor = "DP-2" })'

# Launch Cursor editor and position it on top half
cursor &
sleep 2
# Move to DP-2 monitor first, then position
hyprctl dispatch 'hl.dsp.window.move({ monitor = "DP-2" })'
hyprctl dispatch 'hl.dsp.window.move({ x = 0, y = 0 })'
hyprctl dispatch 'hl.dsp.window.resize({ x = 1440, y = 1280 })'

# Launch terminal and position it on bottom half
kitty &
sleep 2
# Move to DP-2 monitor first, then position
hyprctl dispatch 'hl.dsp.window.move({ monitor = "DP-2" })'
hyprctl dispatch 'hl.dsp.window.move({ x = 0, y = 1280 })'
hyprctl dispatch 'hl.dsp.window.resize({ x = 1440, y = 1280 })'

# Focus back to the main monitor (DP-3)
hyprctl dispatch 'hl.dsp.focus({ monitor = "DP-3" })'
