# NixStation Migration Plan: Local NixOS → Hyprland Configuration

## Overview
This document outlines the migration plan for moving your `nixstation` system from the current local NixOS configuration to the GitHub Hyprland-based configuration while preserving your existing file system layout and bootloader configuration.

## ✅ Completed Setup

### 1. Repository Structure
- ✅ Created `hosts/nixstation/` directory
- ✅ Created `hosts/nixstation/system.nix` - Main system configuration
- ✅ Created `hosts/nixstation/hardware-configuration.nix` - Hardware-specific config
- ✅ Copied Hyprland configuration files from `rvbee` host
- ✅ Copied Waybar configuration and scripts
- ✅ Updated `flake.nix` to include `nixstation` configuration

### 2. Preserved Configuration Elements
- ✅ **File System Layout**: Preserved your existing BTRFS `/nix` and `/home` mounts
- ✅ **Boot Loader**: Kept GRUB configuration with EFI support
- ✅ **Hardware Support**: Preserved Intel CPU and AMD GPU configurations
- ✅ **User Configuration**: Preserved user `chrisf` with all existing groups
- ✅ **Package Set**: Preserved all your existing packages and applications
- ✅ **Services**: Preserved Tor, SSH, Sunshine, and other custom services

### 3. Migration Changes
- ✅ **Kernel**: Switched from `linuxPackages_latest` to `linuxPackages_zen`
- ✅ **Desktop**: Migrated from Plasma 6 to Hyprland
- ✅ **Display Manager**: Switched from SDDM to GDM (Wayland)
- ✅ **Performance**: Added BPF tuning and additional performance optimizations

## 🔄 Migration Steps Required

### Step 1: Test Configuration (Recommended)
```bash
# Test the configuration without applying
sudo nixos-rebuild build --flake .#nixstation

# If successful, you can proceed with the actual switch
sudo nixos-rebuild switch --flake .#nixstation
```

### Step 2: Backup Current Configuration
```bash
# Backup your current configuration
sudo cp -r /etc/nixos /etc/nixos.backup.$(date +%Y%m%d)
```

### Step 3: Update Boot Configuration
Since you're switching from Plasma 6 to Hyprland, you'll need to:
1. Log out of your current session
2. At the GDM login screen, select "Hyprland" from the session menu
3. Log in with your existing credentials

### Step 4: Post-Migration Tasks
1. **Wallpaper**: Replace the placeholder wallpaper with your preferred image
2. **Hyprland Configuration**: Customize `hosts/nixstation/hyprland.conf` as needed
3. **Waybar**: Customize `hosts/nixstation/waybar.json` and `waybar.css` if desired
4. **User Scripts**: Any custom scripts in your home directory will need to be adapted for Hyprland

## 📋 Configuration Details

### File System Layout (Preserved)
```
/                    - ext4 (root)
/nix                 - btrfs (Nix store)
/home                - btrfs (user home)
/scary               - xfs (additional storage)
```

### Boot Configuration (Preserved)
- **Boot Loader**: GRUB with EFI
- **Kernel**: linuxPackages_zen (changed from latest)
- **Kernel Modules**: amdgpu, kvm-intel, kvm-amd
- **Kernel Parameters**: elevator=none

### Desktop Environment (Changed)
- **From**: Plasma 6 with SDDM
- **To**: Hyprland with GDM (Wayland)
- **Display Protocol**: Wayland (with XWayland support)

### Package Groups (Preserved + Enhanced)
- **Development Tools**: All your existing dev tools + additional ones
- **Multimedia**: All your existing multimedia tools + additional ones
- **Utilities**: All your existing utilities + Hyprland-specific tools
- **Applications**: All your existing applications + Hyprland apps
- **Gaming**: All your existing gaming tools + Steam integration
- **System Tools**: All your existing system tools

### Services (Preserved + Enhanced)
- **Audio**: PipeWire with ALSA/Pulse/JACK support
- **Networking**: NetworkManager, Tailscale, OpenSSH
- **Virtualization**: Docker, libvirtd
- **Security**: Tor, Polkit, sudo configuration
- **Performance**: BPF tuning, ZRAM, OOM management

## ⚠️ Important Notes

### 1. Desktop Environment Change
- You'll need to learn Hyprland keybindings and workflow
- Some Plasma-specific applications may need alternatives
- Wayland compatibility for all applications

### 2. Performance Optimizations
- Zen kernel should provide better performance
- BPF tuning will optimize system performance automatically
- ZRAM configuration preserved for memory optimization

### 3. Backup Strategy
- Always backup before major configuration changes
- Test in a VM if possible before applying to physical system
- Keep your old configuration as a fallback

## 🚀 Next Steps

1. **Review Configuration**: Check `hosts/nixstation/system.nix` for any customizations needed
2. **Test Build**: Run `sudo nixos-rebuild build --flake .#nixstation` to test
3. **Apply Configuration**: Run `sudo nixos-rebuild switch --flake .#nixstation`
4. **Login**: Use GDM to log into Hyprland session
5. **Customize**: Adapt to Hyprland workflow and customize as needed

## 🔧 Troubleshooting

### If Build Fails
- Check for missing packages or configuration errors
- Review the error messages and adjust configuration
- Ensure all file paths and UUIDs are correct

### If Boot Fails
- Boot into recovery mode or use a live USB
- Restore from backup: `sudo nixos-rebuild switch --flake /path/to/backup#nixstation`

### If Hyprland Doesn't Start
- Check GDM session selection
- Review Hyprland logs: `journalctl --user -u hyprland`
- Check Waybar and other components

## 📞 Support

If you encounter issues during migration:
1. Check the Hyprland documentation
2. Review the GitHub repository README
3. Check NixOS and Hyprland community resources
4. Keep your backup configuration for rollback if needed

---

**Migration Status**: Configuration files created and ready for testing
**Next Action**: Test build and apply configuration
**Risk Level**: Medium (major desktop environment change) 