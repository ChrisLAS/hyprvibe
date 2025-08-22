#!/run/current-system/sw/bin/bash

# Oh My Posh Theme Switcher
# Easily switch between different Oh My Posh themes

THEME_DIR="$HOME/.config/oh-my-posh"
CURRENT_CONFIG="$THEME_DIR/config.json"

# Available themes
THEMES=(
    "default"      # Your current Tokyo Night theme
    "enhanced"     # Feature-rich Agnoster-inspired theme
    "minimal"      # Clean Robby Russell-inspired theme
    "professional" # Modern Atomic-inspired diamond theme
)

show_usage() {
    echo "Oh My Posh Theme Switcher"
    echo "========================="
    echo
    echo "Usage: $0 [theme_name]"
    echo
    echo "Available themes:"
    for theme in "${THEMES[@]}"; do
        echo "  - $theme"
    done
    echo
    echo "Examples:"
    echo "  $0 enhanced    # Switch to enhanced development theme"
    echo "  $0 minimal     # Switch to minimalist theme"
    echo "  $0 professional # Switch to professional diamond theme"
    echo "  $0 default     # Switch back to default theme"
    echo
    echo "Current theme: $(basename $(readlink -f "$CURRENT_CONFIG" 2>/dev/null || echo "config.json"))"
}

switch_theme() {
    local theme_name="$1"
    local theme_file="$THEME_DIR/config-${theme_name}.json"
    
    if [[ "$theme_name" == "default" ]]; then
        theme_file="$THEME_DIR/config.json"
    fi
    
    if [[ ! -f "$theme_file" ]]; then
        echo "Error: Theme '$theme_name' not found at $theme_file"
        echo "Available themes:"
        for theme in "${THEMES[@]}"; do
            if [[ -f "$THEME_DIR/config-${theme}.json" ]] || [[ "$theme" == "default" && -f "$CURRENT_CONFIG" ]]; then
                echo "  - $theme"
            fi
        done
        exit 1
    fi
    
    # Create backup of current config
    if [[ -f "$CURRENT_CONFIG" ]]; then
        cp "$CURRENT_CONFIG" "$THEME_DIR/config-backup-$(date +%Y%m%d-%H%M%S).json"
    fi
    
    # Switch to new theme
    if [[ "$theme_name" == "default" ]]; then
        # Restore original config
        if [[ -f "$THEME_DIR/config-original.json" ]]; then
            cp "$THEME_DIR/config-original.json" "$CURRENT_CONFIG"
        fi
    else
        # Copy theme to main config
        cp "$theme_file" "$CURRENT_CONFIG"
    fi
    
    echo "✅ Switched to '$theme_name' theme"
    echo "🔄 Restart your terminal or run 'exec fish' to see changes"
    echo
    echo "Theme descriptions:"
    echo "  default     - Tokyo Night inspired, balanced features"
    echo "  enhanced    - Feature-rich with comprehensive dev tools"
    echo "  minimal     - Clean, distraction-free for productivity"
    echo "  professional - Modern diamond style for presentations"
}

# Main script logic
if [[ $# -eq 0 ]]; then
    show_usage
    exit 0
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

switch_theme "$1"
