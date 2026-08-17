{
  config,
  lib,
  pkgs,
  self,
  hyprland,
  ...
}: {
  imports = [
    hyprland.nixosModules.default
    ./hardware-configuration.nix
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
  hyprvibe.packages = {
    dev.enable = true;
    gaming.enable = true;
    extraPackages = with pkgs; [
      firefox
      brave
      chromium
      signal-desktop
      element-desktop
      libreoffice
      localsend
      mpv
      vlc
      ffmpeg-full
      imv
      yt-dlp
      ghostty
      yazi
      zoxide
      smartmontools
      lm_sensors
      pciutils
      usbutils
      libva-utils
      intel-gpu-tools
      powertop
      fwupd
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

  # Use the upstream kernel defaults on this older Intel laptop. Apply i915 or
  # C-state workarounds only if a reproducible fault is observed.
  hyprvibe.system.kernelPackages = pkgs.linuxPackages;
  powerManagement.cpuFreqGovernor = lib.mkForce "powersave";

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
    resolved.enable = true;
    thermald.enable = true;
    hardware.bolt.enable = true;
  };

  programs = {
    dconf.enable = true;
    firefox.enable = true;
    gamemode.enable = true;
    virt-manager.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };
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
