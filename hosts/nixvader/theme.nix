{ config, lib, pkgs, ... }:
let
  userHome = config.hyprvibe.user.home;
  baseCss = builtins.readFile ./waybar.css;
  profiles = {
    stealth = {
      active = "rgba(5f9ea0ee) rgba(6f8790ee) 45deg";
      inactive = "rgba(39434fcc)";
      accent = "#5f9ea0";
      accentBright = "#8fb8b8";
      warning = "#c49a52";
      critical = "#b8646b";
      bg = "#080b10";
      surface = "#10151c";
      fg = "#c7d0da";
      muted = "#657383";
      cursor = "#8fb8b8";
    };
    ember = {
      active = "rgba(c47a52ee) rgba(8f5363ee) 45deg";
      inactive = "rgba(4a3d3fcc)";
      accent = "#c47a52";
      accentBright = "#e0a16f";
      warning = "#d2a65a";
      critical = "#c05b63";
      bg = "#100b0b";
      surface = "#1a1111";
      fg = "#ded0c7";
      muted = "#88746d";
      cursor = "#e0a16f";
    };
    ice = {
      active = "rgba(6e9fd0ee) rgba(7d78b8ee) 45deg";
      inactive = "rgba(3c4558cc)";
      accent = "#6e9fd0";
      accentBright = "#a6c9e8";
      warning = "#c7ad68";
      critical = "#bd7185";
      bg = "#080d14";
      surface = "#0f1722";
      fg = "#c8d5e2";
      muted = "#66778a";
      cursor = "#a6c9e8";
    };
  };

  cssFor = p: lib.replaceStrings
    [ "#5f9ea0" "#8fb8b8" "#c49a52" "#b8646b" "#080b10" "#10151c" "#c7d0da" "#657383" ]
    [ p.accent p.accentBright p.warning p.critical p.bg p.surface p.fg p.muted ]
    baseCss;

  kittyFor = p: ''
    # Nixvader theme: managed by nixvader-theme
    background ${p.bg}
    foreground ${p.fg}
    selection_background ${p.surface}
    selection_foreground ${p.fg}
    url_color ${p.accentBright}
    cursor ${p.cursor}
    cursor_text_color ${p.bg}
    active_tab_background ${p.accent}
    active_tab_foreground ${p.bg}
    inactive_tab_background ${p.surface}
    inactive_tab_foreground ${p.muted}
    tab_bar_background ${p.bg}
    visual_bell_color ${p.critical}
  '';

  swayncCssFor = p: ''
    * { font-family: FiraCode Nerd Font; }
    .control-center { background: alpha(${p.bg}, 0.96); border: 1px solid ${p.accent}; border-radius: 8px; }
    .notification { background: ${p.surface}; border: 1px solid alpha(${p.accent}, 0.55); border-radius: 7px; color: ${p.fg}; }
    .notification-content { padding: 8px; }
    .summary { color: ${p.accentBright}; font-weight: bold; }
    .body { color: ${p.fg}; }
    .widget-title { color: ${p.accentBright}; }
    button { background: ${p.surface}; color: ${p.fg}; border: 1px solid alpha(${p.accent}, 0.35); border-radius: 6px; }
    button:hover { background: ${p.accent}; color: ${p.bg}; }
  '';

  swayncConfig = builtins.toJSON {
    positionX = "right";
    positionY = "top";
    control-center-width = 420;
    notification-window-width = 420;
    notification-icon-size = 48;
    timeout = 6;
    timeout-low = 3;
    timeout-critical = 0;
    notification-2fa-action = true;
    fit-to-screen = true;
    control-center-margin-top = 8;
    control-center-margin-right = 8;
    notification-window-margin = 8;
    layer = "overlay";
    layer-shell = true;
    control-center-layer = "top";
  };

  themeScript = pkgs.writeShellScriptBin "nixvader-theme" ''
    set -euo pipefail
    theme_dir=/etc/nixvader/themes
    state_dir="${userHome}/.config/nixvader"
    state_file="$state_dir/theme"
    mkdir -p "$state_dir" "${userHome}/.config/kitty" "${userHome}/.config/swaync" "${userHome}/.config/waybar"

    apply_theme() {
      local name="$1"
      local dir="$theme_dir/$name"
      if [ ! -d "$dir" ]; then
        echo "Unknown theme: $name" >&2
        echo "Available themes: stealth ember ice" >&2
        return 1
      fi
      install -Dm0644 "$dir/waybar.css" "${userHome}/.config/waybar/style.css"
      install -Dm0644 "$dir/kitty.conf" "${userHome}/.config/kitty/theme.conf"
      install -Dm0644 "$dir/swaync.css" "${userHome}/.config/swaync/style.css"
      install -Dm0644 "$dir/swaync.json" "${userHome}/.config/swaync/config.json"
      printf '%s\n' "$name" > "$state_file"

      # Apply compositor colors immediately when a Hyprland session exists.
      hyprctl keyword general:col.active_border "$(cat "$dir/active-border")" >/dev/null 2>&1 || true
      hyprctl keyword general:col.inactive_border "$(cat "$dir/inactive-border")" >/dev/null 2>&1 || true
      pkill -USR2 waybar 2>/dev/null || true
      swaync-client -R >/dev/null 2>&1 || true
      pkill -USR1 kitty 2>/dev/null || true
      echo "Applied Nixvader theme: $name"
    }

    case "''${1:-apply}" in
      list)
        printf '%s\n' stealth ember ice
        ;;
      current)
        if [ -r "$state_file" ]; then cat "$state_file"; else echo stealth; fi
        ;;
      apply)
        apply_theme "''${2:-stealth}"
        ;;
      menu)
        choice="$(printf '%s\n' stealth ember ice | vicinae dmenu -p 'Nixvader theme')"
        [ -n "$choice" ] && apply_theme "$choice"
        ;;
      *)
        echo "Usage: nixvader-theme {list|current|apply NAME|menu}" >&2
        exit 2
        ;;
    esac
  '';

  keybindsScript = pkgs.writeShellScriptBin "nixvader-keybinds" ''
    set -euo pipefail
    choice="$(cat <<'EOF' | vicinae dmenu -p 'Nixvader keybinds'
