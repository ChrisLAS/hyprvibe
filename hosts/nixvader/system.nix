{
  config,
  lib,
  pkgs,
  self,
  hyprland,
  ...
}: let
  # Remote-only Hermes Desktop launcher + .desktop entry. Shared helper at
  # pkgs/hermes-desktop-nomad.nix; same as nixstation (see hosts/nixstation/system.nix).
  hermesDesktopRemoteHelper = pkgs.callPackage ../../pkgs/hermes-desktop-nomad.nix {
    hermes-desktop = pkgs.hermes-desktop;
  };
  hermesDesktopRemote = hermesDesktopRemoteHelper.wrapper;
  hermesDesktopRemoteEntry = hermesDesktopRemoteHelper.entry;
in {
  imports = [
    hyprland.nixosModules.default
    ./hardware-configuration.nix
    ./flatpak.nix
    ./theme.nix
    ./dms.nix
    ../../modules/shared
    ../../modules/colony-builder-client.nix
  ];

  hyprvibe.enable = true;
  programs.syncshell-dms.enable = true;
  hyprvibe.user = {
    name = "chrisf";
    group = "users";
    home = "/home/chrisf";
    description = "Chris Fisher";
  };

  hyprvibe.hyprland.monitorsFile = ./monitors.lua;
  hyprvibe.hyprland.wallpaper = "/home/chrisf/Pictures/bkgrounds/vaderhole.jpg";
  hyprvibe.hyprland.shellBackend = "dms";
  hyprvibe.hyprland.enable = true;
  # Pin the ScreenCast portal backend to Hyprland so screen-sharing tools
  # (OBS, Discord, etc.) prefer it over the GTK fallback.
  xdg.portal.config.common."org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
  # Keep MPV as the declarative default for video files while VLC remains
  # installed as an alternate player.
  xdg.mime.defaultApplications = {
    "video/*" = "mpv.desktop";
    "text/calendar" = "com.danklinux.dankcalendar.desktop";
    "x-scheme-handler/calendar" = "com.danklinux.dankcalendar.desktop";
    "x-scheme-handler/webcal" = "com.danklinux.dankcalendar.desktop";
    "x-scheme-handler/webcals" = "com.danklinux.dankcalendar.desktop";
  };
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
  hyprvibe.hypruse.enable = true;
  hyprvibe.herdr = {
    enable = true;
    ghostty.primaryFont = "DejaVu Sans Mono";
  };
  hyprvibe.packages = {
    dunst.enable = false;
    dev.enable = true;
    extraPackages = with pkgs; [
      codex
      codexbar
      firefox
      brave
      chromium
      telegram-desktop
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
      avidemux
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
      codex
      wallust
      wlogout
      swappy
      qalculate-gtk
      swaynotificationcenter
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
      hyprpaper
      hypridle
      hyprlock
      hyprsunset
      hyprshot
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
      hermesDesktopRemote
      hermesDesktopRemoteEntry
      hermes-desktop
      self.packages.${pkgs.stdenv.hostPlatform.system}.codexbar
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
  hyprvibe.system.kernelPackages = pkgs.linuxPackages_zen;
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
    # This trusted client host intentionally does not use the NixOS firewall.
    firewall.enable = false;
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
    syncthing = {
      enable = true;
      user = "chrisf";
      group = "users";
      dataDir = "/home/chrisf";
      configDir = "/home/chrisf/.config/syncthing";
      openDefaultPorts = true;
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = {
          aurora.id = "4CD2OSH-B6OBHJ2-3LZS3NI-LFYCVLQ-POGG2SS-LNEKDXA-RBG5ZKS-X3UJ3QK";
          nixstation.id = "KHJYIB5-L5LK6TE-G5BCAXD-UKTVWYU-GX4YG7T-QEXMBWO-YIJ4B5Y-JG24VQ6";
          nomad.id = "HUAZMND-Q4QYPQQ-UEYHN3N-I72DZCR-DTOPZUY-N2KE5WT-FTKTA5Z-YPICHQ7";
          showfactory.id = "6VWD4YN-ONN7JJE-5ZUX2KT-RHABTOM-3WTOETG-JAQFNEC-VMAKH6R-KW3X3A3";
        };
        folders = {
          "50-heremes" = {
            id = "50-heremes";
            label = "50 Heremes";
            path = "/home/chrisf/syncthing/50-Heremes";
            type = "sendreceive";
            devices = ["aurora" "nixstation" "nomad" "showfactory"];
          };
        };
        options.urAccepted = -1;
      };
    };
    thermald.enable = true;
    upower.enable = true;
    hardware.bolt.enable = true;
  };
  systemd.tmpfiles.rules = [
    "d /home/chrisf/syncthing 0750 chrisf users -"
    "d /home/chrisf/syncthing/50-Heremes 0750 chrisf users -"
  ];
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
    thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
      ];
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
  time.timeZone = "America/Los_Angeles";

  # Automatic boot-time updates from Hyprvibe main, no auto-reboot.
  system.autoUpgrade = {
    enable = true;
    operation = "boot";
    randomizedDelaySec = "45min";
    allowReboot = false;
    dates = "02:00";
  };
  # Performance-oriented VM tuning; never auto-reboot on panic.
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 10;
    "kernel.panic" = 0;
  };
  system.configurationRevision = self.rev or "dirty";
  system.stateVersion = "26.05";
}
