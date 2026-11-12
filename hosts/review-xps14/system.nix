{
  self,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./desktop.nix
    ../../modules/shared
  ];

  hyprvibe.enable = true;
  nixpkgs.config.allowUnfree = true;
  hyprvibe.user = {
    name = "chrisf";
    home = "/home/chrisf";
    description = "Chris Fisher";
  };
  users.users.chrisf = {
    uid = 1000;
    openssh.authorizedKeys.keys = import ./ssh-keys.nix;
    # Provisioned privately by the installer; never a Nix-store/Git secret.
    hashedPasswordFile = "/var/lib/review-xps14/login-password-hash";
  };
  users.users.root.hashedPassword = "!";
  services.openssh.settings = {
    PasswordAuthentication = true;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
  };

  networking = {
    hostName = "review-xps14";
    networkmanager.enable = true;
    # Preserve the provisioned Wi-Fi profile; no credentials in the flake.
    networkmanager.wifi.powersave = false;
    firewall.enable = true;
  };
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 8;
    efi.canTouchEfiVariables = true;
  };
  hyprvibe.system.kernelPackages = pkgs.linuxPackages_latest;
  # DA14260: CVS camera wake GPIO collides with all four audio amplifiers.
  # Preserve camera IRQ support without reserving the shared speaker-ID line.
  # Provenance and boot validation: HARDWARE-IMPROVEMENTS.md.
  boot.kernelPatches = [
    {
      name = "intel-cvs-shared-wake-gpio";
      patch = ./patches/intel-cvs-wake-irq.patch;
    }
  ];
  # Intel pstate's powersave governor still boosts; power-profiles-daemon
  # supplies balanced/performance/power-saver without pinning the review to
  # Nixvader's maximum-performance and disabled-deep-idle configuration.
  powerManagement.cpuFreqGovernor = lib.mkForce "powersave";
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.thermald.enable = true;
  services.fwupd.enable = true;
  services.hardware.bolt.enable = true;

  hardware = {
    graphics = {
      enable = true;
      # VA-API media plus Panther Lake OpenCL/Level Zero compute support.
      # Keep these coupled to the flake's tested Mesa/IGC versions.
      extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
        level-zero
      ];
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    ipu7 = {
      enable = true;
      platform = "ipu75xa";
    };
  };

  hyprvibe.shell = {
    atuin.enable = true;
    kittyAsDefault = true;
    kittyIntegration.enable = true;
    kittyConfig.enable = true;
    kittyConfig.fontSize = 13;
  };
  # A review client is not a clone of the permanent clients' fleet identity.
  hyprvibe.opencode.enable = lib.mkForce false;
  hyprvibe.opencode2Client.enable = true;
  # Remote client chdirs to the server project path before attaching.
  systemd.tmpfiles.rules = [ "d /home/chrisf/build/nomad-nixos 0755 chrisf users -" ];
  hyprvibe.hypruse.enable = false;
  hyprvibe.herdr.enable = false;
  hyprvibe.services.syncthing.enable = false;
  hyprvibe.services.nebula.enable = false;
  # Owner-approved enrollment for remote OpenCode and Hermes backends.
  services.tailscale.enable = true;

  # The broad base group also contains Jan and Google Cloud/GWS. Keep the
  # familiar desktop but omit unrelated heavyweight cloud/AI runtimes.
  hyprvibe.packages.base.enable = lib.mkForce false;
  environment.systemPackages =
    let
      hermesRemote = pkgs.callPackage ../../pkgs/hermes-desktop-nomad.nix { };
    in
    with pkgs;
    [
      hermes-desktop
      hermesRemote.wrapper
      hermesRemote.entry
      git
      gh
      curl
      wget
      jq
      ripgrep
      fd
      fzf
      bat
      eza
      tree
      file
      unzip
      zip
      btop
      htop
      lsof
      rsync
      restic
      python3
      nixfmt
      firefox
      chromium
      obsidian
      libreoffice
      slack
      telegram-desktop
      self.packages.${pkgs.stdenv.hostPlatform.system}.chatgpt-desktop
      kdePackages.dolphin
      kdePackages.ark
      kdePackages.kio-extras
      mpv
      vlc
      ffmpeg
      audacity
      imv
      localsend
      qalculate-gtk
      wlogout
      pciutils
      usbutils
      smartmontools
      lm_sensors
      powertop
      libva-utils
      intel-gpu-tools
      vulkan-tools
      clinfo
      v4l-utils
      alsa-utils
      adwaita-icon-theme
      papirus-icon-theme
    ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
      builders = lib.mkForce "";
      max-jobs = 2;
      cores = 6;
    };
    distributedBuilds = false;
    registry.nixpkgs.flake = self.inputs.nixpkgs;
  };
  system.stateVersion = "26.11";
}
