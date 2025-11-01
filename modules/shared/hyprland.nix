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
    amd.enable = lib.mkEnableOption "Enable AMD-specific OpenGL/Vulkan env overrides";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Install base config; fall back to shared defaults where host options are not provided
    system.activationScripts.hyprlandBase = lib.mkAfter ''
      set -euo pipefail
      trap 'echo "[hyprvibe][hyprland] ERROR at line $LINENO"' ERR
      echo "[hyprvibe][hyprland] starting activation"
      mkdir -p ${userHome}/.config/hypr
      # Remove existing symlinks/files if they exist
      rm -f ${userHome}/.config/hypr/hyprland-base.conf
      ln -sf ${../../configs/hyprland-base.conf} ${userHome}/.config/hypr/hyprland-base.conf
      echo "[hyprvibe][hyprland] linked base config -> ${userHome}/.config/hypr/hyprland-base.conf"
      ${lib.optionalString (cfg.monitorsFile != null) ''
        rm -f ${userHome}/.config/hypr/$(basename ${cfg.monitorsFile})
        ln -sf ${cfg.monitorsFile} ${userHome}/.config/hypr/$(basename ${cfg.monitorsFile})
        echo "[hyprvibe][hyprland] linked monitors -> ${userHome}/.config/hypr/$(basename ${cfg.monitorsFile})"
      ''}
      # Main config
      rm -f ${userHome}/.config/hypr/hyprland.conf
      ln -sf ${if cfg.mainConfig != null then cfg.mainConfig else defaultMain} ${userHome}/.config/hypr/hyprland.conf
      echo "[hyprvibe][hyprland] linked main -> ${userHome}/.config/hypr/hyprland.conf"
      # Wallpaper-backed configs
      ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#${if cfg.wallpaper != null then cfg.wallpaper else defaultWallpaper}#g" ${if cfg.hyprpaperTemplate != null then cfg.hyprpaperTemplate else defaultPaper} > ${userHome}/.config/hypr/hyprpaper.conf
      echo "[hyprvibe][hyprland] rendered hyprpaper.conf"
      ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#${if cfg.wallpaper != null then cfg.wallpaper else defaultWallpaper}#g" ${if cfg.hyprlockTemplate != null then cfg.hyprlockTemplate else defaultLock} > ${userHome}/.config/hypr/hyprlock.conf
      echo "[hyprvibe][hyprland] rendered hyprlock.conf"
      # Idle config
      rm -f ${userHome}/.config/hypr/hypridle.conf
      ln -sf ${if cfg.hypridleConfig != null then cfg.hypridleConfig else defaultIdle} ${userHome}/.config/hypr/hypridle.conf
      # Local overrides file (always present; may be empty)
      : > ${userHome}/.config/hypr/hyprland-local.conf
      ${lib.optionalString cfg.amd.enable ''
        cat > ${userHome}/.config/hypr/hyprland-local.conf << 'EOF'
        # AMD-specific overrides (opt-in)
        env = AMD_VULKAN_ICD,RADV
        env = MESA_LOADER_DRIVER_OVERRIDE,radeonsi
        EOF
        echo "[hyprvibe][hyprland] wrote AMD env overrides to hyprland-local.conf"
      ''}
      echo "[hyprvibe][hyprland] linked hypridle.conf"
      ${lib.optionalString (cfg.scriptsDir != null) ''
        mkdir -p ${userHome}/.config/hypr/scripts
        cp -f ${cfg.scriptsDir}/*.sh ${userHome}/.config/hypr/scripts/ 2>/dev/null || true
        chmod +x ${userHome}/.config/hypr/scripts/*.sh 2>/dev/null || true
        echo "[hyprvibe][hyprland] installed scripts from ${cfg.scriptsDir}"
      ''}
      chown -R ${userName}:${userGroup} ${userHome}/.config/hypr
      echo "[hyprvibe][hyprland] ownership fixed; activation complete"
    '';
  };
}


