{ lib, pkgs, config, ... }:
let
  cfg = config.hyprvibe.waybar;
  user = config.hyprvibe.user;
  userHome = user.home;
  userName = user.name;
  userGroup = user.group;
in {
  options.hyprvibe.waybar = {
    enable = lib.mkEnableOption "Waybar setup and config install";
    configPath = lib.mkOption { type = lib.types.nullOr lib.types.path; default = null; };
    stylePath = lib.mkOption { type = lib.types.nullOr lib.types.path; default = null; };
    scriptsDir = lib.mkOption { type = lib.types.nullOr lib.types.path; default = null; };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.waybar ];
    system.activationScripts.waybar = lib.mkAfter ''
      mkdir -p ${userHome}/.config/waybar/scripts
      # Remove existing files/symlinks before creating new ones
      rm -f ${userHome}/.config/waybar/config
      rm -f ${userHome}/.config/waybar/style.css
      ${lib.optionalString (cfg.configPath != null) ''ln -sf ${cfg.configPath} ${userHome}/.config/waybar/config''}
      ${lib.optionalString (cfg.stylePath != null) ''ln -sf ${cfg.stylePath} ${userHome}/.config/waybar/style.css''}
      ${lib.optionalString (cfg.scriptsDir != null) ''cp -f ${cfg.scriptsDir}/* ${userHome}/.config/waybar/scripts/ 2>/dev/null || true''}
      chown -R ${userName}:${userGroup} ${userHome}/.config/waybar
    '';
  };
}


