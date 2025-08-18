# Monitor-Specific Application Launch Keybindings for Nixstation

This document explains how to launch applications to specific monitors and positions in your 4-monitor Hyprland setup.

## Monitor Layout

```
┌─────────────────┬─────────────────┬─────────────────┐
│                 │                 │                 │
│   DP-1 (Top)    │                 │                 │
│  2560x1440      │                 │                 │
│                 │                 │                 │
├─────────────────┼─────────────────┼─────────────────┤
│                 │                 │                 │
│ DP-2 (Left)     │   DP-3 (Main)   │ HDMI-A-1 (Right)│
│ 1440x2560       │  2560x1440      │  1440x2560      │
│ (Vertical)      │                 │ (Vertical)      │
│                 │                 │                 │
└─────────────────┴─────────────────┴─────────────────┘
```

**Note**: DP-1 is directly above DP-3, not offset. The vertical monitors (DP-2 and HDMI-A-1) span the full height of both horizontal monitors.

## Available Keybindings

### Communication Apps (Right Vertical Monitor)
- **SUPER + S**: Launch Slack and Telegram on HDMI-A-1
  - Slack: Top half (4000, 0) - 1440x1280
  - Telegram: Bottom half (4000, 1280) - 1440x1280

### Development Tools (Left Vertical Monitor)
- **SUPER + D**: Launch Cursor editor and terminal on DP-2
  - Cursor: Top half (0, 0) - 1440x1280
  - Terminal: Bottom half (0, 1280) - 1440x1280

### Browser (Top Monitor)
- **SUPER + B**: Launch Firefox on DP-1
  - Full screen (2560, -1440) - 2560x1440

### Media Player (Main Monitor)
- **SUPER + M**: Launch MPV on DP-3
  - Full screen (1440, 0) - 2560x1440

## Monitor Focus and Window Movement

### Monitor Focus
- **SUPER + F1**: Focus DP-1 (Top)
- **SUPER + F2**: Focus DP-2 (Left Vertical)
- **SUPER + F3**: Focus DP-3 (Main)
- **SUPER + F4**: Focus HDMI-A-1 (Right Vertical)

### Window Movement Between Monitors
- **SUPER + SHIFT + F1**: Move window to DP-1
- **SUPER + SHIFT + F2**: Move window to DP-2
- **SUPER + SHIFT + F3**: Move window to DP-3
- **SUPER + SHIFT + F4**: Move window to HDMI-A-1

### Arrow Key Navigation
- **SUPER + CTRL + Arrow**: Focus monitor in direction
- **SUPER + SHIFT + CTRL + Arrow**: Move window to monitor in direction

## Creating Custom Keybindings

### Method 1: Inline Commands (Simple)
```bash
# Launch app on specific monitor
bind = SUPER, KEY, exec, hyprctl dispatch focusmonitor MONITOR && app & sleep 1 && hyprctl dispatch movewindow exact X Y && hyprctl dispatch resizeactive exact WIDTH HEIGHT
```

### Method 2: Script Files (Recommended)
1. Create a script in `hosts/nixstation/scripts/`
2. Add the script to `system.nix` copying section
3. Add keybinding to `hyprland-monitors-nixstation.conf`

Example script:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Focus monitor
hyprctl dispatch focusmonitor MONITOR

# Launch and position apps
app1 &
sleep 2
hyprctl dispatch movewindow exact X1 Y1
hyprctl dispatch resizeactive exact WIDTH1 HEIGHT1

app2 &
sleep 2
hyprctl dispatch movewindow exact X2 Y2
hyprctl dispatch resizeactive exact WIDTH2 HEIGHT2

# Return focus to main monitor
hyprctl dispatch focusmonitor DP-3
```

## Coordinate System

The coordinate system is based on the monitor layout:
- **X coordinates**: Left to right (0, 1440, 2560, 4000)
- **Y coordinates**: Top to bottom (-1440, 0, 720, 1440)

### Monitor Positions
- **DP-1 (Top)**: (2560, -1440) - 2560x1440
- **DP-2 (Left)**: (0, 0) - 1440x2560 (vertical)
- **DP-3 (Main)**: (1440, 0) - 2560x1440
- **HDMI-A-1 (Right)**: (4000, 0) - 1440x2560 (vertical)

**Note**: The vertical monitors (DP-2 and HDMI-A-1) are 2560 pixels tall, so each half is 1280 pixels.

## Useful Hyprland Commands

### Window Management
```bash
# Move window to exact position
hyprctl dispatch movewindow exact X Y

# Resize active window
hyprctl dispatch resizeactive exact WIDTH HEIGHT

# Move window to monitor
hyprctl dispatch movewindow mon:MONITOR

# Focus monitor
hyprctl dispatch focusmonitor MONITOR
```

### Window States
```bash
# Maximize window
hyprctl dispatch fullscreen

# Toggle floating
hyprctl dispatch togglefloating

# Pin window (always on top)
hyprctl dispatch pin
```

## Tips for Creating Keybindings

1. **Use scripts for complex setups**: Multiple apps with specific positioning
2. **Add sleep delays**: Give apps time to launch before positioning
3. **Return focus**: Always return focus to your main monitor
4. **Test coordinates**: Use `hyprctl monitors` to verify monitor positions
5. **Consider window states**: Some apps may need specific window states

## Troubleshooting

### Apps not positioning correctly
- Check if the app is already running
- Verify monitor names with `hyprctl monitors`
- Test coordinates with `hyprctl dispatch movewindow exact X Y`

### Scripts not working
- Ensure scripts are executable: `chmod +x script.sh`
- Check script paths in Hyprland config
- Verify script syntax with `bash -n script.sh`

### Monitor names
- Use `hyprctl monitors` to get exact monitor names
- Monitor names can change between reboots
- Consider using monitor indices instead of names for stability
