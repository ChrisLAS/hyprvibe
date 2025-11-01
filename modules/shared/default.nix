{ lib, config, ... }:
let
  cfg = config.hyprvibe;
in {
  options.hyprvibe.enable = lib.mkEnableOption "Enable the base Hyprvibe desktop experience";

  imports = [
    ./packages.nix
    ./desktop.nix
    ./hyprland.nix
    ./waybar.nix
    ./shell.nix
    ./services.nix
    ./system.nix
    ./user.nix
  ];

  config = lib.mkIf cfg.enable {
    # Base common experience across hosts
    documentation.man.enable = false;
    hyprvibe.desktop = {
      enable = true;
      fonts.enable = true;
    };
    hyprvibe.hyprland.enable = true;
    hyprvibe.waybar.enable = true;
    hyprvibe.shell.enable = true;
    hyprvibe.services = {
      enable = true;
      openssh.enable = true;
    };
    hyprvibe.system.enable = true;
    hyprvibe.packages = {
      enable = true;
      base.enable = true;
      desktop.enable = true;
    };
  };
}