Super+Return  Kitty terminal
Super+Space   Vicinae launcher
Super+Shift+K Search keybinds
Super+T       Theme selector
Super+Shift+G Toggle animations
Super+Alt+O   Toggle blur
Super+Shift+N Notification center
Super+Ctrl+P  Logout menu
Super+Alt+C   Calculator
Super+Alt+V   Clipboard history
Alt+Shift+S   Annotated screenshot
EOF
)"
    [ -n "$choice" ] && notify-send "Nixvader keybind" "$choice"
  '';

  blurScript = pkgs.writeShellScriptBin "nixvader-blur-toggle" ''
    set -euo pipefail
    value="$(${pkgs.jq}/bin/jq -r '.int // 1' < <(hyprctl getoption decoration:blur:enabled -j 2>/dev/null))"
    if [ "$value" = 1 ]; then hyprctl keyword decoration:blur:enabled false; else hyprctl keyword decoration:blur:enabled true; fi
  '';

  gamemodeScript = pkgs.writeShellScriptBin "nixvader-gamemode" ''
    set -euo pipefail
    value="$(${pkgs.jq}/bin/jq -r '.int // 1' < <(hyprctl getoption animations:enabled -j 2>/dev/null))"
    if [ "$value" = 1 ]; then
      hyprctl keyword animations:enabled false
      notify-send "Nixvader" "Performance mode enabled"
    else
      hyprctl keyword animations:enabled true
      notify-send "Nixvader" "Animations restored"
    fi
  '';

  profileEtc = name: p: {
    "nixvader/themes/${name}/waybar.css".text = cssFor p;
    "nixvader/themes/${name}/kitty.conf".text = kittyFor p;
    "nixvader/themes/${name}/swaync.css".text = swayncCssFor p;
    "nixvader/themes/${name}/swaync.json".text = swayncConfig;
    "nixvader/themes/${name}/active-border".text = p.active;
    "nixvader/themes/${name}/inactive-border".text = p.inactive;
  };
in
{
  imports = [];

  environment.etc = lib.mkMerge (lib.mapAttrsToList profileEtc profiles);
  environment.systemPackages = [ themeScript keybindsScript blurScript gamemodeScript pkgs.wallust pkgs.wlogout pkgs.swappy pkgs.qalculate-gtk pkgs.swaynotificationcenter ];

  systemd.user.services.nixvader-theme = {
    description = "Nixvader: apply selected visual theme";
    unitConfig.ConditionUser = config.hyprvibe.user.name;
    wantedBy = [ "default.target" ];
    after = [ "hyprvibe-setup-waybar.service" "hyprvibe-setup-kitty.service" ];
    wants = [ "hyprvibe-setup-waybar.service" "hyprvibe-setup-kitty.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "nixvader-apply-default-theme" ''
        set -euo pipefail
        state=${userHome}/.config/nixvader/theme
        theme=stealth
        if [ -r "$state" ]; then theme=$(cat "$state"); fi
        exec ${themeScript}/bin/nixvader-theme apply "$theme"
      '';
    };
  };
}
