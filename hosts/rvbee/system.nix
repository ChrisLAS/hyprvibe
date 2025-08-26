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
    oh-my-posh
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
    desktop-file-utils
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
    mako
    swaybg
    swayosd
    rofi-wayland
    qt6ct
    pavucontrol
    networkmanagerapplet
    # Shell history replacement
    atuin
    oh-my-posh
    ddcutil
    curl
    openssh
    glib-networking
    rclone
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
    
  ];

  gaming = with pkgs; [
    # steam - now managed by programs.steam
    steam-run
    moonlight-qt
    sunshine
    adwaita-icon-theme
    lutris
    playonlinux
    wineWowPackages.staging
    winetricks
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
    xfce.thunar
    xfce.tumbler
    gvfs
    # Theming packages
    tokyo-night-gtk
    papirus-icon-theme
    bibata-cursors
    adwaita-qt
    adwaita-qt6
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
    ../../modules/shared/packages.nix
    ../../modules/shared/desktop.nix
    ../../modules/shared/hyprland.nix
    ../../modules/shared/waybar.nix
    ../../modules/shared/shell.nix
    ../../modules/shared/services.nix
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

  # Automatic system updates (use flake to avoid channel-based reverts)
  system.autoUpgrade = {
    enable = true;
    flake = "github:ChrisLAS/hyprvibe#rvbee";
    operation = "boot";
    randomizedDelaySec = "45min";
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
    # Keep Netdata unit installed but do not enable it at boot
    services.netdata.wantedBy = pkgs.lib.mkForce [];
    services.netdata.restartIfChanged = false;
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
  };

  # Networking
  networking = {
    hostName = "rvbee";
    networkmanager.enable = true;
    networkmanager.dns = "systemd-resolved";
    firewall = {
      enable = false;
    };
  };

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
    };
    i2c.enable = true;
    steam-hardware.enable = true;
  };

  # Services
  services = {
    fstrim.enable = true;
    resolved.enable = true;
    # Ensure brightnessctl udev rules are active
    udev.packages = [ pkgs.brightnessctl ];
    udisks2.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;
    # Bluetooth manager (tray + UI)
    blueman.enable = true;
    # Network service discovery for "Browse Network" in Thunar and SMB service discovery
    avahi = {
      enable = true;
      nssmdns4 = true;
    };
    # Optional: allow mounting WebDAV as a filesystem (in addition to GVFS WebDAV)
    davfs2.enable = true;
    # Secret Service provider for GVFS credentials (SFTP/SMB/WebDAV)
    gnome.gnome-keyring.enable = true;
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
    cp ${../../configs/hyprland-base.conf} /home/chrisf/.config/hypr/hyprland-base.conf
    cp ${../../configs/hyprland-monitors-rvbee.conf} /home/chrisf/.config/hypr/hyprland-monitors-rvbee.conf
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
    cp ${./scripts/waybar-reboot.sh} /home/chrisf/.config/waybar/scripts/waybar-reboot.sh
    cp ${./scripts/waybar-mpris.sh} /home/chrisf/.config/waybar/scripts/waybar-mpris.sh
    chmod +x /home/chrisf/.config/waybar/scripts/*.sh
    chmod +x /home/chrisf/.config/waybar/scripts/*.py || true
    chown -R chrisf:users /home/chrisf/.config/waybar
    
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
    
    # Configure Oh My Posh default (preserve user-selected theme if present)
    mkdir -p /home/chrisf/.config/oh-my-posh
    cat > /home/chrisf/.config/oh-my-posh/config-default.json << 'EOF'
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
    [ -f /home/chrisf/.config/oh-my-posh/config.json ] || cp /home/chrisf/.config/oh-my-posh/config-default.json /home/chrisf/.config/oh-my-posh/config.json
    
    # Create additional Oh My Posh theme configurations
    cat > /home/chrisf/.config/oh-my-posh/config-enhanced.json << 'EOF'
    {
      "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
      "version": 3,
      "final_space": true,
      "blocks": [
        {
          "type": "prompt",
          "alignment": "left",
          "segments": [
            {
              "type": "root",
              "style": "powerline",
              "background": "#ffe9aa",
              "foreground": "#100e23",
              "powerline_symbol": "\ue0b0",
              "template": " \uf0e7 "
            },
            {
              "type": "session",
              "style": "powerline",
              "background": "#ffffff",
              "foreground": "#100e23",
              "powerline_symbol": "\ue0b0",
              "template": " {{ .UserName }}@{{ .HostName }} "
            },
            {
              "type": "path",
              "style": "powerline",
              "background": "#91ddff",
              "foreground": "#100e23",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "style": "agnoster",
                "max_depth": 2,
                "max_width": 50,
                "folder_icon": "\uf115",
                "home_icon": "\ueb06",
                "folder_separator_icon": " \ue0b1 "
              },
              "template": " {{ .Path }} "
            },
            {
              "type": "git",
              "style": "powerline",
              "background": "#95ffa4",
              "background_templates": [
                "{{ if or (.Working.Changed) (.Staging.Changed) }}#FF9248{{ end }}",
                "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#ff4500{{ end }}",
                "{{ if gt .Ahead 0 }}#B388FF{{ end }}",
                "{{ if gt .Behind 0 }}#B388FF{{ end }}"
              ],
              "foreground": "#193549",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "fetch_status": true,
                "fetch_upstream": true,
                "fetch_upstream_icon": true,
                "display_stash_count": true,
                "branch_template": "{{ trunc 25 .Branch }}"
              },
              "template": " {{ .UpstreamIcon }}{{ .HEAD }}{{ if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }} \ueb4b {{ .StashCount }}{{ end }} "
            },
            {
              "type": "node",
              "style": "powerline",
              "background": "#6CA35E",
              "foreground": "#ffffff",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "fetch_version": true,
                "display_mode": "files"
              },
              "template": " \ue718 {{ if .PackageManagerIcon }}{{ .PackageManagerIcon }} {{ end }}{{ .Full }} "
            },
            {
              "type": "python",
              "style": "powerline",
              "background": "#FFDE57",
              "foreground": "#111111",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "fetch_virtual_env": true,
                "display_version": true,
                "display_mode": "files"
              },
              "template": " \ue235 {{ if .Venv }}{{ .Venv }} {{ end }}{{ .Full }} "
            },
            {
              "type": "go",
              "style": "powerline",
              "background": "#8ED1F7",
              "foreground": "#111111",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "fetch_version": true,
                "display_mode": "files"
              },
              "template": " \ue626 {{ .Full }} "
            },
            {
              "type": "rust",
              "style": "powerline",
              "background": "#FF9E64",
              "foreground": "#111111",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "fetch_version": true,
                "display_mode": "files"
              },
              "template": " \ue7a8 {{ .Full }} "
            },
            {
              "type": "docker_context",
              "style": "powerline",
              "background": "#7aa2f7",
              "foreground": "#1a1b26",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "display_default": false
              },
              "template": " \uf308 {{ .Context }} "
            },
            {
              "type": "execution_time",
              "style": "powerline",
              "background": "#9aa5ce",
              "foreground": "#1a1b26",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "threshold": 5000,
                "style": "text"
              },
              "template": " {{ .FormattedMs }} "
            },
            {
              "type": "exit",
              "style": "powerline",
              "background": "#f7768e",
              "foreground": "#ffffff",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "display_exit_code": true,
                "error_color": "#f7768e",
                "success_color": "#9ece6a"
              },
              "template": " {{ if gt .Code 0 }}\uf071 {{ .Code }}{{ end }} "
            }
          ]
        },
        {
          "type": "rprompt",
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
              "foreground": "#9aa5ce",
              "background": "#1a1b26",
              "properties": {
                "time_format": "15:04",
                "display_date": false
              },
              "template": " {{ .CurrentDate | date .Format }} "
            }
          ]
        }
      ]
    }
    EOF
    
    cat > /home/chrisf/.config/oh-my-posh/config-minimal.json << 'EOF'
    {
      "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
      "version": 3,
      "final_space": true,
      "blocks": [
        {
          "type": "prompt",
          "alignment": "left",
          "segments": [
            {
              "type": "text",
              "style": "plain",
              "foreground": "#98C379",
              "template": "\u279c"
            },
            {
              "type": "path",
              "style": "plain",
              "foreground": "#56B6C2",
              "properties": {
                "style": "folder",
                "max_depth": 2,
                "max_width": 40
              },
              "template": "  {{ .Path }}"
            },
            {
              "type": "git",
              "style": "plain",
              "foreground": "#D0666F",
              "properties": {
                "fetch_status": true,
                "display_stash_count": true
              },
              "template": " <#5FAAE8>git:(</>{{ .HEAD }}<#5FAAE8>)</>"
            },
            {
              "type": "exit",
              "style": "plain",
              "foreground": "#BF616A",
              "template": " {{ if gt .Code 0 }}\u2717{{ end }}"
            }
          ]
        },
        {
          "type": "rprompt",
          "segments": [
            {
              "type": "time",
              "style": "plain",
              "foreground": "#9aa5ce",
              "properties": {
                "time_format": "15:04",
                "display_date": false
              },
              "template": " {{ .CurrentDate | date .Format }}"
            }
          ]
        }
      ]
    }
    EOF
    
    cat > /home/chrisf/.config/oh-my-posh/config-professional.json << 'EOF'
    {
      "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
      "version": 3,
      "final_space": true,
      "blocks": [
        {
          "type": "prompt",
          "alignment": "left",
          "segments": [
            {
              "type": "shell",
              "style": "diamond",
              "background": "#0077c2",
              "foreground": "#ffffff",
              "leading_diamond": "\u256d\u2500\ue0b6",
              "template": "\uf120 {{ .Name }} "
            },
            {
              "type": "root",
              "style": "diamond",
              "background": "#ef5350",
              "foreground": "#FFFB38",
              "template": "<parentBackground>\ue0b0</> \uf292 "
            },
            {
              "type": "path",
              "style": "powerline",
              "background": "#FF9248",
              "foreground": "#2d3436",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "style": "folder",
                "max_depth": 2,
                "max_width": 50,
                "folder_icon": " \uf07b ",
                "home_icon": "\ue617"
              },
              "template": " \uf07b\uea9c {{ .Path }} "
            },
            {
              "type": "git",
              "style": "powerline",
              "background": "#FFFB38",
              "background_templates": [
                "{{ if or (.Working.Changed) (.Staging.Changed) }}#ffeb95{{ end }}",
                "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#c5e478{{ end }}",
                "{{ if gt .Ahead 0 }}#C792EA{{ end }}",
                "{{ if gt .Behind 0 }}#C792EA{{ end }}"
              ],
              "foreground": "#011627",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "fetch_status": true,
                "fetch_upstream": true,
                "fetch_upstream_icon": true,
                "display_stash_count": true,
                "branch_icon": "\ue725 "
              },
              "template": " {{ .UpstreamIcon }}{{ .HEAD }}{{ if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }} \ueb4b {{ .StashCount }}{{ end }} "
            },
            {
              "type": "node",
              "style": "powerline",
              "background": "#6CA35E",
              "foreground": "#ffffff",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "fetch_version": true,
                "display_mode": "files"
              },
              "template": " \ue718 {{ .Full }} "
            },
            {
              "type": "python",
              "style": "powerline",
              "background": "#FFDE57",
              "foreground": "#111111",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "fetch_virtual_env": true,
                "display_version": true,
                "display_mode": "files"
              },
              "template": " \ue235 {{ if .Venv }}{{ .Venv }} {{ end }}{{ .Full }} "
            },
            {
              "type": "go",
              "style": "powerline",
              "background": "#8ED1F7",
              "foreground": "#111111",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "fetch_version": true,
                "display_mode": "files"
              },
              "template": " \ue626 {{ .Full }} "
            },
            {
              "type": "rust",
              "style": "powerline",
              "background": "#FF9E64",
              "foreground": "#111111",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "fetch_version": true,
                "display_mode": "files"
              },
              "template": " \ue7a8 {{ .Full }} "
            },
            {
              "type": "docker_context",
              "style": "powerline",
              "background": "#7aa2f7",
              "foreground": "#1a1b26",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "display_default": false
              },
              "template": " \uf308 {{ .Context }} "
            },
            {
              "type": "execution_time",
              "style": "powerline",
              "background": "#9aa5ce",
              "foreground": "#1a1b26",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "threshold": 5000,
                "style": "text"
              },
              "template": " {{ .FormattedMs }} "
            },
            {
              "type": "exit",
              "style": "powerline",
              "background": "#f7768e",
              "foreground": "#ffffff",
              "powerline_symbol": "\ue0b0",
              "properties": {
                "display_exit_code": true,
                "error_color": "#f7768e",
                "success_color": "#9ece6a"
              },
              "template": " {{ if gt .Code 0 }}\uf071 {{ .Code }}{{ end }} "
            }
          ]
        },
        {
          "type": "rprompt",
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
              "foreground": "#9aa5ce",
              "background": "#1a1b26",
              "properties": {
                "time_format": "15:04",
                "display_date": false
              },
              "template": " {{ .CurrentDate | date .Format }} "
            }
          ]
        }
      ]
    }
    EOF
    
    chown -R chrisf:users /home/chrisf/.config/oh-my-posh
    
    # Create Atuin Fish configuration
    mkdir -p /home/chrisf/.config/fish/conf.d
    cat > /home/chrisf/.config/fish/conf.d/atuin.fish << 'EOF'
    # Atuin shell history integration
    if command -q atuin
      set -g ATUIN_SESSION (atuin uuid)
      atuin init fish | source
    end
    EOF
    
    # Create Oh My Posh Fish configuration
    cat > /home/chrisf/.config/fish/conf.d/oh-my-posh.fish << 'EOF'
    # Oh My Posh prompt configuration
    if command -q oh-my-posh
      # Initialize Oh My Posh with a custom theme
      oh-my-posh init fish --config ~/.config/oh-my-posh/config.json | source
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
    
    chown -R chrisf:users /home/chrisf/.config/fish

    # Hard-override fish prompt to bootstrap Oh My Posh on first prompt draw
    mkdir -p /home/chrisf/.config/fish/functions
    cat > /home/chrisf/.config/fish/functions/fish_prompt.fish << 'EOF'
    function fish_prompt
      if command -q oh-my-posh
        oh-my-posh print primary --config ~/.config/oh-my-posh/config.json
        return
      end
      printf '%s> ' (prompt_pwd)
    end
    EOF
    chown -R chrisf:users /home/chrisf/.config/fish/functions

    # Ensure Oh My Posh is initialized for all interactive Fish sessions
    mkdir -p /home/chrisf/.config/fish
    if ! grep -q "oh-my-posh init fish" /home/chrisf/.config/fish/config.fish 2>/dev/null; then
      cat >> /home/chrisf/.config/fish/config.fish << 'EOF'
    # Initialize Oh My Posh (fallback to ensure prompt loads)
    if status is-interactive
      if command -q oh-my-posh
        oh-my-posh init fish --config ~/.config/oh-my-posh/config.json | source
      end
    end
    EOF
    fi
    # GitHub token export for fish, read from local untracked file if present
    mkdir -p /home/chrisf/.config/secrets
    chown -R chrisf:users /home/chrisf/.config/secrets
    chmod 700 /home/chrisf/.config/secrets
    cat > /home/chrisf/.config/fish/conf.d/github_token.fish << 'EOF'
    if test -r /home/chrisf/.config/secrets/github_token
      set -gx GITHUB_TOKEN (string trim (cat /home/chrisf/.config/secrets/github_token))
    end
    EOF

    # Ensure ~/.local/bin is on PATH for user-installed scripts
    cat > /home/chrisf/.config/fish/conf.d/local-bin.fish << 'EOF'
    if test -d "$HOME/.local/bin"
      fish_add_path "$HOME/.local/bin"
    end
    EOF
    chown -R chrisf:users /home/chrisf/.config/fish
    # Install crypto-price (u3mur4) for Waybar module
    mkdir -p /home/chrisf/.local/bin
    chown -R chrisf:users /home/chrisf/.local
    runuser -s ${pkgs.bash}/bin/bash -l chrisf -c 'GOBIN=$HOME/.local/bin ${pkgs.go}/bin/go install github.com/u3mur4/crypto-price/cmd/crypto-price@latest' || true
    
    # Copy monitor setup helper script
    cp ${../../scripts/setup-monitors.sh} /home/chrisf/.local/bin/setup-monitors
    chmod +x /home/chrisf/.local/bin/setup-monitors


    # Apply GTK theming (Tokyo Night Dark + Papirus-Dark + Bibata cursor)
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

    # Configure qt6ct to use Adwaita-Dark and Papirus icons for closer match
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
    
    # Install Oh My Posh theme switcher
    cat > /home/chrisf/.local/bin/switch-oh-my-posh-theme << 'EOF'
    #!/run/current-system/sw/bin/bash

    # Oh My Posh Theme Switcher
    # Easily switch between different Oh My Posh themes

    THEME_DIR="$HOME/.config/oh-my-posh"
    CURRENT_CONFIG="$THEME_DIR/config.json"

    # Available themes
    THEMES=(
        "default"      # Your current Tokyo Night theme
        "enhanced"     # Feature-rich Agnoster-inspired theme
        "minimal"      # Clean Robby Russell-inspired theme
        "professional" # Modern Atomic-inspired diamond theme
    )

    show_usage() {
        echo "Oh My Posh Theme Switcher"
        echo "========================="
        echo
        echo "Usage: $0 [theme_name]"
        echo
        echo "Available themes:"
        for theme in "''${THEMES[@]}"; do
            echo "  - $theme"
        done
        echo
        echo "Examples:"
        echo "  $0 enhanced    # Switch to enhanced development theme"
        echo "  $0 minimal     # Switch to minimalist theme"
        echo "  $0 professional # Switch to professional diamond theme"
        echo "  $0 default     # Switch back to default theme"
        echo
        echo "Current theme: $(basename $(readlink -f "$CURRENT_CONFIG" 2>/dev/null || echo "config.json"))"
    }

    switch_theme() {
        local theme_name="$1"
        local theme_file="$THEME_DIR/config-''${theme_name}.json"
        
        if [[ "$theme_name" == "default" ]]; then
            theme_file="$THEME_DIR/config.json"
        fi
        
        if [[ ! -f "$theme_file" ]]; then
            echo "Error: Theme '$theme_name' not found at $theme_file"
            echo "Available themes:"
            for theme in "''${THEMES[@]}"; do
                if [[ -f "$THEME_DIR/config-''${theme}.json" ]] || [[ "$theme" == "default" && -f "$CURRENT_CONFIG" ]]; then
                    echo "  - $theme"
                fi
            done
            exit 1
        fi
        
        # Create backup of current config
        if [[ -f "$CURRENT_CONFIG" ]]; then
            cp "$CURRENT_CONFIG" "$THEME_DIR/config-backup-$(date +%Y%m%d-%H%M%S).json"
        fi
        
        # Switch to new theme
        if [[ "$theme_name" == "default" ]]; then
            # Restore original config
            if [[ -f "$THEME_DIR/config-original.json" ]]; then
                cp "$THEME_DIR/config-original.json" "$CURRENT_CONFIG"
            fi
        else
            # Copy theme to main config
            cp "$theme_file" "$CURRENT_CONFIG"
        fi
        
        echo "✅ Switched to '$theme_name' theme"
        echo "🔄 Restart your terminal or run 'exec fish' to see changes"
        echo
        echo "Theme descriptions:"
        echo "  default     - Tokyo Night inspired, balanced features"
        echo "  enhanced    - Feature-rich with comprehensive dev tools"
        echo "  minimal     - Clean, distraction-free for productivity"
        echo "  professional - Modern diamond style for presentations"
    }

    # Main script logic
    if [[ $# -eq 0 ]]; then
        show_usage
        exit 0
    fi

    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi

    switch_theme "$1"
    EOF
    chmod +x /home/chrisf/.local/bin/switch-oh-my-posh-theme
    chown chrisf:users /home/chrisf/.local/bin/switch-oh-my-posh-theme
    
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
    runuser -s ${pkgs.bash}/bin/bash -l chrisf -c '${pkgs.desktop-file-utils}/bin/update-desktop-database ~/.local/share/applications' || true
  '';

  # Programs
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



  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    ubuntu_font_family
    noto-fonts-emoji
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
      # Atuin environment variables
      ATUIN_SESSION = "";
      # Cursor theme for consistency across apps
      XCURSOR_THEME = "Bibata-Modern-Ice";
      # Set Kitty as default terminal
      TERMINAL = "kitty";
      # Additional terminal-related environment variables
      KITTY_CONFIG_DIRECTORY = "~/.config/kitty";
      KITTY_SHELL_INTEGRATION = "enabled";
    };
    systemPackages =
      devTools
      ++ multimedia
      ++ utilities
      ++ systemTools
      ++ applications
      ++ gaming
      ++ gtkApps
      ++ [ pkgs.oh-my-posh ];
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
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
      };
    };
  };

  # Make Qt apps follow GNOME/GTK settings for closer match to GTK theme
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
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
