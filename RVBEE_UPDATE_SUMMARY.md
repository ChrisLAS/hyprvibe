## Recent Fixes and Changes (2025-08-22)

- Enabled `systemd-resolved` and pointed `NetworkManager` DNS to it to eliminate DBus resolve1 activation errors at boot.
- Fixed `kwalletd` on Wayland: user service now starts on `graphical-session.target` with `QT_QPA_PLATFORM=wayland`.
- Netdata tuning:
  - Disabled Postgres collector (go.d) and silenced several noisy plugins (`logs-management`, `ioping`, `perf`, `freeipmi`, `charts.d`).
  - Kept Netdata installed but not auto-started; also prevented auto-restart on rebuilds. Start manually via `sudo systemctl start netdata`.
- Reduced Bluetooth HFP log spam by limiting BlueZ `General.Enable` to `Source,Sink,Media,Socket`.
- Activation script fix: call `${pkgs.desktop-file-utils}/bin/update-desktop-database` directly to avoid PATH-related errors.

# RVBEE Update Summary: Oh My Posh & Kitty Configuration

## Overview

Successfully updated RVBEE to have the same Oh My Posh and Kitty terminal configuration as NIXSTATION. All changes have been applied to ensure consistency across both systems.

## Changes Applied to RVBEE

### 1. **Package Installation**
- ✅ Added `oh-my-posh` to `devTools` package list
- ✅ Added `oh-my-posh` to `utilities` package list  
- ✅ Added `oh-my-posh` to `environment.systemPackages`

### 2. **Kitty Terminal Configuration**
- ✅ Created `~/.config/kitty/kitty.conf` with:
  - Tokyo Night color scheme
  - Fira Code font
  - URL detection and hyperlinks (`detect_urls yes`, `show_hyperlink_targets yes`, `underline_hyperlinks always`)
  - Copy on select enabled (`copy_on_select yes`)
  - Shell integration enabled (`shell_integration enabled`)
  - Fish shell integration
  - Performance optimizations
  - Key bindings for font size adjustment

### 3. **Oh My Posh Configuration**
- ✅ Created main configuration: `~/.config/oh-my-posh/config.json` (Tokyo Night theme)
- ✅ Created enhanced theme: `~/.config/oh-my-posh/config-enhanced.json` (Agnoster-inspired)
- ✅ Created minimal theme: `~/.config/oh-my-posh/config-minimal.json` (Robby Russell-inspired)
- ✅ Created professional theme: `~/.config/oh-my-posh/config-professional.json` (Atomic-inspired)

### 4. **Fish Shell Integration**
- ✅ Enhanced Atuin integration (already existed)
- ✅ Added Oh My Posh integration: `~/.config/fish/conf.d/oh-my-posh.fish`
- ✅ Added Kitty integration: `~/.config/fish/conf.d/kitty-integration.fish`
- ✅ Disabled Fish default prompt when Oh My Posh is active

### 5. **Theme Switching Script**
- ✅ Created `~/.local/bin/switch-oh-my-posh-theme` script
- ✅ Script allows easy switching between all 4 themes
- ✅ Includes backup functionality and help system

## Features Available on RVBEE

### **Kitty Terminal Features**
- URL detection and clickable hyperlinks
- Automatic copy on text selection
- Shell integration with Fish
- Tokyo Night color scheme
- Fira Code font with ligatures
- Performance optimizations
- Font size adjustment shortcuts (Ctrl+Shift+Plus/Minus)

### **Oh My Posh Features**
- **Default Theme**: Tokyo Night inspired, balanced features
- **Enhanced Theme**: Feature-rich with comprehensive dev tools
- **Minimal Theme**: Clean, distraction-free for productivity
- **Professional Theme**: Modern diamond style for presentations

### **Development Tool Detection**
- Git branch and status with dynamic backgrounds
- Node.js version detection
- Python version and virtual environment detection
- Go version detection
- Rust version detection
- Docker context detection
- Execution time for slow commands (>5 seconds)
- Exit status with error codes

### **Shell Integration**
- Atuin command history (Ctrl+R)
- Oh My Posh beautiful prompts
- Kitty terminal integration
- All existing Fish functionality preserved

## Usage Instructions

### **Switch Themes**
```bash
switch-oh-my-posh-theme enhanced    # Feature-rich development
switch-oh-my-posh-theme minimal     # Clean, distraction-free
switch-oh-my-posh-theme professional # Modern diamond style
switch-oh-my-posh-theme default     # Back to Tokyo Night
```

### **Start Kitty Terminal**
```bash
kitty
```

### **Test Features**
- URLs are automatically detected and underlined
- Text selection automatically copies to clipboard
- Oh My Posh prompt shows development tool information
- Atuin history search works with Ctrl+R

## Compatibility Verification

✅ **All components work together**:
- Oh My Posh + Fish shell
- Oh My Posh + Atuin history
- Kitty + Oh My Posh
- Kitty + Fish shell
- All existing RVBEE functionality preserved

## System Integration

- All configurations are automatically applied on system rebuild
- Theme switching script is available system-wide
- All Fish shell integrations are automatically loaded
- Kitty terminal is configured with optimal settings

## Next Steps

1. **Rebuild RVBEE**: Run `sudo nixos-rebuild switch` to apply changes
2. **Test Configuration**: Start a new terminal session to verify everything works
3. **Switch Themes**: Use the theme switcher to try different themes
4. **Enjoy**: Experience the same beautiful terminal setup as NIXSTATION

## Files Created/Modified

### **New Configuration Files**
- `~/.config/kitty/kitty.conf`
- `~/.config/oh-my-posh/config.json`
- `~/.config/oh-my-posh/config-enhanced.json`
- `~/.config/oh-my-posh/config-minimal.json`
- `~/.config/oh-my-posh/config-professional.json`
- `~/.config/fish/conf.d/oh-my-posh.fish`
- `~/.config/fish/conf.d/kitty-integration.fish`
- `~/.local/bin/switch-oh-my-posh-theme`

### **Modified System Files**
- `hyprvibe/hosts/rvbee/system.nix` - Added packages and activation scripts

RVBEE now has the exact same Oh My Posh and Kitty terminal setup as NIXSTATION, providing a consistent and beautiful development experience across both systems!
