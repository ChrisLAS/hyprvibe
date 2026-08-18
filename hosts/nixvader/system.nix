{
  config,
  lib,
  pkgs,
  self,
  hyprland,
  ...
}:
let
  hermesDesktopNomad = pkgs.writeShellScriptBin "hermes-desktop-nomad" ''
    set -euo pipefail

    token_file="$HOME/.config/secrets/hermes_dashboard_session_token"
    if [ ! -r "$token_file" ]; then
      echo "Hermes Desktop remote token not found: $token_file" >&2
      exit 1
    fi

    token="$(${pkgs.gnused}/bin/sed -n '1 { s/^[^=]*=//; s/[[:space:]]*$//; p; }' "$token_file")"
    if [ -z "$token" ]; then
      echo "Hermes Desktop remote token is empty: $token_file" >&2
      exit 1
    fi

    export HERMES_DESKTOP_REMOTE_URL="http://nomad.coin-noodlefish.ts.net:9119"
    export HERMES_DESKTOP_REMOTE_TOKEN="$token"

    log_dir="$HOME/.cache/hermes-desktop-nomad"
    ${pkgs.coreutils}/bin/mkdir -p "$log_dir"
    log_file="$log_dir/launcher.log"

    {
      ${pkgs.coreutils}/bin/printf '\n[%s] launching Hermes Desktop (Nomad)\n' \
        "$(${pkgs.coreutils}/bin/date --iso-8601=seconds)"
      exec ${config.nix.package}/bin/nix run github:NousResearch/hermes-agent#desktop -- "$@"
    } >>"$log_file" 2>&1
  '';

  hermesDesktopNomadEntry = pkgs.makeDesktopItem {
    name = "hermes-desktop-nomad";
    desktopName = "Hermes Desktop (Nomad)";
    comment = "Launch Hermes Desktop connected to the Nomad remote backend";
    exec = lib.getExe hermesDesktopNomad;
    terminal = false;
    categories = [ "Utility" ];
    icon = "agentdesktop";
    type = "Application";
  };
in
{
  imports = [
    hyprland.nixosModules.default
    ./hardware-configuration.nix
    ./flatpak.nix
    ../../modules/shared
  ];

  hyprvibe.enable = true;
  hyprvibe.user = {
    name = "chrisf";
    group = "users";
    home = "/home/chrisf";
    description = "Chris Fisher";
  };

  hyprvibe.hyprland.monitorsFile = ./monitors.lua;
  hyprvibe.waybar = {
    configPath = ./waybar.json;
    stylePath = ./waybar.css;
  };
  hyprvibe.shell = {
    atuin.enable = true;
    githubToken.enable = true;
    kittyAsDefault = true;
    kittyIntegration.enable = true;
    kittyConfig.enable = true;
  };
  hyprvibe.opencode2Client.enable = true;
  hyprvibe.packages = {
    dev.enable = true;
    extraPackages = with pkgs; [
      firefox
      brave
      chromium
      google-chrome
      tor-browser
      signal-desktop
      element-desktop
      slack
      obsidian
      libreoffice
      evince
      xournalpp
      gnome-calculator
      localsend
      mpv
      vlc
      ffmpeg-full
      handbrake
      audacity
      kdePackages.kdenlive
      easyeffects
      qpwgraph
      drawing
      blanket
      fragments
      imv
      yt-dlp
      ghostty
      yazi
      zoxide
      restic
      autorestic
      restique
      trayscale
      hyprsunset
      hyprpicker
      mosh
      nixfmt
      zed-editor
      mise
      cargo
      clang
      llvm
      hugo
      xmlstarlet
      nextcloud-client
      maestral-gui
      rclone
      rclone-browser
      smartmontools
      lm_sensors
      pciutils
      usbutils
      libva-utils
      intel-gpu-tools
      powertop
      fwupd
      adwaita-icon-theme
      papirus-icon-theme
      hermesDesktopNomad
      hermesDesktopNomadEntry
      self.packages.${pkgs.stdenv.hostPlatform.system}.chatgpt-desktop
      kdePackages.dolphin
      kdePackages.ark
      kdePackages.kate
      kdePackages.kio-extras
      kdePackages.ffmpegthumbs
    ];
  };
  hyprvibe.services = {
    openssh.enable = true;
    tailscale.enable = true;
    virt.enable = true;
  };
  hyprvibe.power = {
    enable = true;
    autoSleepOnBatteryMinutes = 30;
  };

  # Disable the Intel display and deep-idle paths implicated in Latitude 7490 hard locks.
  # Keep the performance-oriented CPU governor because battery life is not the goal.
  hyprvibe.system.kernelPackages = pkgs.linuxPackages;
  boot.kernelParams = [
    "i915.enable_dc=0"
    "i915.enable_psr=0"
    "intel_idle.max_cstate=1"
  ];
  powerManagement.cpuFreqGovernor = lib.mkForce "performance";

  networking = {
    hostName = "nixvader";
    networkmanager.enable = true;
    networkmanager.dns = "systemd-resolved";
    firewall.enable = true;
  };
  systemd.services.NetworkManager-wait-online.enable = false;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  hardware = {
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [pkgs.intel-media-driver];
    };
  };
  services = {
    fwupd.enable = true;
    printing.enable = true;
    resolved.enable = true;
    thermald.enable = true;
    hardware.bolt.enable = true;
  };
  services.displayManager.defaultSession = "hyprland";

  qt = {
    enable = true;
    platformTheme = null;
    style = "adwaita-dark";
  };

  programs = {
    dconf.enable = true;
    firefox.enable = true;
    virt-manager.enable = true;
  };

  environment.sessionVariables = {
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    LIBVA_DRIVER_NAME = "iHD";
  };

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    registry.hyprvibe.flake = self;
    nixPath = ["nixpkgs=${pkgs.path}"];
  };
  nixpkgs.config.allowUnfree = true;

  system.configurationRevision = self.rev or "dirty";
  system.stateVersion = "26.05";
}
