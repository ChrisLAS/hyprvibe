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
    extraConfigs = lib.mkOption {
      type = with lib.types; listOf (submodule ({ ... }: {
        options = {
          source = lib.mkOption { type = lib.types.path; description = "Path to additional Waybar config variant"; };
          destName = lib.mkOption { type = lib.types.str; description = "Destination filename under ~/.config/waybar"; };
        };
      }));
      default = [];
      description = "Additional Waybar configs to install alongside main config";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.waybar ];
    system.activationScripts.waybar = lib.mkAfter ''
      set -euo pipefail
      trap 'echo "[hyprvibe][waybar] ERROR at line $LINENO"' ERR
      echo "[hyprvibe][waybar] starting activation"
      mkdir -p ${userHome}/.config/waybar/scripts
      # Remove existing files/symlinks before creating new ones
      rm -f ${userHome}/.config/waybar/config
      rm -f ${userHome}/.config/waybar/style.css
      ${lib.optionalString (cfg.configPath != null) ''ln -sf ${cfg.configPath} ${userHome}/.config/waybar/config''}
      ${lib.optionalString (cfg.stylePath != null) ''ln -sf ${cfg.stylePath} ${userHome}/.config/waybar/style.css''}
      ${lib.optionalString (cfg.scriptsDir != null) ''cp -f ${cfg.scriptsDir}/* ${userHome}/.config/waybar/scripts/ 2>/dev/null || true''}
      # Install extra config variants
      ${lib.concatStringsSep "\n" (map (c: ''
        ln -sf ${c.source} ${userHome}/.config/waybar/${c.destName}
      '') cfg.extraConfigs)}
      chown -R ${userName}:${userGroup} ${userHome}/.config/waybar
      echo "[hyprvibe][waybar] activation complete"
    '';
  };
}


