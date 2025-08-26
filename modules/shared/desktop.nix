{ lib, pkgs, config, ... }:
let cfg = config.shared.desktop;
in {
  options.shared.desktop = {
    enable = lib.mkEnableOption "Shared desktop (Wayland env, portals, fonts, GTK/Qt)";
  };

  config = lib.mkIf cfg.enable {
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      GDK_BACKEND = "wayland";
    };

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = [ "hyprland" "gtk" ];
    };
  };
}


