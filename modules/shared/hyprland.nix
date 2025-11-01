{ lib, pkgs, config, ... }:
let
  cfg = config.hyprvibe.hyprland;
  user = config.hyprvibe.user;
  userHome = user.home;
  userName = user.name;
  userGroup = user.group;
  defaultMain = ../../configs/hyprland-default.conf;
  defaultPaper = ../../configs/hyprpaper-default.conf;
  defaultLock = ../../configs/hyprlock-default.conf;
  defaultIdle = ../../configs/hypridle-default.conf;
  defaultWallpaper = ../../wallpapers/aishot-2602.jpg;
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

    # Install base config; fall back to shared defaults where host options are not provided
    system.activationScripts.hyprlandBase = lib.mkAfter ''
      mkdir -p ${userHome}/.config/hypr
      # Remove existing symlinks/files if they exist
      rm -f ${userHome}/.config/hypr/hyprland-base.conf
      ln -sf ${../../configs/hyprland-base.conf} ${userHome}/.config/hypr/hyprland-base.conf
      ${lib.optionalString (cfg.monitorsFile != null) ''
        rm -f ${userHome}/.config/hypr/$(basename ${cfg.monitorsFile})
        ln -sf ${cfg.monitorsFile} ${userHome}/.config/hypr/$(basename ${cfg.monitorsFile})
      ''}
      # Main config
      rm -f ${userHome}/.config/hypr/hyprland.conf
      ln -sf ${lib.optionalString (cfg.mainConfig != null) cfg.mainConfig or defaultMain} ${userHome}/.config/hypr/hyprland.conf
      # Wallpaper-backed configs
      ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#${lib.optionalString (cfg.wallpaper != null) cfg.wallpaper or defaultWallpaper}#g" ${lib.optionalString (cfg.hyprpaperTemplate != null) cfg.hyprpaperTemplate or defaultPaper} > ${userHome}/.config/hypr/hyprpaper.conf
      ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#${lib.optionalString (cfg.wallpaper != null) cfg.wallpaper or defaultWallpaper}#g" ${lib.optionalString (cfg.hyprlockTemplate != null) cfg.hyprlockTemplate or defaultLock} > ${userHome}/.config/hypr/hyprlock.conf
      # Idle config
      rm -f ${userHome}/.config/hypr/hypridle.conf
      ln -sf ${lib.optionalString (cfg.hypridleConfig != null) cfg.hypridleConfig or defaultIdle} ${userHome}/.config/hypr/hypridle.conf
      ${lib.optionalString (cfg.scriptsDir != null) ''
        mkdir -p ${userHome}/.config/hypr/scripts
        cp -f ${cfg.scriptsDir}/*.sh ${userHome}/.config/hypr/scripts/ 2>/dev/null || true
        chmod +x ${userHome}/.config/hypr/scripts/*.sh 2>/dev/null || true
      ''}
      chown -R ${userName}:${userGroup} ${userHome}/.config/hypr
    '';
  };
}


