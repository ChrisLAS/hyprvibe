{ config, pkgs, hyprland, ... }:

let
  # Package groups - preserving your existing packages
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
    nixfmt-rfc-style
    zed-editor
    code-cursor
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
    oh-my-posh
    lazydocker
    # Additional dev tools from your current config
    yarn
    nodejs_20
    qemu
    speechd
    roboto
    roboto-serif
    quickemu
    junction
    distrobox
    gitui
    cmake
    ispell
    aspell
    gnumake
    patchelf
    glxinfo
    roc-toolkit
    binutils
    dool
    file
    iotop
    pciutils
    zellij
    tree
    lsof
    lshw
    jack2
    obs-studio
    obs-studio-plugins.wlrobs
    obs-studio-plugins.waveform
    obs-studio-plugins.obs-pipewire-audio-capture
    lazygit
    brave
    simplex-chat-desktop
    xrdp
    caffeine-ng
    filezilla
    zed-editor
    lutris
    adwaita-icon-theme
  ];

  multimedia = with pkgs; [
    mpv
    vlc
    ffmpeg-full
    lame
    qjackctl
    qpwgraph
    x32edit
    easyeffects
    wayfarer
    obs-studio
    obs-studio-plugins.obs-pipewire-audio-capture
    libepoxy
    audacity
    ffmpegthumbnailer
    gnome.gvfs
    imv
    # Additional multimedia from your current config
    v4l-utils
    v4l2-relayd
    libv4l
    roc-toolkit
    libarchive
    libzip
    unrar
    pzip
    lrzip
    kdePackages.ark
    kdePackages.yakuake
    kdePackages.kdenlive
    kdePackages.ktorrent
    krita
    kdePackages.discover
    kdePackages.kfind
    kdePackages.kleopatra
    kdePackages.filelight
    kdePackages.isoimagewriter
    kdePackages.partitionmanager
  ];

  utilities = with pkgs; [
    ghostty
    htop
    btop
    neofetch
    nmap
    mosh
    yt-dlp
    zip
    unzip
    gnupg
    restic
    autorestic
    restique
    hddtemp
    smartmontools
    iotop
    lm_sensors
    tree
    lsof
    lshw
    tor-browser
    vdhcoapp
    wmctrl
    oh-my-posh
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
    xdg-utils
    kdePackages.polkit-kde-agent-1
    qt6.qtbase
    qt6.qtwayland
    wofi
    dunst
    cliphist
    brightnessctl
    playerctl
    kdePackages.kwallet
    kdePackages.kwallet-pam
    kdePackages.kate
    libnotify
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
    less
    whois
    bash-completion
    pamixer
    wiremix
    fcitx5
    fcitx5-gtk
    kdePackages.fcitx5-qt
    nautilus
    libqalculate
    mako
    swaybg
    swayosd
    rofi-wayland
    qt6ct
    pavucontrol
    networkmanagerapplet
    atuin
    ddcutil
    curl
    openssh
    glib-networking
    rclone
    # Additional utilities from your current config
    usbmuxd
    magic-wormhole
    android-udev-rules
    adb-sync
    jmtpfs
    nextcloud-client
    gnome-firmware
    wayland-protocols
    wayland-scanner
    wayland
    avahi
    mesa
    libffi
    libevdev
    libcap
    libdrm
    xorg.libXrandr
    xorg.libxcb
    libevdev
    libpulseaudio
    xorg.libX11
    xorg.libXfixes
    libva
    libvdpau
    moonlight-qt
    sunshine
    virt-manager
    fuse
    fuse3
    appimage-run
    pop-gtk-theme
    cool-retro-term
    gparted
    vscode-fhs
    logitech-udev-rules
    ltunify
    solaar
    gtop
    wine-wayland
    winetricks
    wineasio
    bottles-unwrapped
    rustdesk-flutter
    pwvucontrol
    pipecontrol
    wireplumber
    kdePackages.plasma-browser-integration
    nixfmt-rfc-style
    qownnotes
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
    # Additional system tools from your current config
    cifs-utils
    samba
    distrobox
  ];

  applications = with pkgs; [
    firefox
    brave
    google-chrome
    nextcloud-client
    trayscale
    maestral-gui
    qownnotes
    libation
    audible-cli
    chromium
    gnome-calculator
    gnome-keyring
    libreoffice
    kdePackages.kdenlive
    xournalpp
    localsend
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
    rclone-browser
    # Additional applications from your current config
    maestral
    maestral-gui
    steam-run
    steam
    appimage-run
    android-udev-rules
    adb-sync
    gnumake
    unzip
    zip
    gnupg
    pkgs.restic
    pkgs.autorestic
    pkgs.restique
    pkgs.nextcloud-client
    pkgs.gnome-firmware
    wayland-protocols
    wayland-scanner
    wayland
    avahi
    mesa
    libffi
    libevdev
    libcap
    libdrm
    xorg.libXrandr
    xorg.libxcb
    ffmpeg-full
    libevdev
    libpulseaudio
    xorg.libX11
    pkgs.xorg.libxcb
    xorg.libXfixes
    libva
    libvdpau
    pkgs.moonlight-qt
    pkgs.sunshine
    virt-manager
    fuse
    fuse3
    appimage-run
    pop-gtk-theme
    cool-retro-term
    gparted
    vscode-fhs
    logitech-udev-rules
    ltunify
    solaar
    gtop
    wine-wayland
    winetricks
    wineasio
    bottles-unwrapped
    yarn
    pkgs.nodejs_20
    pkgs.qemu
    speechd
    roboto
    roboto-serif
    quickemu
    junction
    distrobox
    tor-browser
    v4l-utils
    v4l2-relayd
    libv4l
    sunshine
    nixfmt-rfc-style
    qownnotes
    roc-toolkit
    libarchive
    libzip
    unrar
    pzip
    lrzip
    kdePackages.ark
    kdePackages.yakuake
    kdePackages.kdenlive
    kdePackages.ark
    kdePackages.ktorrent
    krita
    kdePackages.discover
    kdePackages.kfind
    kdePackages.kleopatra
    kdePackages.filelight
    kdePackages.isoimagewriter
    kdePackages.partitionmanager
    rustdesk-flutter
    pkgs.cifs-utils
    pkgs.samba
    distrobox
    pwvucontrol
    pipecontrol
    wireplumber
    pavucontrol
    qpwgraph
    kdePackages.plasma-browser-integration
    gitui
    cmake
    ispell
    gcc
    go
    aspell
    gnumake
    patchelf
    glxinfo
    roc-toolkit
    binutils
    dool
    file
    iotop
    pciutils
    zellij
    tree
    lsof
    lshw
    jack2
    obs-studio
    obs-studio-plugins.wlrobs
    obs-studio-plugins.waveform
    obs-studio-plugins.obs-pipewire-audio-capture
    lazygit
    brave
    simplex-chat-desktop
    xrdp
    caffeine-ng
    filezilla
    zed-editor
    lutris
    adwaita-icon-theme
  ];

  gaming = with pkgs; [
    steam-run
    moonlight-qt
    sunshine
    adwaita-icon-theme
    lutris
    playonlinux
    wineWowPackages.staging
    winetricks
    vulkan-tools
    # Additional gaming from your current config
    steam
    appimage-run
    wine-wayland
    winetricks
    wineasio
    bottles-unwrapped
  ];

  # GTK applications
  gtkApps = with pkgs; [
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
    # KDE System Components for file associations
    kdePackages.systemsettings
    kdePackages.kinfocenter
    kdePackages.kfilemetadata
    kdePackages.baloo
    kdePackages.baloo-widgets
    kdePackages.kservice
    kdePackages.kded
    kdePackages.kio-extras-kf5
    shared-mime-info
    desktop-file-utils
    xfce.thunar
    xfce.tumbler
    gvfs
    tokyo-night-gtk
    papirus-icon-theme
    bibata-cursors
    adwaita-qt
    adwaita-qt6
    evince
    eog
    gnome-calculator
    file-roller
    celluloid
    fragments
    blanket
    metadata-cleaner
    dialect
    drawing
  ];

  # Centralized wallpaper path
  wallpaperPath = "/home/chrisf/build/config/hyprvibe/hosts/nixstation/wallpaper.jpg";

  # Script to import GITHUB_TOKEN into systemd --user environment
  setGithubTokenScript = pkgs.writeShellScript "set-github-token" ''
    if [ -r "$HOME/.config/secrets/github_token" ]; then
      value="$(tr -d '\n' < "$HOME/.config/secrets/github_token")"
      systemctl --user set-environment GITHUB_TOKEN="$value"
    fi
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
  shared.desktop = {
    enable = true;
    fonts.enable = true;
  };
  shared.hyprland.enable = true;
  # Provide per-host monitors and wallpaper paths to shared module
  shared.hyprland.monitorsFile = ../../configs/hyprland-monitors-nixstation.conf;
  shared.waybar.enable = true;
  shared.waybar.configPath = ./waybar.json;
  shared.waybar.stylePath = ./waybar.css;
  shared.waybar.scriptsDir = ./scripts;
  shared.shell = { enable = true; kittyAsDefault = true; };
  shared.services = {
    enable = true;
    openssh.enable = true;
    tailscale.enable = true;
    virt.enable = true;
    docker.enable = true;
  };
  shared.packages = {
    enable = true;
    base.enable = true;
    desktop.enable = true;
    dev.enable = true;
    gaming.enable = true;
    # Add NIXSTATION-specific packages as extra packages
    extraPackages = devTools ++ multimedia ++ utilities ++ systemTools ++ applications ++ gaming ++ gtkApps;
  };

  # Boot configuration - PRESERVING YOUR EXISTING CONFIG
  boot = {
    # Keep your existing GRUB configuration
    loader.grub.enable = true;
    loader.grub.device = "/dev/nvme0n1";
    loader.efi.canTouchEfiVariables = true;
    loader.efi.efiSysMountPoint = "/boot/efi";
    
    # Switch to Zen kernel as requested
    kernelPackages = pkgs.linuxPackages_zen;
  };

  # System performance and maintenance - PRESERVING YOUR EXISTING CONFIG
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # Improve disk performance - PRESERVING YOUR EXISTING CONFIG
  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];

  # Increase file descriptors limit - PRESERVING YOUR EXISTING CONFIG
  security.pam.loginLimits = [{
    domain = "*";
    type = "soft";
    item = "nofile";
    value = "65535";
  }];

  # Enable z-ram - PRESERVING YOUR EXISTING CONFIG
  zramSwap.enable = true;
  zramSwap.memoryPercent = 300;

  # Enable OOM - PRESERVING YOUR EXISTING CONFIG
  systemd.oomd.enable = true;

  # Enable CPU performance governor - PRESERVING YOUR EXISTING CONFIG
  powerManagement = {
    cpuFreqGovernor = "performance";
    powertop.enable = true;
  };

  # Nix settings - PRESERVING YOUR EXISTING CONFIG
  nix.settings = {
    download-buffer-size = 512000000;
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Less Journal Flushes - PRESERVING YOUR EXISTING CONFIG
  services.journald = {
    rateLimitBurst = 1000;
    rateLimitInterval = "30s";
    extraConfig = ''
      Storage=auto
      SystemMaxUse=200M
      RuntimeMaxUse=50M
    '';
  };

  # Networking - PRESERVING YOUR EXISTING CONFIG
  networking = {
    hostName = "nixstation";
    networkmanager.enable = true;
    firewall.enable = false;
  };

  # Time zone - PRESERVING YOUR EXISTING CONFIG
  time.timeZone = "America/Los_Angeles";

  # Internationalization - PRESERVING YOUR EXISTING CONFIG
  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "C.UTF-8/UTF-8"
    ];
  };

  # Hardware configuration - PRESERVING YOUR EXISTING CONFIG
  hardware = {
    bluetooth = {
      enable = true;
      # Enhanced settings for Logitech mice
      settings = {
        General = {
          # Enable experimental features for better HID support
          Experimental = true;
          # Enable battery reporting
          BatteryReporting = true;
          # Enable HID over GATT
          HIDOverGATT = true;
        };
        Policy = {
          # Auto-enable Bluetooth on boot
          AutoEnable = true;
          # Allow pairing without PIN for trusted devices
          ReconnectAttempts = 7;
          ReconnectIntervals = "1,2,4,8,16,32,64";
        };
        GATT = {
          # Enable HID over GATT for better mouse support
          Key = "HIDOverGATT";
          Value = true;
        };
      };
      # Additional packages for Logitech support
      package = pkgs.bluez5-experimental;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [ vaapiVdpau ];
    };
    i2c.enable = true;
    steam-hardware.enable = true;
  };

  # Services - PRESERVING YOUR EXISTING CONFIG
  services = {
    
    # Enable CUPS to print documents
    printing.enable = true;
    
    # Enable sound with pipewire - PRESERVING YOUR EXISTING CONFIG
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    
    # Enable touchpad support
    libinput.enable = true;
    
    # Enable Flatpak - PRESERVING YOUR EXISTING CONFIG
    flatpak.enable = true;
    
    # Enable Tor - PRESERVING YOUR EXISTING CONFIG
    tor.client.enable = true;
    tor.enable = true;
    
    # Enable Sunshine Streaming Server - PRESERVING YOUR EXISTING CONFIG
    xserver.config = ''
      Section "Device"
        Identifier "sw-mouse"
        Driver     "amdgpu"
        Option "SWCursor" "true"
      EndSection
    '';
    

    

    
    # Enable Tailscale Service - PRESERVING YOUR EXISTING CONFIG
    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
    };
    
    # Enable the OpenSSH daemon - PRESERVING YOUR EXISTING CONFIG
    openssh.enable = true;
    
    # Enable locate - PRESERVING YOUR EXISTING CONFIG
    locate.enable = true;
    
    # Display manager for Hyprland
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    
    # Additional services from GitHub config
    udev.packages = [ 
      pkgs.brightnessctl 
      pkgs.logitech-udev-rules
      # Additional udev rules for better HID support
      pkgs.bluez5-experimental
    ];
    udisks2.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;
    blueman.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
    };
    davfs2.enable = true;
    gnome.gnome-keyring.enable = true;
    atuin = {
      enable = true;
    };
  };

  # Auto Tune
  services.bpftune.enable = true;
  programs.bcc.enable = true;

  # Security - PRESERVING YOUR EXISTING CONFIG
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo.wheelNeedsPassword = false;
    pam.services = {
      login.kwallet.enable = true;
      gdm.kwallet.enable = true;
      gdm-password.kwallet.enable = true;
      hyprlock = { };
      login.enableGnomeKeyring = true;
      gdm-password.enableGnomeKeyring = true;
    };
    # Sunshine wrapper - PRESERVING YOUR EXISTING CONFIG
    wrappers.sunshine = {
      owner = "root";
      group = "root";
      capabilities = "cap_sys_admin+p";
      source = "${pkgs.sunshine}/bin/sunshine";
    };
  };

  # Virtualization - PRESERVING YOUR EXISTING CONFIG
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

  # Boot kernel modules - PRESERVING YOUR EXISTING CONFIG
  boot.kernelModules = [ 
    "kvm-amd" 
    "kvm-intel" 
    # Additional modules for better Bluetooth HID support
    "hid_logitech"
    "hid_logitech_dj"
    "hid_logitech_hidpp"
    "btusb"
    "bluetooth"
    "hid_generic"
    "uhid"
  ];

  # No man pages
  documentation.man.enable = false;

  # User configuration - PRESERVING YOUR EXISTING CONFIG
  users.users.chrisf = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "Chris Fisher";
    linger = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "adbusers"
      "libvirtd"
      "video"
      "render"
      "audio"
      "i2c"
    ];
    home = "/home/chrisf";
  };

  # NIXSTATION-specific activation scripts (complementing shared modules)
  system.activationScripts.nixstationSpecific = ''
    # Copy NIXSTATION-specific Hyprland configs
    mkdir -p /home/chrisf/.config/hypr
    cp ${./hyprland.conf} /home/chrisf/.config/hypr/hyprland.conf
    # Render wallpaper path into hyprpaper/hyprlock configs
    ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#${wallpaperPath}#g" ${./hyprpaper.conf} > /home/chrisf/.config/hypr/hyprpaper.conf
    ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#${wallpaperPath}#g" ${./hyprlock.conf} > /home/chrisf/.config/hypr/hyprlock.conf
    cp ${./hypridle.conf} /home/chrisf/.config/hypr/hypridle.conf
    
    # Install NIXSTATION-specific Hyprland scripts
    mkdir -p /home/chrisf/.config/hypr/scripts
    cp ${./scripts/launch-communication.sh} /home/chrisf/.config/hypr/scripts/launch-communication.sh
    cp ${./scripts/launch-development.sh} /home/chrisf/.config/hypr/scripts/launch-development.sh
    cp ${./scripts/logitech-bluetooth.sh} /home/chrisf/.config/hypr/scripts/logitech-bluetooth.sh
    chmod +x /home/chrisf/.config/hypr/scripts/*.sh
    chown -R chrisf:users /home/chrisf/.config/hypr
    
    # Copy additional waybar configs (shared module handles main config)
    mkdir -p /home/chrisf/.config/waybar
    cp ${./waybar-simple.json} /home/chrisf/.config/waybar/waybar-simple.json
    cp ${./waybar-simple-dp1.json} /home/chrisf/.config/waybar/waybar-simple-dp1.json
    cp ${./waybar-simple-dp2.json} /home/chrisf/.config/waybar/waybar-simple-dp2.json
    cp ${./waybar-simple-hdmi.json} /home/chrisf/.config/waybar/waybar-simple-hdmi.json
    
    # Copy waybar scripts
    mkdir -p /home/chrisf/.config/waybar/scripts
    cp ${./scripts/waybar-timezones.sh} /home/chrisf/.config/waybar/scripts/waybar-timezones.sh
    
    # Ensure waybar scripts are executable
    chmod +x /home/chrisf/.config/waybar/scripts/*.sh 2>/dev/null || true
    chmod +x /home/chrisf/.config/waybar/scripts/*.py 2>/dev/null || true
    chown -R chrisf:users /home/chrisf/.config/waybar
    
    # Create Atuin Fish configuration
    mkdir -p /home/chrisf/.config/fish/conf.d
    cat > /home/chrisf/.config/fish/conf.d/atuin.fish << 'EOF'
    # Atuin shell history integration
    if command -q atuin
      set -g ATUIN_SESSION (atuin uuid)
      atuin init fish | source
    end
    EOF
    
    # Additional Fish configuration for better integration
    cat > /home/chrisf/.config/fish/conf.d/kitty-integration.fish << 'EOF'
    # Kitty terminal integration
    if test "$TERM" = "xterm-kitty"
      # Enable kitty shell integration
      kitty + complete setup fish | source
      
      # Set kitty-specific environment variables
      set -gx KITTY_SHELL_INTEGRATION enabled
    end
    EOF
    
    # GitHub token export for fish
    mkdir -p /home/chrisf/.config/secrets
    chown -R chrisf:users /home/chrisf/.config/secrets
    chmod 700 /home/chrisf/.config/secrets
    cat > /home/chrisf/.config/fish/conf.d/github_token.fish << 'EOF'
    if test -r /home/chrisf/.config/secrets/github_token
      set -gx GITHUB_TOKEN (string trim (cat /home/chrisf/.config/secrets/github_token))
    end
    EOF
    chown -R chrisf:users /home/chrisf/.config/fish
    
    # Install crypto-price for Waybar module
    mkdir -p /home/chrisf/.local/bin
    chown -R chrisf:users /home/chrisf/.local
    runuser -l chrisf -c 'GOBIN=$HOME/.local/bin ${pkgs.go}/bin/go install github.com/u3mur4/crypto-price/cmd/crypto-price@latest' || true
    
    # Copy monitor setup helper script
    cp ${../../scripts/setup-monitors.sh} /home/chrisf/.local/bin/setup-monitors
    chmod +x /home/chrisf/.local/bin/setup-monitors
    
    # Set Kitty as default terminal in desktop environment
    mkdir -p /home/chrisf/.local/share/applications
    cat > /home/chrisf/.local/share/applications/kitty.desktop << 'EOF'
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=Kitty
    GenericName=Terminal
    Comment=Fast, feature-rich, GPU based terminal emulator
    Exec=kitty
    Icon=kitty
    Terminal=false
    Categories=System;TerminalEmulator;
    EOF
    chown chrisf:users /home/chrisf/.local/share/applications/kitty.desktop
    
    # Update desktop database to register Kitty
    runuser -l chrisf -c 'update-desktop-database ~/.local/share/applications' || true
    
    # Copy waybar switch script
    cp ${../../scripts/waybar-switch.sh} /home/chrisf/.local/bin/waybar-switch
    chmod +x /home/chrisf/.local/bin/waybar-switch
    
    # Copy per-monitor waybar script
    cp ${../../scripts/waybar-per-monitor.sh} /home/chrisf/.local/bin/waybar-per-monitor
    chmod +x /home/chrisf/.local/bin/waybar-per-monitor

    # Copy Logitech Bluetooth management script
    cp ${./scripts/logitech-bluetooth.sh} /home/chrisf/.local/bin/logitech-bluetooth
    chmod +x /home/chrisf/.local/bin/logitech-bluetooth


    # Apply GTK theming
    mkdir -p /home/chrisf/.config/gtk-3.0
    cat > /home/chrisf/.config/gtk-3.0/settings.ini << 'EOF'
    [Settings]
    gtk-theme-name=Tokyonight-Dark-B
    gtk-icon-theme-name=Papirus-Dark
    gtk-cursor-theme-name=Bibata-Modern-Ice
    gtk-cursor-theme-size=24
    gtk-application-prefer-dark-theme=true
    EOF
    mkdir -p /home/chrisf/.config/gtk-4.0
    cat > /home/chrisf/.config/gtk-4.0/settings.ini << 'EOF'
    [Settings]
    gtk-theme-name=Tokyonight-Dark-B
    gtk-icon-theme-name=Papirus-Dark
    gtk-cursor-theme-name=Bibata-Modern-Ice
    gtk-cursor-theme-size=24
    gtk-application-prefer-dark-theme=true
    EOF
    chown -R chrisf:users /home/chrisf/.config/gtk-3.0 /home/chrisf/.config/gtk-4.0

    # Configure qt6ct
    mkdir -p /home/chrisf/.config/qt6ct
    cat > /home/chrisf/.config/qt6ct/qt6ct.conf << 'EOF'
    [Appearance]
    style=adwaita-dark
    icon_theme=Papirus-Dark
    standard_dialogs=gtk3
    palette=
    [Fonts]
    fixed=@Variant(\0\0\0\x7f\0\0\0\n\0M\0o\0n\0o\0s\0p\0a\0c\0e\0\0\0\0\0\0\0\0\0\x1e\0\0\0\0\0\0\0\0\0\0\0\0\0\0)
    general=@Variant(\0\0\0\x7f\0\0\0\n\0I\0n\0t\0e\0r\0\0\0\0\0\0\0\0\0\x1e\0\0\0\0\0\0\0\0\0\0\0\0\0\0)
    [Interface]
    double_click_interval=400
    cursor_flash_time=1000
    buttonbox_layout=0
    keyboard_scheme=2
    gui_effects=@Invalid()
    wheel_scroll_lines=3
    resolve_symlinks=true
    single_click_activate=false
    tabs_behavior=0
    [SettingsWindow]
    geometry=@ByteArray(AdnQywADAAAAAAAAB3wAAAQqAAAADwAAAB9AAAAEKgAAAA8AAAAAAAEAAAHfAAAAAQAAAAQAAAAfAAAABCg=)
    [Troubleshooting]
    force_raster_widgets=false
    ignore_platform_theme=false
    EOF
    chown -R chrisf:users /home/chrisf/.config/qt6ct
    
    # Install rofi brightness menu
    install -m 0755 ${./scripts/rofi-brightness.sh} /home/chrisf/.local/bin/rofi-brightness
    chown chrisf:users /home/chrisf/.local/bin/rofi-brightness
    
    # Configure Kitty terminal
    mkdir -p /home/chrisf/.config/kitty
    cat > /home/chrisf/.config/kitty/kitty.conf << 'EOF'
    # Kitty Terminal Configuration
    
    # Font configuration
    font_family FiraCode Nerd Font
    font_size 12
    bold_font auto
    italic_font auto
    bold_italic_font auto
    
    # Colors - Tokyo Night inspired
    background #1a1b26
    foreground #c0caf5
    selection_background #28344a
    selection_foreground #c0caf5
    url_color #7aa2f7
    cursor #c0caf5
    cursor_text_color #1a1b26
    
    # Tabs
    active_tab_background #7aa2f7
    active_tab_foreground #1a1b26
    inactive_tab_background #1a1b26
    inactive_tab_foreground #c0caf5
    tab_bar_background #16161e
    
    # Window settings
    window_padding_width 10
    window_margin_width 0
    window_border_width 0
    background_opacity 0.95
    
    # Shell integration
    shell_integration enabled
    
    # Copy on select
    copy_on_select yes
    
    # URL detection and hyperlinks
    detect_urls yes
    show_hyperlink_targets yes
    underline_hyperlinks always
    
    # Mouse settings
    mouse_hide_while_typing yes
    focus_follows_mouse yes
    
    # Performance
    sync_to_monitor yes
    repaint_delay 10
    input_delay 3
    
    # Key bindings
    map ctrl+shift+equal change_font_size all +1.0
    map ctrl+shift+minus change_font_size all -1.0
    map ctrl+shift+0 change_font_size all 0
    
    # Fish shell integration
    shell fish
    
    # Terminal bell
    enable_audio_bell no
    visual_bell_duration 0.5
    visual_bell_color #f7768e
    
    # Cursor
    cursor_shape beam
    cursor_beam_thickness 2
    
    # Scrollback
    scrollback_lines 10000
    scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER
    
    # Clipboard
    clipboard_control write-clipboard write-primary read-clipboard read-primary
    
    # Allow remote control
    allow_remote_control yes
    listen_on unix:/tmp/kitty
    EOF
    chown -R chrisf:users /home/chrisf/.config/kitty
    
    # Configure Oh My Posh
    mkdir -p /home/chrisf/.config/oh-my-posh
    cat > /home/chrisf/.config/oh-my-posh/config.json << 'EOF'
    {
      "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
      "version": 1,
      "final_space": true,
      "blocks": [
        {
          "type": "prompt",
          "alignment": "left",
          "segments": [
            {
              "type": "path",
              "style": "plain",
              "properties": {
                "style": "folder",
                "max_depth": 2,
                "max_width": 50
              },
              "foreground": "#7aa2f7",
              "background": "#1a1b26"
            },
            {
              "type": "git",
              "style": "plain",
              "properties": {
                "display_stash_count": true,
                "display_upstream_icon": true,
                "fetch_stash_count": true,
                "fetch_status": true,
                "fetch_upstream": true
              },
              "foreground": "#bb9af7",
              "background": "#1a1b26"
            },
            {
              "type": "node",
              "style": "plain",
              "properties": {
                "fetch_version": true,
                "display_mode": "files"
              },
              "foreground": "#7dcfff",
              "background": "#1a1b26"
            },
            {
              "type": "python",
              "style": "plain",
              "properties": {
                "fetch_virtual_env": true,
                "display_version": true,
                "display_mode": "files"
              },
              "foreground": "#7dcfff",
              "background": "#1a1b26"
            },
            {
              "type": "go",
              "style": "plain",
              "properties": {
                "fetch_version": true,
                "display_mode": "files"
              },
              "foreground": "#7dcfff",
              "background": "#1a1b26"
            },
            {
              "type": "rust",
              "style": "plain",
              "properties": {
                "fetch_version": true,
                "display_mode": "files"
              },
              "foreground": "#ff9e64",
              "background": "#1a1b26"
            },
            {
              "type": "docker_context",
              "style": "plain",
              "properties": {
                "display_default": false
              },
              "foreground": "#7aa2f7",
              "background": "#1a1b26"
            },
            {
              "type": "execution_time",
              "style": "plain",
              "properties": {
                "threshold": 5000,
                "style": "text"
              },
              "foreground": "#9aa5ce",
              "background": "#1a1b26"
            },
            {
              "type": "exit",
              "style": "plain",
              "properties": {
                "display_exit_code": true,
                "error_color": "#f7768e",
                "success_color": "#9ece6a"
              },
              "foreground": "#c0caf5",
              "background": "#1a1b26"
            }
          ]
        },
        {
          "type": "prompt",
          "alignment": "right",
          "segments": [
            {
              "type": "text",
              "style": "plain",
              "properties": {
                "text": " "
              }
            },
            {
              "type": "time",
              "style": "plain",
              "properties": {
                "time_format": "15:04",
                "display_date": false
              },
              "foreground": "#9aa5ce",
              "background": "#1a1b26"
            }
          ]
        }
      ]
    }
    EOF
    chown -R chrisf:users /home/chrisf/.config/oh-my-posh
  '';

  # Programs - PRESERVING YOUR EXISTING CONFIG
  programs = {
    fish.enable = true;
    adb.enable = true;
    virt-manager.enable = true;
    dconf.enable = true;
    gamemode.enable = true;
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
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
    # Hyprland configuration
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };

  # Fonts - PRESERVING YOUR EXISTING CONFIG
  fonts.packages = with pkgs; [
    noto-fonts
    ubuntu_font_family
    noto-fonts-emoji
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    fira
    corefonts
    hack-font
    twemoji-color-font
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.ubuntu
  ];

  # Font configuration for better emoji support
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "Fira Code" "Noto Color Emoji" ];
      sansSerif = [ "Ubuntu" "Noto Color Emoji" ];
      serif = [ "Noto Serif" "Noto Color Emoji" ];
      emoji = [ "Noto Color Emoji" "Twemoji" ];
    };
    localConf = builtins.readFile ./fonts.conf;
  };

  # Environment - PRESERVING YOUR EXISTING CONFIG
  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      GDK_BACKEND = "wayland";
      # Preserve your existing environment variables
      MUTTER_DEBUG_DISABLE_HW_CURSORS = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      # Atuin environment variables
      ATUIN_SESSION = "";
      # Cursor theme for consistency across apps
      XCURSOR_THEME = "Bibata-Modern-Ice";
      # Bluetooth HID support
      BLUETOOTH_HID_DEBUG = "1";
      # Logitech device support
      LOGITECH_DEVICE_DEBUG = "1";
      # XDG integration for proper file associations
      # Set Kitty as default terminal
      TERMINAL = "kitty";
      # Additional terminal-related environment variables
      KITTY_CONFIG_DIRECTORY = "~/.config/kitty";
      KITTY_SHELL_INTEGRATION = "enabled";
    };
  };

  # Prefer Hyprland XDG portal
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      common = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
      };
    };
  };

  # Make Qt apps follow GNOME/GTK settings
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  # Nix settings
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "libsoup-2.74.3"
  ];

  # Systemd user services - PRESERVING YOUR EXISTING CONFIG
  systemd.user.services.sunshine = {
    description = "sunshine";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${config.security.wrapperDir}/sunshine";
      Restart = "always";
    };
    environment = {
      WAYLAND_DISPLAY = "wayland-0";
      XDG_RUNTIME_DIR = "/home/chrisf/tmp";
      XDG_SESSION_TYPE = "wayland";
      WLR_BACKENDS= "headless";
      PULSE_SERVER = "/run/user/1000/pulse/native";
    };
  };

  systemd.user.services.set-github-token = {
    description = "Set GITHUB_TOKEN in systemd --user environment from ~/.config/secrets/github_token";
    after = [ "default.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${setGithubTokenScript}";
    };
  };

  # Solaar service for Logitech device management
  systemd.user.services.solaar = {
    description = "Solaar - Logitech device manager";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.solaar}/bin/solaar --window=hide";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Enable/Disable automatic login for the user - PRESERVING YOUR EXISTING CONFIG
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "chrisf";

  # Workaround for GNOME autologin - PRESERVING YOUR EXISTING CONFIG
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # System version
  system.stateVersion = "24.05";
}