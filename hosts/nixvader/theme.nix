{ pkgs, ... }:
let
  keybindsScript = pkgs.writeShellScriptBin "nixvader-keybinds" ''
        set -euo pipefail
        choice="$(cat <<'EOF' | vicinae dmenu -p 'Nixvader keybinds'
    Super+Return  Kitty terminal
    Super+Space   Application launcher
    Super+Shift+K Search keybinds
    Super+T       Shell theme settings
    Super+Shift+G Toggle animations
    Super+Alt+O   Toggle blur
    Super+Shift+N Notification center
    Ctrl+Alt+P    Power menu
    Super+Alt+C   Calculator
    Super+Alt+V   Clipboard history
    Super+B       Control center
    Super+L       Lock and turn displays off
    Alt+Shift+S   Annotated screenshot
    EOF
    )"
        [ -n "$choice" ] && notify-send "Nixvader keybind" "$choice"
  '';

  themeScript = pkgs.writeShellScriptBin "nixvader-theme" ''
    set -euo pipefail
    case "''${1:-menu}" in
      menu|settings|apply)
        exec dms ipc call settings openWith theme
        ;;
      current)
        exec dms ipc call settings get currentThemeName
        ;;
      *)
        echo "Nixvader themes are now managed by DankMaterialShell." >&2
        echo "Usage: nixvader-theme {menu|settings|current}" >&2
        exit 2
        ;;
    esac
  '';

  blurScript = pkgs.writeShellScriptBin "nixvader-blur-toggle" ''
    set -euo pipefail
    value="$(${pkgs.jq}/bin/jq -r '.int // 1' < <(hyprctl getoption decoration:blur:enabled -j 2>/dev/null))"
    if [ "$value" = 1 ]; then
      hyprctl keyword decoration:blur:enabled false
    else
      hyprctl keyword decoration:blur:enabled true
    fi
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

  shellScript = pkgs.writeShellScriptBin "nixvader-shell" ''
    set -euo pipefail

    start_unit() {
      local unit="$1"
      shift
      systemctl --user stop "$unit.service" >/dev/null 2>&1 || true
      systemd-run --user --unit="$unit" --collect --property=Restart=on-failure -- "$@" >/dev/null
    }

    case "''${1:-status}" in
      dms)
        systemctl --user stop 'nixvader-legacy-*' >/dev/null 2>&1 || true
        pkill -x waybar 2>/dev/null || true
        pkill -x swaync 2>/dev/null || true
        pkill -x hypridle 2>/dev/null || true
        systemctl --user stop hyprvibe-hyprpaper.service >/dev/null 2>&1 || true
        systemctl --user restart dms.service
        echo "Nixvader is using DankMaterialShell. Log in again to reset all shell keybindings."
        ;;
      legacy)
        systemctl --user stop dms.service >/dev/null 2>&1 || true
        systemctl --user start hyprvibe-hyprpaper.service >/dev/null 2>&1 || true
        start_unit nixvader-legacy-waybar ${pkgs.waybar}/bin/waybar
        start_unit nixvader-legacy-swaync ${pkgs.swaynotificationcenter}/bin/swaync
        start_unit nixvader-legacy-hypridle ${pkgs.hypridle}/bin/hypridle
        start_unit nixvader-legacy-clipboard ${pkgs.bash}/bin/bash -lc '${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store'
        start_unit nixvader-legacy-clipboard-persist ${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular
        echo "Legacy Waybar/SwayNC shell started for this session. Run 'nixvader-shell dms' to return."
        ;;
      status)
        systemctl --user --no-pager --full status dms.service || true
        ;;
      *)
        echo "Usage: nixvader-shell {dms|legacy|status}" >&2
        exit 2
        ;;
    esac
  '';
in
{
  environment.systemPackages = [
    themeScript
    keybindsScript
    blurScript
    gamemodeScript
    shellScript
    pkgs.wallust
    pkgs.wlogout
    pkgs.swappy
    pkgs.qalculate-gtk
    pkgs.swaynotificationcenter
  ];
}
