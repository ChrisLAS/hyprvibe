{ lib, pkgs, config, ... }:
let cfg = config.shared.desktop;
in {
  options.shared.desktop = {
    enable = lib.mkEnableOption "Shared desktop (Wayland env, portals, fonts, GTK/Qt)";
    fonts.enable = lib.mkEnableOption "Install recommended Nerd/base fonts";
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

    fonts.packages = lib.mkIf cfg.fonts.enable (
      with pkgs; [
        fira-code
        fira-code-symbols
        nerd-fonts.fira-code
        nerd-fonts.hack
        nerd-fonts.ubuntu
        noto-fonts
        noto-fonts-emoji
        noto-fonts-color-emoji
        ubuntu_font_family
        liberation_ttf
      ]
    );
  };
}


