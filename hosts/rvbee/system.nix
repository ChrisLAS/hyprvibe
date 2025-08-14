{ config, pkgs, hyprland, ... }:

let
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
    nixfmt-rfc-style
    zed-editor
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
    # reaper
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
    obs-studio
    obs-studio-plugins.obs-pipewire-audio-capture
    # obs-studio-plugins.waveform
    libepoxy
    audacity
    # Additional multimedia tools from Omarchy
    ffmpegthumbnailer
    gnome.gvfs
    imv
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
    vdhcoapp
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
    xdg-utils
    kdePackages.polkit-kde-agent-1
    qt6.qtbase
    qt6.qtwayland
    # Additional Hyprland utilities
    wofi
    dunst
    cliphist
    brightnessctl
    playerctl
    kdePackages.kwallet
    kdePackages.kwallet-pam
    kdePackages.kate
    # Notification daemon
    libnotify
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
    man
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
    polkit_gnome
    libqalculate
    mako
    swaybg
    swayosd
    rofi-wayland
    pavucontrol
    networkmanagerapplet
    # Shell history replacement
    atuin
    ddcutil
    curl
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
    telegram-desktop
    element-desktop
    nextcloud-client
    trayscale
    alacritty
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
    zoxide
    
  ];

  gaming = with pkgs; [
    # steam - now managed by programs.steam
    steam-run
    moonlight-qt
    sunshine
    adwaita-icon-theme
    lutris-free
    playonlinux
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
    # Ebook reader
    foliate
    # Background sounds
    blanket
    # Metadata cleaner
    metadata-cleaner
    # Translation app
    dialect
    # Drawing app
    drawing
  ];
  # Centralized wallpaper path used by hyprpaper and hyprlock
  wallpaperPath = "/home/chrisf/build/config/hosts/rvbee/aesthetic_8_bit_art-wallpaper-3840x2160.jpg";
