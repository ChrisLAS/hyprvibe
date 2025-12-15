# Dynamic Power Management for Nixbook

This configuration provides modern, NixOS-first dynamic power management with a performance bias, manual low-power mode switching, and automatic battery sleep.

## Features

- **Performance-biased defaults**: CPU, disk, WiFi, and GPU optimized for performance by default
- **Dynamic power profiles**: Switch between Performance, Balanced, and Power Saver modes
- **Automatic battery sleep**: System automatically sleeps after 30 minutes of inactivity when on battery
- **Hyprland integration**: Power profile switching via keybindings and launcher
- **Comprehensive control**: Manages CPU governor, WiFi power saving, disk power management, and GPU power states

## Usage

### Power Profile Switching

#### Via Hyprland Keybinding
- Press `SUPER+SHIFT+P` to open the power profile menu

#### Via Command Line
```bash
# Switch to performance mode (maximum performance)
power-profile performance

# Switch to balanced mode (balanced performance/power)
power-profile balanced

# Switch to power saver mode (maximum battery life)
power-profile power-saver

# Check current profile and battery status
power-profile status
```

#### Via Rofi Menu
```bash
rofi-power-profile
```

### Power Profiles

#### Performance Mode
- **CPU Governor**: `performance` (maximum frequency)
- **WiFi Power Saving**: Disabled
- **Disk Power Saving**: Disabled (drives stay active)
- **GPU Power Saving**: Disabled (Intel RC6 disabled, AMD high performance)
- **Use Case**: Gaming, video editing, compilation, maximum responsiveness

#### Balanced Mode
- **CPU Governor**: `schedutil` (adaptive)
- **WiFi Power Saving**: Enabled
- **Disk Power Saving**: Auto (allows some power saving)
- **GPU Power Saving**: Auto (balanced)
- **Use Case**: General desktop use, mixed workloads

#### Power Saver Mode
- **CPU Governor**: `powersave` (minimum frequency)
- **WiFi Power Saving**: Enabled
- **Disk Power Saving**: Enabled (aggressive power saving)
- **GPU Power Saving**: Enabled (maximum power saving)
- **Use Case**: Battery conservation, light workloads

## Automatic Battery Sleep

The system automatically monitors battery status and will:
- Lock the session
- Suspend the system

After **30 minutes** of inactivity when running on battery power.

This is handled by the `battery-auto-sleep` systemd user service.

### Disabling Auto-Sleep

To disable automatic battery sleep, set `autoSleepOnBatteryMinutes = 0` in your `system.nix`:

```nix
hyprvibe.power = {
  enable = true;
  autoSleepOnBatteryMinutes = 0;  # Disable auto-sleep
  # ... other settings
};
```

## Configuration

Power management is configured in `hosts/nixbook/system.nix`:

```nix
hyprvibe.power = {
  enable = true;
  autoSleepOnBatteryMinutes = 30;
  performanceMode = {
    cpuGovernor = "performance";
    wifiPowerSave = false;
    diskPowerSave = false;
  };
  powerSaverMode = {
    cpuGovernor = "powersave";
    wifiPowerSave = true;
    diskPowerSave = true;
  };
};
```

## Technical Details

### Components

1. **power-profiles-daemon**: Provides D-Bus interface for power profile switching
2. **power-profile script**: Installed to `~/.local/bin/power-profile` - handles profile switching
3. **rofi-power-profile script**: Rofi menu interface for power profiles
4. **battery-auto-sleep service**: Systemd user service for automatic sleep on battery

### Hardware Support

- **CPU**: Intel and AMD CPUs with frequency scaling support
- **WiFi**: Modern (iw) and legacy (iwconfig) WiFi drivers
- **Disk**: NVMe and SATA SSDs/HDDs
- **GPU**: Intel i915 and AMD amdgpu drivers

### System Integration

- Power profiles integrate with `power-profiles-daemon` when available
- Falls back to manual sysfs manipulation if daemon unavailable
- All changes require sudo privileges (handled automatically)
- User notifications via `notify-send` when switching profiles

## Troubleshooting

### Power profile not switching
- Ensure `power-profiles-daemon` is running: `systemctl --user status power-profiles-daemon`
- Check if CPU frequency scaling is available: `ls /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`
- Verify sudo access: `sudo -v`

### Auto-sleep not working
- Check battery detection: `upower -i $(upower -e | grep battery | head -1)`
- Verify service is running: `systemctl --user status battery-auto-sleep`
- Check logs: `journalctl --user -u battery-auto-sleep`

### WiFi power saving not applying
- Verify WiFi interface name: `ip link show | grep -E 'wl|wifi|wlan'`
- Check if `iw` or `iwconfig` is available: `which iw iwconfig`
- Test manually: `sudo iw dev wlan0 set power_save off`

## Performance Impact

- **Performance Mode**: Maximum performance, higher power consumption
- **Balanced Mode**: Good balance, moderate power consumption
- **Power Saver Mode**: Maximum battery life, reduced performance

The system defaults to **Performance Mode** to prioritize CPU, disk, WiFi, and GPU performance as requested.
