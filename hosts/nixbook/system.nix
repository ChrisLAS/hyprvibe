{
  config,
  pkgs,
  hyprland,
  ...
}:

let
  # Hyprvibe user options (from modules/shared/user.nix)
  userName = config.hyprvibe.user.name;
  userGroup = config.hyprvibe.user.group;
  homeDir = config.hyprvibe.user.home;
  # Package groups
  devTools = with pkgs; [
    git
    gcc
    cmake
    python3
    go
    gh
    gitui
    patchelf
    binutils
    nixfmt
    zed-editor
    opencode
    # Additional development tools from Omarchy
    cargo
    clang
    llvm
    mise
    imagemagick
    mariadb
    postgresql
    github-cli
    lazygit
    kitty
    lazydocker
  ];

  multimedia = with pkgs; [
    mpv
    vlc
    ffmpeg-full
    # haruna
    reaper
    (pkgs.writeShellScriptBin "reaper-x11" ''
      # Ensure an X11 DISPLAY is set; avoid Nix interpolation issues
      if [ -z "$DISPLAY" ]; then
        export DISPLAY=:0
      fi
      exec env -u WAYLAND_DISPLAY -u QT_QPA_PLATFORM -u GDK_BACKEND -u XDG_SESSION_TYPE \
        QT_QPA_PLATFORM=xcb \
        GDK_BACKEND=x11 \
        XDG_SESSION_TYPE=x11 \
        reaper -newinst "$@"
    '')
    (pkgs.makeDesktopItem {
      name = "reaper-x11";
      desktopName = "REAPER (X11)";
      comment = "Launch REAPER using X11/XWayland for Wayland compositors";
      exec = "reaper-x11 %F";
      terminal = false;
      categories = [
        "AudioVideo"
        "Audio"
        "Midi"
      ];
      icon = "reaper";
      type = "Application";
    })
    lame
    # carla
    qjackctl
    qpwgraph
    # sonobus
    # krita
    x32edit
    # pwvucontrol
    easyeffects
    wayfarer
    # OBS configured via programs.obs-studio with plugins
    # obs-studio-plugins.waveform
    libepoxy
    audacity
    # Additional multimedia tools from Omarchy
    # yabridge
    # yabridgectl
    lsp-plugins
    ffmpegthumbnailer
    gnome.gvfs
    imv
  ];

  utilities = with pkgs; [
    ghostty
    htop
    btop
    fastfetch
    socat
    nmap
    mosh
    yt-dlp
    zip
    unzip
    gnupg
    restic
    autorestic
    restique
    cool-retro-term
    #    ventoy
    hddtemp
    smartmontools
    iotop
    lm_sensors
    tree
    lsof
    lshw
    # rustdesk-flutter
    tor-browser
    # lmstudio
    # vdhcoapp - removed: VDH >= 10 doesn't require companion app and repo is archived
    ulauncher
    #    python312Packages.todoist-api-python
    wmctrl
    # Hyprland utilities
    waybar
    wl-clipboard
    grim
    slurp
    swappy
    wf-recorder
    wlroots
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    desktop-file-utils
    kdePackages.polkit-kde-agent-1
    qt6.qtbase
    qt6.qtwayland
    # Additional Hyprland utilities
    wofi
    cliphist
    brightnessctl
    playerctl
    kdePackages.kwallet
    kdePackages.kwallet-pam
    kdePackages.kate
    # Additional terminal utilities from Omarchy
    fd
    eza
    fzf
    ripgrep
    zoxide
    bat
    jq
    xmlstarlet
    tldr
    plocate
    # man  # removed since manpages are disabled
    less
    whois
    bash-completion
    # Additional desktop utilities from Omarchy
    pamixer
    wiremix
    fcitx5
    fcitx5-gtk
    kdePackages.fcitx5-qt
    nautilus
    sushi
    # Additional Hyprland utilities from Omarchy
    # polkit_gnome  # removed to avoid duplicate agents; using KDE polkit agent
    libqalculate
    swaybg
    swayosd
    qt6Packages.qt6ct
    pavucontrol
    networkmanagerapplet
    # Shell history replacement
    atuin
    oh-my-posh
    ddcutil
    curl
    v4l-utils
    openssh
    glib-networking
    rclone
    android-tools
  ];

  systemTools = with pkgs; [
    btrfs-progs
    btrfs-snap
    pciutils
    cifs-utils
    samba
    fuse
    fuse3
    docker-compose
  ];

  applications = with pkgs; [
    firefox
    brave
    google-chrome
    slack
    # telegram-desktop (moved to Flatpak)
    element-desktop
    nextcloud-client
    trayscale
    maestral-gui
    qownnotes
    libation
    audible-cli
    # Additional applications from Omarchy
    chromium
    gnome-calculator
    gnome-keyring
    signal-desktop
    libreoffice
    kdePackages.kdenlive
    xournalpp
    localsend
    # Note: Some packages like pinta, typora, spotify, zoom may need to be installed via other means
    # or may have different names in Nix
    _1password-gui
    _1password-cli
    hyprpicker
    hyprshot
    wl-clip-persist
    hyprpaper
    hypridle
    hyprlock
    hyprsunset
    yazi
    starship
    # zoxide  # deduped; present in utilities
    rclone-browser
    code-cursor
    cursor-cli

  ];

  gaming = with pkgs; [
    # steam - now managed by programs.steam
    steam-run
    moonlight-qt
    # sunshine  # Temporarily disabled - build fails fetching Boost dependencies
    adwaita-icon-theme
    # lutris
    # playonlinux
    # wineWowPackages.staging
    # winetricks
    vulkan-tools
  ];

  # GTK applications (replacing GNOME apps)
  gtkApps = with pkgs; [
    # File manager
    kdePackages.dolphin
    kdePackages.kio-extras
    kdePackages.kio-fuse
    kdePackages.kio-admin
    kdePackages.kdenetwork-filesharing
    kdePackages.ffmpegthumbs
    kdePackages.kdegraphics-thumbnailers
    kdePackages.kimageformats
    kdePackages.ark
    kdePackages.konsole
    # Also include Thunar alongside Dolphin
    thunar
    tumbler
    gvfs
    # Theming packages
    tokyonight-gtk-theme
    papirus-icon-theme
    bibata-cursors
    # Document viewer
    evince
    # Image viewer
    eog
    # Calculator
    gnome-calculator
    # Archive manager
    file-roller
    # Video player
    celluloid
    # Torrent client
    fragments
    # Ebook reader (moved to Flatpak)
    # Background sounds
    blanket
    # Translation app (moved to Flatpak)
    # Drawing app
    drawing
  ];
  # Centralized wallpaper path used by hyprpaper and hyprlock (standardized repo path)
  wallpaperPath = ../../wallpapers/aishot-2602.jpg;

  # Script to import GITHUB_TOKEN into systemd --user environment
  setGithubTokenScript = pkgs.writeShellScript "set-github-token" ''
    if [ -r "$HOME/.config/secrets/github_token" ]; then
      value="$(tr -d '\n' < "$HOME/.config/secrets/github_token")"
      systemctl --user set-environment GITHUB_TOKEN="$value"
    fi
  '';
  # Script to setup OpenCode configuration with OpenRouter defaults
  setupOpencodeConfigScript = pkgs.writeShellScript "setup-opencode-config" ''
    set -euo pipefail
    mkdir -p ${homeDir}/.config/opencode
    cat > ${homeDir}/.config/opencode/opencode.json << 'EOF'
    {
      "$schema": "https://opencode.ai/config.json",
      "model": "anthropic/claude-sonnet-4.5",
      "autoupdate": true,
      "theme": "opencode"
    }
    EOF
    chown ${userName}:${userGroup} ${homeDir}/.config/opencode/opencode.json
  '';
