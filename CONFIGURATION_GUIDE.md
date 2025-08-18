# Hyprland Configuration Guide

This guide explains the modular configuration structure for managing Hyprland settings across multiple hosts.

## Overview

The configuration is split into modular components to allow for:
- **Shared base configuration** across all hosts
- **Host-specific monitor configurations** for different setups
- **Easy maintenance** and updates
- **Scalability** for future hosts

## File Structure

```
hyprvibe/
├── configs/
│   ├── hyprland-base.conf              # Shared base configuration
│   ├── hyprland-monitors-nixstation.conf  # Nixstation monitor config
│   └── hyprland-monitors-rvbee.conf    # Rvbee monitor config
├── hosts/
│   ├── nixstation/
│   │   └── hyprland.conf               # Nixstation main config (sources others)
│   └── rvbee/
│       └── hyprland.conf               # Rvbee main config (sources others)
└── scripts/
    └── setup-monitors.sh               # Monitor setup helper script
```

## Configuration Components

### 1. Base Configuration (`configs/hyprland-base.conf`)

Contains all shared settings:
- Keybindings
- General appearance settings
- Input configuration
- Animations
- Window rules
- Application launchers

### 2. Monitor Configurations

#### Nixstation (`configs/hyprland-monitors-nixstation.conf`)
- 4-monitor setup
- Workspace assignments per monitor
- Multi-monitor specific settings

#### Rvbee (`configs/hyprland-monitors-rvbee.conf`)
- Single monitor setup
- Simplified configuration

### 3. Host-Specific Configurations

Each host has a main configuration file that sources the appropriate components:

```bash
# Source shared base configuration
source = ~/.config/hypr/hyprland-base.conf

# Source host-specific monitor configuration
source = ~/.config/hypr/hyprland-monitors-{hostname}.conf

# Host-specific overrides and additions
```

## Setting Up Monitors

### Using the Helper Script

The `setup-monitors` script makes it easy to configure monitors:

```bash
# Full setup process for nixstation
setup-monitors setup nixstation

# Just detect current monitors
setup-monitors detect

# Apply existing configuration
setup-monitors apply nixstation

# Show current status
setup-monitors status
```

### Manual Monitor Configuration

1. **Detect your monitors:**
   ```bash
   hyprctl monitors
   ```

2. **Edit the monitor configuration file:**
   ```bash
   nano ~/.config/hypr/hyprland-monitors-nixstation.conf
   ```

3. **Example configuration for 4 monitors:**
   ```bash
   monitor=DP-1,2560x1440@144,0x0,1
   monitor=DP-2,2560x1440@144,2560x0,1
   monitor=HDMI-A-1,1920x1080@60,5120x0,1
   monitor=HDMI-A-2,1920x1080@60,5120x1080,1
   ```

4. **Apply the configuration:**
   ```bash
   setup-monitors apply nixstation
   ```

## Adding a New Host

1. **Create monitor configuration:**
   ```bash
   cp configs/hyprland-monitors-rvbee.conf configs/hyprland-monitors-newhost.conf
   ```

2. **Create host configuration:**
   ```bash
   cp hosts/rvbee/hyprland.conf hosts/newhost/hyprland.conf
   ```

3. **Update the host configuration:**
   ```bash
   # Edit hosts/newhost/hyprland.conf
   source = ~/.config/hypr/hyprland-monitors-newhost.conf
   ```

4. **Update system.nix:**
   - Add the new host to the flake.nix
   - Copy configuration files in the activation script

## Making Changes

### Global Changes (affects all hosts)
Edit `configs/hyprland-base.conf` and rebuild all hosts.

### Host-Specific Changes
Edit the appropriate host configuration file:
- `hosts/nixstation/hyprland.conf` for nixstation
- `hosts/rvbee/hyprland.conf` for rvbee

### Monitor-Specific Changes
Edit the appropriate monitor configuration:
- `configs/hyprland-monitors-nixstation.conf` for nixstation
- `configs/hyprland-monitors-rvbee.conf` for rvbee

## Rebuilding Configuration

After making changes, rebuild the system:

```bash
# For nixstation
sudo nixos-rebuild switch --flake /home/chrisf/build/config/hyprvibe#nixstation

# For rvbee
sudo nixos-rebuild switch --flake /home/chrisf/build/config/hyprvibe#rvbee
```

## Troubleshooting

### Configuration Not Loading
1. Check that all source files exist:
   ```bash
   ls -la ~/.config/hypr/
   ```

2. Check Hyprland logs:
   ```bash
   journalctl --user -u hyprland --since "5 minutes ago"
   ```

### Monitor Issues
1. Verify monitor detection:
   ```bash
   setup-monitors detect
   ```

2. Check current configuration:
   ```bash
   setup-monitors status
   ```

3. Test monitor configuration:
   ```bash
   hyprctl keyword monitor "DP-1,2560x1440@144,0x0,1"
   ```

## Best Practices

1. **Always test changes** on one host before applying to others
2. **Use the helper script** for monitor configuration
3. **Keep monitor configurations simple** and well-documented
4. **Document host-specific requirements** in the configuration files
5. **Use version control** to track changes across hosts

## Future Enhancements

Potential improvements to consider:
- **Dynamic monitor detection** and configuration
- **Per-monitor workspace assignments** based on monitor count
- **Performance optimizations** for multi-monitor setups
- **Backup and restore** functionality for monitor configurations
