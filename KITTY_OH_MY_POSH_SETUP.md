# Kitty Terminal + Oh My Posh + Fish + Atuin Setup

## Overview

This configuration sets up a complete terminal environment with:
- **Kitty Terminal**: Modern, fast terminal emulator with GPU acceleration
- **Oh My Posh**: Beautiful, customizable prompt engine
- **Fish Shell**: User-friendly shell with excellent features
- **Atuin**: Advanced command history management

## Compatibility Verification ✅

All components work perfectly together:
- ✅ **Oh My Posh + Fish**: Native Fish shell support with excellent integration
- ✅ **Oh My Posh + Atuin**: No conflicts - Atuin manages history, Oh My Posh manages prompt
- ✅ **Kitty + Oh My Posh**: Excellent shell integration and prompt rendering
- ✅ **Kitty + Fish**: Native Fish shell support with shell integration

## Features Configured

### Kitty Terminal Features
- **URL Detection**: Automatically detects and underlines URLs
- **Hyperlink Support**: Clickable URLs with target preview
- **Copy on Select**: Automatic clipboard copying when text is selected
- **Shell Integration**: Enhanced integration with Fish shell
- **Tokyo Night Theme**: Beautiful dark theme with blue accents
- **Fira Code Font**: Programming font with ligatures
- **Performance Optimized**: GPU acceleration and efficient rendering

### Oh My Posh Features
- **Custom Theme**: Tokyo Night inspired colors
- **Development Tools**: Shows Git, Node.js, Python, Go, Rust, Docker context
- **Execution Time**: Shows command execution time for slow commands
- **Exit Status**: Visual feedback for command success/failure
- **Time Display**: Current time in the right prompt
- **Path Display**: Smart path truncation and styling

### Fish Shell Features
- **Atuin Integration**: Advanced command history with search
- **Oh My Posh Integration**: Beautiful, informative prompts
- **Kitty Integration**: Enhanced terminal features
- **Git Integration**: Built-in Git status and completion

### Atuin Features
- **Command History**: Persistent, searchable command history
- **Cross-Session**: History shared across all terminal sessions
- **Search**: Fuzzy search with Ctrl+R
- **Sync**: Optional cloud sync for history

## Configuration Files

### Kitty Configuration
- **Location**: `~/.config/kitty/kitty.conf`
- **Features**:
  - URL detection and hyperlinks
  - Copy on select enabled
  - Shell integration enabled
  - Tokyo Night color scheme
  - Fira Code font
  - Performance optimizations

### Oh My Posh Configuration
- **Location**: `~/.config/oh-my-posh/config.json`
- **Features**:
  - Custom Tokyo Night theme
  - Development tool detection
  - Execution time tracking
  - Exit status display
  - Time display

### Fish Shell Configuration
- **Location**: `~/.config/fish/conf.d/`
- **Files**:
  - `oh-my-posh.fish`: Oh My Posh integration
  - `kitty-integration.fish`: Kitty terminal integration
  - `atuin.fish`: Atuin history integration

## Usage Instructions

### Starting Kitty Terminal
```bash
kitty
```

### Testing Features
Run the test script to verify all features:
```bash
./test-kitty-features.sh
```

### Oh My Posh Commands
- **Change Theme**: Edit `~/.config/oh-my-posh/config.json`
- **Reload Prompt**: `omp_repaint_prompt` in Fish
- **Enable Tooltips**: `enable_poshtooltips` in Fish

### Atuin Commands
- **Search History**: `Ctrl+R` in Fish
- **Sync History**: `atuin sync`
- **Import History**: `atuin import`
- **Stats**: `atuin stats`

### Kitty Commands
- **New Window**: `Ctrl+Shift+Enter`
- **New Tab**: `Ctrl+Shift+T`
- **Close Tab**: `Ctrl+Shift+W`
- **Font Size**: `Ctrl+Shift+Plus/Minus`
- **Reset Font**: `Ctrl+Shift+0`

## Troubleshooting

### Oh My Posh Not Loading
1. Check if package is installed: `which oh-my-posh`
2. Verify Fish configuration: `cat ~/.config/fish/conf.d/oh-my-posh.fish`
3. Restart Fish shell: `exec fish`

### Kitty Features Not Working
1. Check configuration: `kitty --config ~/.config/kitty/kitty.conf`
2. Verify shell integration: `echo $KITTY_SHELL_INTEGRATION`
3. Restart Kitty terminal

### Atuin Not Working
1. Check service status: `systemctl --user status atuin`
2. Verify Fish integration: `cat ~/.config/fish/conf.d/atuin.fish`
3. Test history search: `Ctrl+R` in Fish

## System Integration

### NixOS Configuration
The setup is integrated into the NixOS system configuration:
- Oh My Posh package added to system packages
- Configuration files created via activation scripts
- Fish shell configured with all integrations
- Atuin service enabled

### Automatic Setup
On system rebuild, the following is automatically configured:
- Kitty terminal configuration
- Oh My Posh theme and integration
- Fish shell with all plugins
- Atuin history service

## Performance Notes

- **Kitty**: GPU-accelerated rendering for smooth performance
- **Oh My Posh**: Efficient prompt rendering with caching
- **Fish**: Fast startup and command execution
- **Atuin**: Minimal overhead for history management

## Security Considerations

- **Atuin**: History can be optionally encrypted and synced
- **Kitty**: Secure clipboard handling
- **Oh My Posh**: No sensitive data in prompts
- **Fish**: Secure by default with no additional risks

## Future Enhancements

Potential improvements:
- Custom Oh My Posh themes
- Additional Kitty keybindings
- Fish shell plugins
- Atuin cloud sync configuration
- Performance monitoring integration