in
{
  imports = [
    # Import the Hyprland flake module
    hyprland.nixosModules.default
    # Import your hardware configuration
    ./hardware-configuration.nix
  ];

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_zen;
  };

  # System performance and maintenance
  services.btrfs.autoScrub.enable = true;
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 15d";
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # Automatic system updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "02:00";
  };

  # Power management
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };

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
    user.services.kwalletd = {
      description = "KWallet user daemon";
      after = [ "default.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.kdePackages.kwallet}/bin/kwalletd6";
        Restart = "on-failure";
      };
    };
  };

  # Networking
  networking = {
    hostName = "rvbee";
    networkmanager.enable = true;
    firewall = {
      enable = false;
    };
  };

  # Hardware configuration
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        amdvlk
      ];
    };
    i2c.enable = true;
  };

  # Services
  services = {
    fstrim.enable = true;
    # Ensure brightnessctl udev rules are active
    udev.packages = [ pkgs.brightnessctl ];
    udisks2.enable = true;
    # Display manager for Hyprland
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    printing.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
    openssh.enable = true;
    tailscale.enable = true;
    netdata.enable = true;
    flatpak.enable = true;
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
    pam.services = {
      login.kwallet.enable = true;
      gdm.kwallet.enable = true;
      gdm-password.kwallet.enable = true;
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

  # No man pages
  documentation.man.enable = false;

  # User configuration
  users.users.chrisf = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "Chris Fisher";
    linger = true;
    extraGroups = [
      "networkmanager"
      "wheel"
      "adbusers"
      "libvirtd"
      "video"
      "render"
      "audio"
      "docker"
      "i2c"
    ];
    # Create Hyprland configuration directory and copy config
    home = "/home/chrisf";
  };

  # Copy Hyprland configuration to user's home
  system.activationScripts.copyHyprlandConfig = ''
    mkdir -p /home/chrisf/.config/hypr
    cp ${./hyprland.conf} /home/chrisf/.config/hypr/hyprland.conf
    # Render wallpaper path into hyprpaper/hyprlock configs
    ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#${wallpaperPath}#g" ${./hyprpaper.conf} > /home/chrisf/.config/hypr/hyprpaper.conf
    ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#${wallpaperPath}#g" ${./hyprlock.conf} > /home/chrisf/.config/hypr/hyprlock.conf
    cp ${./hypridle.conf} /home/chrisf/.config/hypr/hypridle.conf
    chown -R chrisf:users /home/chrisf/.config/hypr
    # BTC script for hyprlock
    cp ${./scripts/hyprlock-btc.sh} /home/chrisf/.config/hypr/hyprlock-btc.sh
    chmod +x /home/chrisf/.config/hypr/hyprlock-btc.sh
    
    mkdir -p /home/chrisf/.config/waybar
    cp ${./waybar.json} /home/chrisf/.config/waybar/config
    # Theme and scripts for Waybar (cyberpunk aesthetic + custom modules)
    cp ${./waybar.css} /home/chrisf/.config/waybar/style.css
    mkdir -p /home/chrisf/.config/waybar/scripts
    cp ${./scripts/waybar-dunst.sh} /home/chrisf/.config/waybar/scripts/waybar-dunst.sh
    cp ${./scripts/waybar-public-ip.sh} /home/chrisf/.config/waybar/scripts/waybar-public-ip.sh
    cp ${./scripts/waybar-amd-gpu.sh} /home/chrisf/.config/waybar/scripts/waybar-amd-gpu.sh
    cp ${./scripts/waybar-weather.sh} /home/chrisf/.config/waybar/scripts/waybar-weather.sh
    cp ${./scripts/waybar-brightness.sh} /home/chrisf/.config/waybar/scripts/waybar-brightness.sh
    cp ${./scripts/waybar-btc.py} /home/chrisf/.config/waybar/scripts/waybar-btc.py
    # CoinGecko BTC-only
    cp ${./scripts/waybar-btc-coingecko.sh} /home/chrisf/.config/waybar/scripts/waybar-btc-coingecko.sh
    chmod +x /home/chrisf/.config/waybar/scripts/*.sh
    chmod +x /home/chrisf/.config/waybar/scripts/*.py || true
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
    chown -R chrisf:users /home/chrisf/.config/fish
    # GitHub token export for fish, read from local untracked file if present
    mkdir -p /home/chrisf/.config/secrets
    chown -R chrisf:users /home/chrisf/.config/secrets
    chmod 700 /home/chrisf/.config/secrets
    cat > /home/chrisf/.config/fish/conf.d/github_token.fish << 'EOF'
    if test -r /home/chrisf/.config/secrets/github_token
      set -gx GITHUB_TOKEN (string trim (cat /home/chrisf/.config/secrets/github_token))
    end
    EOF
    chown -R chrisf:users /home/chrisf/.config/fish
    # Install crypto-price (u3mur4) for Waybar module
    mkdir -p /home/chrisf/.local/bin
    chown -R chrisf:users /home/chrisf/.local
    runuser -l chrisf -c 'GOBIN=$HOME/.local/bin ${pkgs.go}/bin/go install github.com/u3mur4/crypto-price/cmd/crypto-price@latest' || true
  '';

  # Programs
  programs = {
    fish.enable = true;
    adb.enable = true;
    virt-manager.enable = true;
    dconf.enable = true;
    gamemode.enable = true;
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



  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    ubuntu_font_family
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    fira
  ];

  # Environment
  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      GDK_BACKEND = "wayland";
      # Atuin environment variables
      ATUIN_SESSION = "";
    };
    systemPackages =
      devTools
      ++ multimedia
      ++ utilities
      ++ systemTools
      ++ applications
      ++ gaming
      ++ gtkApps;
  };

  # Prefer Hyprland XDG portal
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    # Hyprland module provides its own portal; include only GTK here to avoid duplicate units
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      common = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
      };
    };
  };

  # Nix settings
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "libsoup-2.74.3"
  ];

  # System version
  system.stateVersion = "23.11";
} 
