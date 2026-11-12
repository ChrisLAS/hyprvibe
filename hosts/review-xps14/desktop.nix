{ lib, pkgs, ... }:
let
  wallpaper = ../../wallpapers/aishot-2602.jpg;
  barTemplate = builtins.fromJSON (builtins.readFile ../../configs/dms/bar-template.json);
in
{
  hyprvibe.hyprland = {
    shellBackend = "dms";
    monitorsFile = ./monitors.lua;
    inherit wallpaper;
  };
  hyprvibe.dms = {
    enable = true;
    wallpaper = toString wallpaper;
    barConfigs = [ (lib.recursiveUpdate barTemplate {
      id = "default";
      name = "Review XPS 14";
      screenPreferences = [ "all" ];
      showOnLastDisplay = true;
    }) ];
    # These plugins reference permanent-client AI/sync/workspace state.
    pluginSettingsOverrides = {
      nixvaderCodex.enabled = false;
      syncshell.enabled = false;
      quickCapture.enabled = false;
      wallpaperCarousel.enabled = false;
    };
  };
  xdg.portal.config.common."org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "video/*" = "mpv.desktop";
  };

  # The shared keymap retains these historical command names. Supply local,
  # Lua-compatible helpers rather than importing Nixvader's host configuration.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nixvader-gamemode" ''
      set -eu
      enabled="$(hyprctl getoption animations:enabled -j | ${pkgs.jq}/bin/jq -r .int)"
      if [ "$enabled" = 1 ]; then value=false; else value=true; fi
      exec hyprctl eval "hl.config({ animations = { enabled = $value } })"
    '')
    (pkgs.writeShellScriptBin "nixvader-blur-toggle" ''
      set -eu
      enabled="$(hyprctl getoption decoration:blur:enabled -j | ${pkgs.jq}/bin/jq -r .int)"
      if [ "$enabled" = 1 ]; then value=false; else value=true; fi
      exec hyprctl eval "hl.config({ decoration = { blur = { enabled = $value } } })"
    '')
  ];
}
