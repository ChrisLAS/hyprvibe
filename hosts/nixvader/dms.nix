{ lib, pkgs, ... }:
let
  barTemplate = builtins.fromJSON (builtins.readFile ../../configs/dms/bar-template.json);
  fullBar = lib.recursiveUpdate barTemplate {
    id = "default";
    name = "Nixvader";
    screenPreferences = [ "all" ];
    showOnLastDisplay = true;
  };
in
{
  hyprvibe.dms = {
    enable = true;
    wallpaper = "/home/chrisf/Pictures/bkgrounds/vaderhole.jpg";
    barConfigs = [ fullBar ];
    exportBarId = "default";
    legacyWaybarCommand = "exec ${pkgs.waybar}/bin/waybar";
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
