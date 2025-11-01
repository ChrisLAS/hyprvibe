{ lib, pkgs, config, ... }:
let
  cfg = config.hyprvibe.packages;
  # Curated common sets derived from overlaps across hosts
  rofiPkg = if pkgs ? rofi-wayland then pkgs.rofi-wayland
            else if pkgs ? rofi-wayland-unwrapped then pkgs.rofi-wayland-unwrapped
            else pkgs.rofi;
  basePackages = with pkgs; [
    htop btop tree lsof lshw neofetch nmap zip unzip gnupg curl file jq bat fd fzf ripgrep tldr
    whois plocate less eza grc
  ];
  desktopPackages =
    (with pkgs; [
      wl-clipboard grim slurp swappy wf-recorder dunst cliphist brightnessctl playerctl pavucontrol
      qt6Packages.qt6ct
      # Core desktop apps
      kitty
      # Hyprland companions started by base config
      hyprpaper hypridle hyprlock
    ]) ++ [ rofiPkg ];
  devPackages = with pkgs; [
    git gh gitui gcc gnumake cmake binutils patchelf python3 go nodejs_20 yarn imagemagick
  ];
  gamingPackages = with pkgs; [
    steam-run lutris moonlight-qt sunshine vulkan-tools
  ];
in {
  options.hyprvibe.packages = {
    enable = lib.mkEnableOption "Shared package groups";
    base.enable = lib.mkEnableOption "Common CLI utilities";
    desktop.enable = lib.mkEnableOption "Desktop helpers for Wayland sessions";
    dev.enable = lib.mkEnableOption "Developer toolchain";
    gaming.enable = lib.mkEnableOption "Gaming helpers";
    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = "Additional packages to append to shared packages.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      (lib.optionals cfg.base.enable basePackages)
      ++ (lib.optionals cfg.desktop.enable desktopPackages)
      ++ (lib.optionals cfg.dev.enable devPackages)
      ++ (lib.optionals cfg.gaming.enable gamingPackages)
      ++ cfg.extraPackages;
  };
}


