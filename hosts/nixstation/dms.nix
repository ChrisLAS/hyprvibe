{ lib, pkgs, ... }:
let
  barTemplate = builtins.fromJSON (builtins.readFile ../../configs/dms/bar-template.json);
  fullBar = lib.recursiveUpdate barTemplate {
    id = "nixstation-main";
    name = "Nixstation Main";
    screenPreferences = [ "DP-3" ];
    showOnLastDisplay = false;
    rightWidgets = [
      "idleInhibitor"
      "cpuUsage"
      "memUsage"
      "nixvaderCodex"
      "nixvaderWorldClock"
      "systemTray"
      "notificationButton"
      "controlCenterButton"
    ];
  };
  satelliteBar = lib.recursiveUpdate barTemplate {
    id = "nixstation-satellites";
    name = "Nixstation Satellites";
    screenPreferences = [
      "DP-1"
      "DP-2"
      "HDMI-A-1"
    ];
    showOnLastDisplay = false;
    leftWidgets = [
      "workspaceSwitcher"
      "focusedWindow"
    ];
    centerWidgets = [ ];
    rightWidgets = [ "clock" ];
  };
in
{
  hyprvibe.dms = {
    enable = true;
    wallpaper = toString ../../wallpapers/aishot-2602.jpg;
    barConfigs = [
      fullBar
      satelliteBar
    ];
    exportBarId = "nixstation-main";
    pluginSettingsOverrides.wallpaperCarousel.enabled = false;
    legacyWaybarCommand = ''
      ${pkgs.waybar}/bin/waybar -c ~/.config/waybar/waybar-simple-dp1.json -s ~/.config/waybar/style.css &
      pids="$!"
      ${pkgs.waybar}/bin/waybar -c ~/.config/waybar/waybar-simple-dp2.json -s ~/.config/waybar/style.css &
      pids="$pids $!"
      ${pkgs.waybar}/bin/waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css &
      pids="$pids $!"
      ${pkgs.waybar}/bin/waybar -c ~/.config/waybar/waybar-simple-hdmi.json -s ~/.config/waybar/style.css &
      pids="$pids $!"
      trap 'kill $pids 2>/dev/null || true' EXIT INT TERM
      wait
    '';
  };

  programs.dank-calendar = {
    enable = true;
    systemd = {
      enable = true;
      target = "nixos-fake-graphical-session.target";
      restartIfChanged = true;
    };
  };
}
