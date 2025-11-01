{ lib, pkgs, config, ... }:
let
  cfg = config.hyprvibe.hyprland;
  user = config.hyprvibe.user;
  userHome = user.home;
  userName = user.name;
  userGroup = user.group;
in {
  options.hyprvibe.hyprland = {
    enable = lib.mkEnableOption "Hyprland base setup";
    waybar.enable = lib.mkEnableOption "Waybar autostart integration";
    monitorsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Per-host Hyprland monitors config file path";
    };
    mainConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to host's hyprland.conf";
    };
    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Wallpaper file path for hyprpaper/hyprlock generation";
    };
    hyprpaperTemplate = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Template hyprpaper.conf with __WALLPAPER__ placeholder";
    };
    hyprlockTemplate = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Template hyprlock.conf with __WALLPAPER__ placeholder";
    };
    hypridleConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to hypridle.conf to install";
    };
    scriptsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Directory of Hyprland helper scripts to copy and chmod +x";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Install base config; host supplies additional configs via options
    system.activationScripts.hyprlandBase = lib.mkAfter ''
      mkdir -p ${userHome}/.config/hypr
      # Remove existing symlinks/files if they exist
      rm -f ${userHome}/.config/hypr/hyprland-base.conf
      ln -sf ${../../configs/hyprland-base.conf} ${userHome}/.config/hypr/hyprland-base.conf
      ${lib.optionalString (cfg.monitorsFile != null) ''
        rm -f ${userHome}/.config/hypr/$(basename ${cfg.monitorsFile})
        ln -sf ${cfg.monitorsFile} ${userHome}/.config/hypr/$(basename ${cfg.monitorsFile})
      ''}
      ${lib.optionalString (cfg.mainConfig != null) ''
        rm -f ${userHome}/.config/hypr/hyprland.conf
        ln -sf ${cfg.mainConfig} ${userHome}/.config/hypr/hyprland.conf
      ''}
      ${lib.optionalString (cfg.hyprpaperTemplate != null && cfg.wallpaper != null) ''
        ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#${cfg.wallpaper}#g" ${cfg.hyprpaperTemplate} > ${userHome}/.config/hypr/hyprpaper.conf
      ''}
      ${lib.optionalString (cfg.hyprlockTemplate != null && cfg.wallpaper != null) ''
        ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#${cfg.wallpaper}#g" ${cfg.hyprlockTemplate} > ${userHome}/.config/hypr/hyprlock.conf
      ''}
      ${lib.optionalString (cfg.hypridleConfig != null) ''
        rm -f ${userHome}/.config/hypr/hypridle.conf
        ln -sf ${cfg.hypridleConfig} ${userHome}/.config/hypr/hypridle.conf
      ''}
      ${lib.optionalString (cfg.scriptsDir != null) ''
        mkdir -p ${userHome}/.config/hypr/scripts
        cp -f ${cfg.scriptsDir}/*.sh ${userHome}/.config/hypr/scripts/ 2>/dev/null || true
        chmod +x ${userHome}/.config/hypr/scripts/*.sh 2>/dev/null || true
      ''}
      chown -R ${userName}:${userGroup} ${userHome}/.config/hypr
    '';
  };
}


