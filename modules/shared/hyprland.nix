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
    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Wallpaper file path for hyprpaper/hyprlock generation";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Install base config; host supplies monitor file separately
    system.activationScripts.hyprlandBase = lib.mkAfter ''
      mkdir -p ${userHome}/.config/hypr
      # Remove existing symlinks/files if they exist
      rm -f ${userHome}/.config/hypr/hyprland-base.conf
      ln -sf ${../../configs/hyprland-base.conf} ${userHome}/.config/hypr/hyprland-base.conf
      ${lib.optionalString (cfg.monitorsFile != null) ''
        rm -f ${userHome}/.config/hypr/$(basename ${cfg.monitorsFile})
        ln -sf ${cfg.monitorsFile} ${userHome}/.config/hypr/$(basename ${cfg.monitorsFile})
      ''}
      chown -R ${userName}:${userGroup} ${userHome}/.config/hypr
    '';
  };
}


