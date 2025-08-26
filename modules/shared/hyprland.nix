{ lib, pkgs, config, ... }:
let cfg = config.shared.hyprland;
in {
  options.shared.hyprland = {
    enable = lib.mkEnableOption "Hyprland base setup";
    waybar.enable = lib.mkEnableOption "Waybar autostart integration";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Install base config; host supplies monitor file separately
    system.activationScripts.hyprlandBase = lib.mkAfter ''
      mkdir -p /home/chrisf/.config/hypr
      cp ${../../configs/hyprland-base.conf} /home/chrisf/.config/hypr/hyprland-base.conf
      chown -R chrisf:users /home/chrisf/.config/hypr
    '';
  };
}