in
{
  imports = [
    # Import the Hyprland flake module
    hyprland.nixosModules.default
    # Import your hardware configuration
    ./hardware-configuration.nix
    # Shared scaffolding (non-host-specific)
    ../../modules/shared
  ];

  # Enable shared module toggles
  hyprvibe.desktop = {
    enable = true;
    fonts.enable = true;
  };
  hyprvibe.hyprland.enable = true;
  # Provide per-host monitors and wallpaper paths to shared module
  hyprvibe.hyprland.monitorsFile = ../../configs/hyprland-monitors-nixbook.conf;
  hyprvibe.hyprland.mainConfig = ./hyprland.conf;
  hyprvibe.hyprland.wallpaper = wallpaperPath;
  hyprvibe.hyprland.hyprpaperTemplate = ./hyprpaper.conf;
  hyprvibe.hyprland.hyprlockTemplate = ./hyprlock.conf;
  hyprvibe.hyprland.hypridleConfig = ./hypridle.conf;
  hyprvibe.hyprland.scriptsDir = ./scripts;
  # Intel GPU - no AMD-specific configuration needed
  hyprvibe.waybar.enable = true;
  hyprvibe.waybar.configPath = ./waybar.json;
  hyprvibe.waybar.stylePath = ./waybar.css;
  hyprvibe.waybar.scriptsDir = ./scripts;
  hyprvibe.system.enable = true;
  # Power management: Performance-biased with manual low-power mode
  hyprvibe.power = {
    enable = true;
    autoSleepOnBatteryMinutes = 30;
    performanceMode = {
      cpuGovernor = "performance";
      wifiPowerSave = false;
      diskPowerSave = false;
    };
    powerSaverMode = {
      cpuGovernor = "powersave";
      wifiPowerSave = true;
      diskPowerSave = true;
    };
  };
  # Kernel selection: Try Zen kernel for better desktop performance
  # Previous issues with Zen 6.18, but newer versions (6.12+) are more stable
  # Fallback options: pkgs.linuxPackages (regular), pkgs.linuxPackages_latest, pkgs.linuxPackages_6_1
  # If Zen causes issues, change to: pkgs.linuxPackages_latest
  hyprvibe.system.kernelPackages = pkgs.linuxPackages_zen;
  hyprvibe.shell = {
    enable = true;
    kittyAsDefault = true;
    atuin.enable = true;
    githubToken.enable = true;
    kittyIntegration.enable = true;
    kittyConfig.enable = true;
  };
  # Explicit shared user options including host-specific groups
  hyprvibe.user = {
    name = "chrisf";
    group = "users";
    home = "/home/chrisf";
    description = "Chris Fisher";
    extraGroups = [ "plugdev" ];
  };

  # Define custom groups referenced by udev rules
  users.groups.plugdev = { };
  # Services configuration
  hyprvibe.services = {
    enable = true; # Enable baseline services (pipewire, flatpak, polkit, etc.)
    tailscale.enable = true; # Enable Tailscale via shared module (configures useRoutingFeatures = "both")
    virt.enable = true;
    docker.enable = true;
    nebula = {
      enable = true;
      nebulaIp = "192.168.100.12/24";
    };
  };

  # Add Flathub remote system-wide if it doesn't exist (Flatpak is enabled via hyprvibe.services)
  system.activationScripts.addFlathubRemote = ''
    if ! ${pkgs.flatpak}/bin/flatpak remote-list --system 2>/dev/null | grep -q "^flathub"; then
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    fi
  '';

  # Declaratively install Flatpak applications
  system.activationScripts.installFlatpaks = ''
    # Ensure Flathub remote exists before installing packages
    if ! ${pkgs.flatpak}/bin/flatpak remote-list --system 2>/dev/null | grep -q "^flathub"; then
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    fi

    # Update Flathub remote to ensure we have latest package information
    ${pkgs.flatpak}/bin/flatpak update --appstream --system flathub 2>/dev/null || true

    # List of flatpak applications to install
    FLATPAKS=(
      # "flathub:com.usebottles.bottles"  # Wine prefix manager - commented out with Wine removal
      "flathub:org.telegram.desktop"
      "flathub:org.kde.haruna"
      "flathub:com.github.tchx84.Flatseal"
      "flathub:md.obsidian.Obsidian"
      "flathub:app.zen_browser.zen"
      "flathub:com.github.wwmm.easyeffects"
      "flathub:com.rustdesk.RustDesk"
      "flathub:org.flameshot.Flameshot"
      "flathub:org.filezillaproject.Filezilla"
      "flathub:com.slack.Slack"
      "flathub:org.gnome.baobab"
      "flathub:com.transmissionbt.Transmission"
      "flathub:io.github.giantpinkrobots.flatsweep"
      "flathub:dev.fredol.open-tv"
      "flathub:im.riot.Riot"
      "flathub:io.gitlab.adhami3310.Converter"
      "flathub:io.github.xyproto.zsnes"
    )

    # Install each flatpak if not already installed
    for pkg in "''${FLATPAKS[@]}"; do
      # Extract the app ID from the package string (e.g., "flathub:com.usebottles.bottles" -> "com.usebottles.bottles")
      app_id="''${pkg#*:}"
      if ! ${pkgs.flatpak}/bin/flatpak list --system --columns=application 2>/dev/null | grep -q "^''${app_id}$"; then
        echo "Installing flatpak: ''${pkg}"
        ${pkgs.flatpak}/bin/flatpak install --system --noninteractive --assumeyes "''${pkg}" || true
      else
        echo "Flatpak already installed: ''${app_id}"
      fi
    done
  '';

  # Android ADB udev support now handled automatically by systemd 258+ uaccess rules
  services.udev.packages = [ pkgs.brightnessctl ];
  services.udev.extraRules = ''
    # Note: Android ADB rules now handled automatically by systemd 258+
    # Google (Pixel/Nexus) generic USB (MTP/ADB) - keeping for backwards compatibility
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="adbusers"
    # Elgato Stream Deck (USB + hidraw)
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", MODE="0660", GROUP="plugdev"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0fd9", MODE="0660", GROUP="plugdev"

    # Prevent wakeup from USB devices (mice, keyboards, etc.) - critical for preventing unexpected wakeups
    # Disable wakeup for USB HID devices (keyboards, mice)
    ACTION=="add", SUBSYSTEM=="usb", DRIVERS=="usb", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="input", KERNEL=="event*", ATTR{power/wakeup}="disabled"

    # Disable wakeup for network interfaces (prevent Wake-on-LAN from waking laptop)
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan*", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="eth*", RUN+="${pkgs.bash}/bin/bash -c 'echo disabled > /sys$devpath/power/wakeup'"

    # Note: Lid switch wakeup is intentionally left enabled (we need it to detect lid open/close)
    # But other input devices are disabled to prevent accidental wakeups
  '';
  hyprvibe.packages = {
    enable = true;
    base.enable = true;
    desktop.enable = true;
    dev.enable = true;
    gaming.enable = true;
  };

  # Boot loader configuration (kernel package provided by shared module)
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    # v4l2loopback for virtual webcam support (OBS, conferencing apps)
    # Load v4l2loopback via systemd instead of early boot to avoid kernel panic
    # The module will be loaded on-demand when needed
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    extraModprobeConfig = ''
      # Dedicated virtual camera for OBS capture, fixed at /dev/video10
      options v4l2loopback video_nr=10 exclusive_caps=1 card_label=OBS-VirtualCam
    '';
    # Kernel parameters for Intel Core i7-10810U (Comet Lake) + Intel UHD Graphics
    # Performance optimizations while maintaining stability
    #
    # Stability fixes (Priority 1-3 - keep these):
    # Priority 1: C-state limiting prevents kernel panics on Dell Latitude 5410
    # Priority 2: Intel graphics driver fixes (i915)
    # Priority 3: ACPI compatibility fixes
    #
    # Performance optimizations (Priority 4-7):
    # Priority 4: CPU performance (RCU, NOHZ for 6-core/12-thread CPU)
    # Priority 5: Intel GPU performance (FBC, PSR, DC)
    # Priority 6: I/O scheduler (NVMe optimization)
    # Priority 7: Memory (transparent hugepages)
    kernelParams = [
      # Stability fixes (Priority 1-3)
      "intel_idle.max_cstate=1" # Reduce C-state depth (prevents deep sleep panics)
      "processor.max_cstate=1" # Limit processor C-states system-wide
      "i915.enable_guc=0" # Disable Intel GPU GuC firmware loading (stability)
      "i915.enable_huc=0" # Disable Intel GPU HuC firmware loading (stability)
      "acpi_osi=Linux" # Tell ACPI we're Linux (better compatibility)

      # Performance optimizations (Priority 4-7)
      # CPU: RCU and NOHZ tuning for 6-core/12-thread CPU (i7-10810U)
      "rcu_nocbs=0-11" # Offload RCU callbacks from all 12 threads
      "nohz_full=0-11" # Enable full dynticks (reduce timer interrupts)
      # Intel GPU: Performance features (safe to enable)
      "i915.enable_fbc=1" # Enable frame buffer compression (saves power, improves performance)
      "i915.enable_psr=1" # Enable panel self-refresh (saves power)
      "i915.enable_dc=1" # Enable display C-states (power saving)
      "i915.modeset=1" # Force modesetting (explicit, already default)
      # I/O: NVMe optimization (assuming NVMe drive)
      "elevator=none" # No-op scheduler for NVMe (best performance)
      # Memory: Transparent hugepages for better memory performance
      "transparent_hugepage=always" # Always use hugepages when possible
    ];

    # Kernel sysctl tuning for performance
    kernel.sysctl = {
      # Memory management optimizations
      "vm.swappiness" = 10; # Reduce swapping aggressiveness (default: 60)
      "vm.vfs_cache_pressure" = 50; # Balance between inode and dentry caches
      "vm.dirty_background_ratio" = 5; # Flush dirty pages more aggressively (default: 10)
      "vm.dirty_ratio" = 10; # Hard limit for dirty pages (default: 20)
      "vm.dirty_expire_centisecs" = 3000; # How long dirty pages can stay (30s, default: 3000)
      "vm.dirty_writeback_centisecs" = 500; # How often writeback happens (5s, default: 500)
      "vm.overcommit_memory" = 1; # Allow overcommit (better for desktop, default: 0)
      "vm.overcommit_ratio" = 50; # Allow 50% overcommit (default: 50)
      "vm.min_free_kbytes" = 65536; # Ensure minimum free memory (default varies)
      "vm.zone_reclaim_mode" = 0; # Disable zone reclaim (better for UMA systems)

      # Network TCP tuning for better throughput
      "net.core.rmem_max" = 67108864; # 64MB max receive buffer
      "net.core.wmem_max" = 67108864; # 64MB max send buffer
      "net.core.rmem_default" = 87380; # Default receive buffer
      "net.core.wmem_default" = 65536; # Default send buffer
      "net.ipv4.tcp_rmem" = "4096 87380 67108864"; # TCP receive buffer (min default max)
      "net.ipv4.tcp_wmem" = "4096 65536 67108864"; # TCP send buffer (min default max)
      "net.ipv4.tcp_fastopen" = 3; # Enable TCP Fast Open (client + server)
      "net.core.netdev_max_backlog" = 5000; # Increase network device backlog
      "net.ipv4.tcp_slow_start_after_idle" = 0; # Disable slow start after idle (better for persistent connections)

      # Kernel memory management
      "kernel.panic_on_oom" = 0; # Don't panic on OOM (let systemd-oomd handle it)
      "vm.oom_dump_tasks" = 1; # Dump tasks on OOM for debugging
    };
  };

  # Filesystem performance optimizations
  fileSystems."/".options = [
    "noatime"
    "nodiratime"
    "discard"
  ];
  fileSystems."/home".options = [
    "noatime"
    "nodiratime"
    "discard"
  ];

  # Systemd performance optimizations
  systemd.settings.Manager = {
    # Increase default service limits for better performance
    DefaultLimitNOFILE = "65535";
    DefaultLimitNPROC = "32768";
  };

  # Journald performance tuning
  services.journald = {
    rateLimitBurst = 1000;
    rateLimitInterval = "30s";
    extraConfig = ''
      Storage=auto
      SystemMaxUse=200M
      RuntimeMaxUse=50M
    '';
  };

  # ZRAM configuration (override shared module defaults for this system)
  # 6-core CPU with 12 threads benefits from more ZRAM
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # Use 50% of RAM for ZRAM (good for 16GB+ systems)
  };

  # Automatic system updates (use flake to avoid channel-based reverts)
  system.autoUpgrade = {
    enable = true;
    flake = "github:ChrisLAS/hyprvibe#nixbook";
    operation = "boot";
    randomizedDelaySec = "45min";
    allowReboot = false;
    dates = "02:00";
  };

  # Power management optimizations
  # Note: Dynamic power management is handled by hyprvibe.power module
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance"; # Default to performance (hyprvibe.power can override)
    powertop.enable = true; # Enable powertop for power tuning
  };

  # logind configuration for laptop lid handling and sleep management
  # Prevents unexpected wakeups that drain battery
  services.logind = {
    # Additional sleep configuration - ensure proper sleep behavior
    settings = {
      Login = {
        # Suspend when lid is closed (both on battery and AC power)
        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "suspend"; # Also suspend when plugged in
        HandleLidSwitchDocked = "ignore"; # Don't suspend if docked/external displays

        # Power button behavior
        HandlePowerKey = "suspend";
        HandlePowerKeyLongPress = "poweroff";

        # Ensure system enters sleep state properly
        HandleSuspendKey = "suspend";
        HandleHibernateKey = "suspend";
      };
    };
  };

  # CPU microcode updates (critical for Intel CPUs)
  hardware.cpu.intel.updateMicrocode = true;

  # OOM configuration
  systemd = {
    slices."nix-daemon".sliceConfig = {
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "95%";
    };
    services."nix-daemon" = {
      serviceConfig = {
        Slice = "nix-daemon.slice";
        OOMScoreAdjust = 1000;
      };
    };
    # Keep Netdata unit installed but do not enable it at boot
    services.netdata.wantedBy = pkgs.lib.mkForce [ ];
    services.netdata.restartIfChanged = false;
    # Load v4l2loopback module after system is ready (not during early boot)
    # This avoids kernel panic during early boot if module has compatibility issues
    services.load-v4l2loopback = {
      description = "Load v4l2loopback kernel module";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.kmod}/bin/modprobe v4l2loopback";
      };
    };
    user.services.kwalletd = {
      description = "KWallet user daemon";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Environment = [
          "QT_QPA_PLATFORM=wayland"
          "XDG_RUNTIME_DIR=%t"
        ];
        ExecStart = "${pkgs.kdePackages.kwallet}/bin/kwalletd6";
        Restart = "on-failure";
      };
    };

    # Load GITHUB_TOKEN into the systemd user manager environment from a local secret file
    user.services.set-github-token = {
      description = "Set GITHUB_TOKEN in systemd --user environment from ~/.config/secrets/github_token";
      after = [ "default.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${setGithubTokenScript}";
      };
    };

    # Setup OpenCode configuration with OpenRouter defaults
    user.services.setup-opencode-config = {
      description = "Setup OpenCode configuration with OpenRouter defaults";
      after = [ "default.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${setupOpencodeConfigScript}";
      };
    };
  };

  # Networking
  networking = {
    hostName = "nixbook";
    networkmanager.enable = true;
    networkmanager.dns = "systemd-resolved";
    firewall = {
      enable = false;
    };
  };

  # Time zone
  time.timeZone = "America/Los_Angeles";

  # Hardware configuration
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      # Enable experimental features (battery, LC3, etc.)
      settings = {
        General = {
          Experimental = true;
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
    graphics = {
      enable = true;
      enable32Bit = true;
      # Intel GPU optimizations for Comet Lake UHD Graphics
      extraPackages = with pkgs; [
        intel-media-driver # VAAPI video acceleration for Intel GPUs (modern)
        intel-vaapi-driver # Legacy VAAPI driver (fallback, renamed from vaapiIntel)
        libva-vdpau-driver # VDPAU wrapper for VAAPI (renamed from vaapiVdpau)
        libvdpau-va-gl # VDPAU driver with VAAPI backend
      ];
    };
    i2c.enable = true;
    steam-hardware.enable = true;
  };

  # Services
  services = {
    resolved.enable = true;
    # Desktop support services moved to shared module (udisks2, gvfs, tumbler, blueman, avahi, davfs2, gnome-keyring, gdm)
    printing.enable = true;

    openssh.enable = true;
    # Tailscale is configured via hyprvibe.services.tailscale.enable (see above)
    # The shared module sets useRoutingFeatures = "both" by default
    # Override here if you need "client" mode (use routes but don't advertise):
    # tailscale.useRoutingFeatures = "client";
    netdata = {
      enable = true;
      # Drop-in config to disable the Postgres collector (go.d plugin)
      configDir = {
        "go.d.conf" = pkgs.writeText "go.d.conf" ''
          modules:
            postgres: no
        '';
        "go.d/postgres.conf" = pkgs.writeText "postgres.conf" ''
          enabled: no
        '';
      };
      config = {
        plugins = {
          "logs-management" = "no";
          "ioping" = "no";
          "perf" = "no";
          "freeipmi" = "no";
          "charts.d" = "no";
        };
      };
    };

    # Atuin shell history service
    atuin = {
      enable = true;
      # Optional: Configure a server for sync (uncomment and configure if needed)
      # server = {
      #   enable = true;
      #   host = "0.0.0.0";
      #   port = 8888;
      # };
    };
  };

  # Auto Tune
  services.bpftune.enable = true;
  programs.bcc.enable = true;

  # Security
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo.wheelNeedsPassword = false;
    # Increase file descriptor limits for better performance
    pam.loginLimits = [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "65535";
      }
      {
        domain = "*";
        type = "hard";
        item = "nofile";
        value = "65535";
      }
    ];
    pam.services = {
      login.kwallet.enable = true;
      gdm.kwallet.enable = true;
      gdm-password.kwallet.enable = true;
      hyprlock = { };
      # Unlock GNOME Keyring on login for GVFS credentials
      login.enableGnomeKeyring = true;
      gdm-password.enableGnomeKeyring = true;
    };
  };

  # Virtualization
  virtualisation = {
    libvirtd.enable = true;
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
  };

  # No man pages handled by shared module

  # User configuration handled by hyprvibe.user

  # Podman + declarative Companion container
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers.companion = {
    image = "ghcr.io/bitfocus/companion/companion:latest";
    autoStart = true;
    # Note: image defaults to user "companion"; override via extraOptions
    ports = [
      "8000:8000"
      "51234:51234"
    ];
    volumes = [
      "/var/lib/companion:/companion"
      "/run/udev:/run/udev:ro"
      "/dev/bus/usb:/dev/bus/usb"
    ];
    extraOptions = [
      "--privileged"
      "--user=0:0"
    ];
    labels = {
      "io.containers.autoupdate" = "registry";
    };
  };

  # Ensure persistent data directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/companion 0777 root root -"
  ];

  # Open firewall for Companion
  networking.firewall.allowedTCPPorts = (config.networking.firewall.allowedTCPPorts or [ ]) ++ [
    8000
    51234
  ];
  networking.firewall.allowedUDPPorts = (config.networking.firewall.allowedUDPPorts or [ ]) ++ [
    51234
  ];

  # Removed stale nixbook-specific activation script body.
  # Shared hyprvibe modules now manage Hyprland, shell, and related desktop files.
  # Programs
  programs = {
    virt-manager.enable = true;
    dconf.enable = true;
    gamemode.enable = true;
    # Enable nix-ld to allow dynamically linked executables (like cursor-agent) to run
    nix-ld.enable = true;
    thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
    steam = {
      enable = true;
      gamescopeSession.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
    # Hyprland configuration provided by shared module
    obs-studio = {
      enable = true;
      plugins = [
        pkgs.obs-studio-plugins.obs-pipewire-audio-capture
        pkgs.obs-studio-plugins.wlrobs
        pkgs.obs-studio-plugins.waveform
        pkgs.obs-studio-plugins.obs-stroke-glow-shadow
        pkgs.obs-studio-plugins.obs-source-record
        pkgs.obs-studio-plugins.obs-dir-watch-media
        pkgs.obs-studio-plugins.obs-backgroundremoval
        pkgs.obs-studio-plugins.obs-advanced-masks
      ];
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    ubuntu-classic
    noto-fonts-color-emoji
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.ubuntu
    mplus-outline-fonts.githubRelease
    dina-font
    fira
  ];

  # Environment
  environment = {
    sessionVariables = {
      # Cursor theme for consistency across apps
      XCURSOR_THEME = "Bibata-Modern-Ice";
      # Audio plugin discovery paths for REAPER and other hosts
      VST_PATH = "/run/current-system/sw/lib/vst";
      VST3_PATH = "/run/current-system/sw/lib/vst3";
      LADSPA_PATH = "/run/current-system/sw/lib/ladspa";
      LV2_PATH = "/run/current-system/sw/lib/lv2";
      CLAP_PATH = "/run/current-system/sw/lib/clap";
    };
    systemPackages =
      devTools ++ multimedia ++ utilities ++ systemTools ++ applications ++ gaming ++ gtkApps;

    # Disable Orca in GDM greeter to silence missing TryExec logs
    etc = {
      "xdg/autostart/orca-autostart.desktop".text = ''
        [Desktop Entry]
        Hidden=true
      '';
    };
  };

  # Prefer Hyprland XDG portal
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    # Hyprland module provides its own portal; include only GTK here to avoid duplicate units
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      common = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
      };
    };
  };

  # Make Qt apps follow GNOME/GTK settings for closer match to GTK theme
  qt = {
    enable = true;
    platformTheme = null;
    style = "adwaita-dark";
  };

  # Nix settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "libsoup-2.74.3"
    "jitsi-meet-1.0.8792"
  ];
  # Workaround: upstream mat2 test regression (breaks metadata-cleaner)
  nixpkgs.overlays = [
    (final: prev: {
      python3Packages = prev.python3Packages.override {
        overrides = self: super: {
          mat2 = super.mat2.overridePythonAttrs (old: {
            doCheck = false;
          });
        };
      };
      python313Packages = prev.python313Packages.override {
        overrides = self: super: {
          mat2 = super.mat2.overridePythonAttrs (old: {
            doCheck = false;
          });
        };
      };
    })
  ];

  # System version
  system.stateVersion = "25.11";
}
