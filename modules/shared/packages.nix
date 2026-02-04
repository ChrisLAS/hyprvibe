{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.hyprvibe.packages;
  janWrappedLower = pkgs.writeShellScriptBin "jan" ''
    export LD_LIBRARY_PATH=${pkgs.openssl}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    exec ${pkgs.jan}/bin/Jan "$@"
  '';
  janWrappedUpper = pkgs.writeShellScriptBin "Jan" ''
    export LD_LIBRARY_PATH=${pkgs.openssl}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    exec ${pkgs.jan}/bin/Jan "$@"
  '';
  # Curated common sets derived from overlaps across hosts
  basePackages = with pkgs; [
    htop
    btop
    tree
    lsof
    lshw
    neofetch
    nmap
    zip
    unzip
    gnupg
    curl
    file
    jq
    bat
    fd
    fzf
    ripgrep
    tldr
    whois
    plocate
    less
    eza
    grc
    cursor-cli
    tmate
    # Jan desktop/CLI (wrapped to ensure compatible OpenSSL libcrypto)
    janWrappedLower
    janWrappedUpper
  ];
  desktopPackages = with pkgs; [
    wl-clipboard
    grim
    slurp
    swappy
    wf-recorder
    dunst
    cliphist
    brightnessctl
    playerctl
    pavucontrol
    # qt6ct  # Temporarily disabled - pulls in qgnomeplatform which has build failure in current nixpkgs
    # Core desktop apps
    kitty
    vicinae
    bibata-cursors
    # Hyprland companions started by base config
    hyprpaper
    hypridle
    hyprlock
  ];
  devPackages = with pkgs; [
    git
    gh
    gitui
    gcc
    gnumake
    cmake
    binutils
    patchelf
    python3
    go
    nodejs_22
    yarn
    imagemagick
    beads
  ];
  gamingPackages = with pkgs; [
    steam-run
    lutris
    moonlight-qt
    sunshine
    vulkan-tools
  ];
in
{
  options.hyprvibe.packages = {
    enable = lib.mkEnableOption "Shared package groups";
    base.enable = lib.mkEnableOption "Common CLI utilities";
    desktop.enable = lib.mkEnableOption "Desktop helpers for Wayland sessions";
    dev.enable = lib.mkEnableOption "Developer toolchain";
    gaming.enable = lib.mkEnableOption "Gaming helpers";
    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
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
