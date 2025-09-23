# Monitor-Specific Application Launch Keybindings

This document describes the custom keybindings for launching applications on specific monitors on the **nixstation** host.

## Monitor Layout

```
    [DP-1] Top Monitor (2560x1440)
    [DP-3] Center/Main Monitor (2560x1440)
[DP-2] Left Vertical [HDMI-A-1] Right Vertical
```

## Application Launch Keybindings

### Communication Apps (Right Vertical Monitor - HDMI-A-1)
- **SUPER + S**: Launch Slack, then Telegram after 2-second delay
  - Opens both communication apps on the right vertical monitor
  - Slack launches first, then Telegram

### Development Tools (Left Vertical Monitor - DP-2)
- **SUPER + D**: Launch Cursor editor and terminal
  - Opens development environment on the left vertical monitor

### Browser (Top Monitor - DP-1)
- **SUPER + G**: Launch Junction on top monitor
  - Opens browser on the top monitor (DP-1)

### Media Player (Main Monitor - DP-3)
- **SUPER + K**: Launch media player on main monitor
  - Opens media player on the center/main monitor

## Monitor Navigation Keybindings

### Focus Monitors
- **SUPER + F1**: Focus top monitor (DP-1)
- **SUPER + F2**: Focus left vertical monitor (DP-2)
- **SUPER + F3**: Focus main monitor (DP-3)
- **SUPER + F4**: Focus right vertical monitor (HDMI-A-1)

### Move Windows Between Monitors
- **SUPER + SHIFT + F1**: Move window to top monitor (DP-1)
- **SUPER + SHIFT + F2**: Move window to left vertical monitor (DP-2)
- **SUPER + SHIFT + F3**: Move window to main monitor (DP-3)
- **SUPER + SHIFT + F4**: Move window to right vertical monitor (HDMI-A-1)

### Arrow Key Navigation
- **SUPER + CTRL + Arrow Keys**: Move focus between monitors
- **SUPER + SHIFT + CTRL + Arrow Keys**: Move windows between monitors

## Creating Custom Keybindings

To add new monitor-specific keybindings:

1. **Edit the monitor config**: `hyprvibe/configs/hyprland-monitors-nixstation.conf`
2. **Add your keybinding**: Follow the pattern:
   ```bash
   # SUPER + [KEY]: Description
   bind = SUPER, [KEY], exec, your-command-here
   ```
3. **Copy to system**: `cp configs/hyprland-monitors-nixstation.conf ~/.config/hypr/`
4. **Reload Hyprland**: `hyprctl reload`

## Important Notes

- **Avoid conflicts**: Check that your new keybinding doesn't conflict with existing bindings in `hyprland-base.conf`
- **Monitor names**: Use the exact monitor names (DP-1, DP-2, DP-3, HDMI-A-1)
- **Positioning**: Use `hyprctl dispatch movewindow exact X Y` for precise positioning
- **Focus management**: Use `hyprctl dispatch focusmonitor` to ensure apps open on the correct monitor
