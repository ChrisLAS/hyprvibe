{ lib, pkgs, config, ... }:
let cfg = config.shared.hyprland;
in {
  options.shared.hyprland = {
    enable = lib.mkEnableOption "Hyprland base setup";
    waybar.enable = lib.mkEnableOption "Waybar autostart integration";
    monitorsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Per-host Hyprland monitors config file path";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Install base config; host supplies monitor file separately
    system.activationScripts.hyprlandBase = lib.mkAfter ''
      mkdir -p /home/chrisf/.config/hypr
      # Remove existing symlinks/files if they exist
      rm -f /home/chrisf/.config/hypr/hyprland-base.conf
      ln -sf ${../../configs/hyprland-base.conf} /home/chrisf/.config/hypr/hyprland-base.conf
      ${lib.optionalString (cfg.monitorsFile != null) ''
        rm -f /home/chrisf/.config/hypr/$(basename ${cfg.monitorsFile})
        ln -sf ${cfg.monitorsFile} /home/chrisf/.config/hypr/$(basename ${cfg.monitorsFile})
      ''}
      chown -R chrisf:users /home/chrisf/.config/hypr
    '';
  };
}


