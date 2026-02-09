{
  config,
  pkgs,
  openclaw,
  self,
  ...
}:

let
  # Hyprvibe user options (from modules/shared/user.nix)
  userName = config.hyprvibe.user.name;
  userGroup = config.hyprvibe.user.group;
  homeDir = config.hyprvibe.user.home;

  # Package groups
  devTools = with pkgs; [
    gcc
    cmake
    go
    patchelf
    binutils
    nixfmt
    zed-editor
    # Additional development tools from Omarchy
    cargo
    clang
    llvm
    mise
    imagemagick
    mariadb
    postgresql
    kitty
  ];

  multimedia = with pkgs; [
    mpv
    vlc
    ffmpeg-full
    # Optical media (DVD/BluRay) support & tools
    libdvdcss
    libdvdread
    libdvdnav
    libbluray
    libaacs
    # Disc inspection / ripping / conversion
    dvdplusrwtools
    udftools
    xorriso
    makemkv
    handbrake
    lsdvd
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
    # x32edit  # Temporarily removed due to hash mismatch
    # pwvucontrol
    easyeffects
    wayfarer
    # OBS configured via programs.obs-studio with plugins
    # obs-studio-plugins.waveform
    libepoxy
    audacity
    # Additional multimedia tools from Omarchy
    yabridge
    yabridgectl
    lsp-plugins
    ffmpegthumbnailer
    gnome.gvfs
    imv
  ];

  utilities = with pkgs; [
    ghostty
    htop
    btop
    neofetch
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
    android-tools
    lsof
    lshw
    # rustdesk-flutter
    tor-browser
    # lmstudio
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
    sshpass # For automated Home Assistant SSH key setup
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
    libva-utils
    mesa-demos
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
    # Dropbox client (CLI + Qt GUI share the same config in ~/.config/maestral)
    maestral
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
  # Script to setup OpenCode configuration with modular MCP snippets
  setupOpencodeConfigScript = pkgs.writeShellScript "setup-opencode-config" ''
    set -euo pipefail
    
    # 1. Ensure directories exist
    mkdir -p ${homeDir}/.config/opencode
    
    # 2. Base Configuration Template
    BASE_CONFIG='{
      "$schema": "https://opencode.ai/config.json",
      "model": "anthropic/claude-sonnet-4.5",
      "autoupdate": true,
      "theme": "opencode",
      "mcp": {}
    }'

    # 3. Safe Merge using jq
    # Iterates over snippets in /etc/opencode/mcp.d and merges them into the base
    if [ -d "/etc/opencode/mcp.d" ] && [ "$(ls -A /etc/opencode/mcp.d/*.json 2>/dev/null)" ]; then
      MERGED_MCP=$(jq -s 'reduce .[] as $item ({}; . * $item)' /etc/opencode/mcp.d/*.json)
      FINAL_JSON=$(echo "$BASE_CONFIG" | jq --argjson mcp "$MERGED_MCP" '.mcp = $mcp')
    else
      FINAL_JSON="$BASE_CONFIG"
    fi

    # 4. Atomic Deployment
    echo "$FINAL_JSON" > ${homeDir}/.config/opencode/opencode.json.tmp
    if jq . ${homeDir}/.config/opencode/opencode.json.tmp > /dev/null 2>&1; then
      mv ${homeDir}/.config/opencode/opencode.json.tmp ${homeDir}/.config/opencode/opencode.json
      chown ${userName}:${userGroup} ${homeDir}/.config/opencode/opencode.json
    else
      echo "ERROR: Generated JSON is invalid. Aborting update to prevent breakage."
      exit 1
    fi
  '';

  # Script to setup SSH config for remote host management
  setupSshConfigScript = pkgs.writeShellScript "setup-ssh-config" ''
        set -euo pipefail
        mkdir -p ${homeDir}/.ssh
        chmod 700 ${homeDir}/.ssh

        # Generate SSH key if not exists
        if [ ! -f ${homeDir}/.ssh/id_ed25519 ]; then
          ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -C "${userName}@rvbee" -f ${homeDir}/.ssh/id_ed25519 -N ""
        fi

        # Write SSH config for remote hosts
        cat > ${homeDir}/.ssh/config << 'EOF'
    # =============================================================================
    # SSH Configuration for rvbee multi-host management
    # Managed by NixOS - DO NOT EDIT MANUALLY
    # Source: ~/build/config/hosts/rvbee/system.nix
    # =============================================================================

    # Global defaults
    Host *
        AddKeysToAgent yes
        IdentityFile ~/.ssh/id_ed25519
        ServerAliveInterval 60
        ServerAliveCountMax 3
        StrictHostKeyChecking accept-new

    # =============================================================================
    # NixOS Hosts (Managed via hyprvibe flake)
    # =============================================================================

    Host nixbook
        HostName nixbook.coin-noodlefish.ts.net
        User chrisf
        # Laptop - managed by hyprvibe flake

    Host nixstation
        HostName nixstation.coin-noodlefish.ts.net
        User chrisf
        # Workstation - managed by hyprvibe flake

    # =============================================================================
    # NixOS Hosts (Independent configurations)
    # =============================================================================

    Host custodian
        HostName custodian.coin-noodlefish.ts.net
        User chrisf
        # Server - passwordless sudo confirmed
        # Static IP: 172.16.0.10

    Host nodecan-1
        HostName nodecan-1.coin-noodlefish.ts.net
        User chrisf
        # Node - may need sudo configuration

    # =============================================================================
    # Special Network Hosts
    # =============================================================================

    Host doctor
        HostName 192.168.100.2
        User chrisf
        # Nebula VPN only (not on Tailscale)
        # Connection may take longer to establish

    # =============================================================================
    # Ubuntu/Other Hosts
    # =============================================================================

    Host van
        HostName van.trailertrash.io
        User chrisf
        # Ubuntu LTS
        # Note: Tailscale SSH not working, use domain name

    # =============================================================================
    # Appliance Hosts
    # =============================================================================

    Host homeassistant ha
        HostName 172.16.0.116
        User root
        # Home Assistant OS - uses local IP (Tailscale connects to wrong container)
        # Password stored in ~/.config/secrets/homeassistant_password
    EOF
        chmod 600 ${homeDir}/.ssh/config
        chown -R ${userName}:${userGroup} ${homeDir}/.ssh
  '';

  # Script to create SSH helper scripts
  setupSshHelperScriptsScript = pkgs.writeShellScript "setup-ssh-helper-scripts" ''
        set -euo pipefail
        mkdir -p ${homeDir}/.local/bin

        # Create setup-ssh-keys script
        cat > ${homeDir}/.local/bin/setup-ssh-keys << 'SCRIPT'
    #!/usr/bin/env bash
    # Distribute SSH keys to all remote hosts
    # Generated by NixOS configuration

    set -euo pipefail

    echo "SSH Key Distribution Tool"
    echo "=========================="
    echo ""

    # NixOS hosts (use chrisf user)
    NIXOS_HOSTS=(
        "custodian"
        "nixbook"
        "nixstation"
        "nodecan-1"
        "doctor"
    )

    # Ubuntu hosts
    UBUNTU_HOSTS=(
        "van"
    )

    # Setup Home Assistant (automated with sshpass)
    setup_homeassistant() {
        echo ""
        echo "Setting up Home Assistant (automated)..."
        echo "========================================="

        if [ ! -f ~/.config/secrets/homeassistant_password ]; then
            echo "Error: Password file not found at ~/.config/secrets/homeassistant_password"
            return 1
        fi

        if ! command -v sshpass >/dev/null 2>&1; then
            echo "Error: sshpass not installed"
            return 1
        fi

        if sshpass -f ~/.config/secrets/homeassistant_password \
            ssh-copy-id -o StrictHostKeyChecking=accept-new homeassistant 2>/dev/null; then

            if ssh -o BatchMode=yes homeassistant true 2>/dev/null; then
                echo "Home Assistant: SSH key installed successfully"
                return 0
            else
                echo "Home Assistant: Key installed but verification failed"
                return 1
            fi
        else
            echo "Home Assistant: Key installation failed"
            return 1
        fi
    }

    # Main execution
    if [ "$#" -eq 0 ]; then
        echo "Usage: setup-ssh-keys [host|all|homeassistant]"
        echo ""
        echo "Examples:"
        echo "  setup-ssh-keys custodian      # Setup single host"
        echo "  setup-ssh-keys all            # Setup all hosts (interactive)"
        echo "  setup-ssh-keys homeassistant  # Setup HA (automated)"
        echo ""
        echo "Available hosts:"
        echo "  NixOS: custodian nixbook nixstation nodecan-1 doctor"
        echo "  Ubuntu: van"
        echo "  Appliance: homeassistant"
        exit 0
    elif [ "$1" = "homeassistant" ] || [ "$1" = "ha" ]; then
        setup_homeassistant
    elif [ "$1" = "all" ]; then
        echo "Setting up all hosts (you will be prompted for passwords)..."
        echo ""
        for host in "''${NIXOS_HOSTS[@]}" "''${UBUNTU_HOSTS[@]}"; do
            echo "--- $host ---"
            ssh-copy-id "$host" || echo "Failed: $host"
            echo ""
        done
        setup_homeassistant
    else
        for host in "$@"; do
            echo "Setting up: $host"
            ssh-copy-id "$host"
        done
    fi
    SCRIPT
        chmod +x ${homeDir}/.local/bin/setup-ssh-keys

        # Create check-remote-sudo script
        cat > ${homeDir}/.local/bin/check-remote-sudo << 'SCRIPT'
    #!/usr/bin/env bash
    # Check sudo configuration on all remote hosts
    # Generated by NixOS configuration

    set -euo pipefail

    HOSTS=(
        "custodian"
        "nixbook"
        "nixstation"
        "nodecan-1"
        "doctor"
        "van"
    )

    echo "Checking passwordless sudo on all hosts..."
    echo "==========================================="
    echo ""

    for host in "''${HOSTS[@]}"; do
        printf "%-15s " "$host:"

        # First check if we can SSH at all
        if ! ssh -o BatchMode=yes -o ConnectTimeout=10 "$host" "true" 2>/dev/null; then
            echo "Cannot connect (check SSH keys or network)"
            continue
        fi

        # Check sudo
        if ssh -o BatchMode=yes "$host" "sudo -n true 2>/dev/null" 2>/dev/null; then
            echo "Passwordless sudo ENABLED"
        else
            echo "Passwordless sudo DISABLED - needs configuration"
        fi
    done

    echo ""
    echo "homeassistant:  N/A (root user - no sudo needed)"
    echo ""
    echo "==========================================="
    SCRIPT
        chmod +x ${homeDir}/.local/bin/check-remote-sudo

        # Create ssh-ha script
        cat > ${homeDir}/.local/bin/ssh-ha << 'SCRIPT'
    #!/usr/bin/env bash
    # SSH to Home Assistant with automatic password fallback
    # Generated by NixOS configuration

    # Try key-based auth first
    if ssh -o BatchMode=yes -o ConnectTimeout=5 homeassistant "$@" 2>/dev/null; then
        exit 0
    fi

    # Fall back to password if key auth failed
    if [ -f ~/.config/secrets/homeassistant_password ] && command -v sshpass >/dev/null 2>&1; then
        sshpass -f ~/.config/secrets/homeassistant_password ssh homeassistant "$@"
    else
        echo "Error: Cannot connect to Home Assistant" >&2
        echo "- Key auth failed" >&2
        echo "- Password file not found or sshpass not installed" >&2
        exit 1
    fi
    SCRIPT
        chmod +x ${homeDir}/.local/bin/ssh-ha

        # Create remote-exec script
        cat > ${homeDir}/.local/bin/remote-exec << 'SCRIPT'
    #!/usr/bin/env bash
    # Execute commands on multiple remote hosts
    # Generated by NixOS configuration

    set -euo pipefail

    ALL_HOSTS=(custodian nixbook nixstation nodecan-1 doctor van)
    NIXOS_HOSTS=(custodian nixbook nixstation nodecan-1 doctor)

    usage() {
        echo "Usage: remote-exec [--all|--nixos|host1 host2 ...] \"command\""
        echo ""
        echo "Examples:"
        echo "  remote-exec --all \"hostname\""
        echo "  remote-exec --nixos \"nixos-rebuild --version\""
        echo "  remote-exec custodian nixbook \"uptime\""
        echo ""
        echo "Hosts:"
        echo "  --all:   ''${ALL_HOSTS[*]}"
        echo "  --nixos: ''${NIXOS_HOSTS[*]}"
    }

    if [ "$#" -lt 2 ]; then
        usage
        exit 1
    fi

    # Parse arguments
    HOSTS=()
    CMD=""

    case "$1" in
        --all)
            HOSTS=("''${ALL_HOSTS[@]}")
            shift
            CMD="$*"
            ;;
        --nixos)
            HOSTS=("''${NIXOS_HOSTS[@]}")
            shift
            CMD="$*"
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            # Collect hosts until we hit a command (starts with non-host char or has spaces)
            while [ "$#" -gt 1 ]; do
                HOSTS+=("$1")
                shift
            done
            CMD="$1"
            ;;
    esac

    echo "Executing on: ''${HOSTS[*]}"
    echo "Command: $CMD"
    echo "==========================================="
    echo ""

    for host in "''${HOSTS[@]}"; do
        echo "--- $host ---"
        if ssh -o BatchMode=yes -o ConnectTimeout=10 "$host" "$CMD" 2>&1; then
            echo ""
        else
            echo "Failed to execute on $host"
            echo ""
        fi
    done
    SCRIPT
        chmod +x ${homeDir}/.local/bin/remote-exec

        chown -R ${userName}:${userGroup} ${homeDir}/.local/bin
  '';
  # Script to set AMD EPP to performance at boot across all policies
  setEppPerformanceScript = pkgs.writeShellScript "set-epp-performance" ''
    set -euo pipefail
    for p in /sys/devices/system/cpu/cpufreq/policy*; do
      f="$p/energy_performance_preference"
      if [ -w "$f" ]; then
        echo performance > "$f"
      fi
    done
  '';
in
{
  imports = [
    # Import your hardware configuration
    ./hardware-configuration.nix
    # Shared scaffolding (non-host-specific)
    ../../modules/shared
    ./lore.nix
  ];

  # Enable shared module toggles
  hyprvibe.desktop = {
    enable = true;
    fonts.enable = true;
  };
  hyprvibe.hyprland.enable = true;
  # Provide per-host monitors and wallpaper paths to shared module
  hyprvibe.hyprland.monitorsFile = ../../configs/hyprland-monitors-rvbee-120hz.conf;
  hyprvibe.hyprland.mainConfig = ./hyprland.conf;
  hyprvibe.hyprland.wallpaper = wallpaperPath;
  hyprvibe.hyprland.hyprpaperTemplate = ./hyprpaper.conf;
  hyprvibe.hyprland.hyprlockTemplate = ./hyprlock.conf;
  hyprvibe.hyprland.hypridleConfig = ./hypridle.conf;
  hyprvibe.hyprland.scriptsDir = ./scripts;
  hyprvibe.hyprland.amd.enable = true;
  hyprvibe.waybar.enable = true;
  hyprvibe.waybar.configPath = ./waybar.json;
  hyprvibe.waybar.stylePath = ./waybar.css;
  hyprvibe.waybar.scriptsDir = ./scripts;
  hyprvibe.system.enable = true;
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
  hyprvibe.services = {
    enable = true;

    virt.enable = true;
    docker.enable = true;
    nebula = {
      enable = true;
      nebulaIp = "192.168.100.10/24";
    };
  };

  # Define modular MCP snippets for opencode
  environment.etc = {
    "opencode/mcp.d/nixos.json".text = builtins.toJSON {
      nixos = {
        type = "local";
        command = ["nix" "run" "github:utensils/mcp-nixos" "--"];
        enabled = true;
      };
    };
    "opencode/mcp.d/obsidian.json".text = builtins.toJSON {
      obsidian = {
        type = "local";
        command = ["uvx" "mcp-obsidian"];
        env = {
           OBSIDIAN_API_KEY = "$(cat /home/chrisf/.config/secrets/obsidian_mcp_key)"; # Note: Shell expansion handled by assembly script
           OBSIDIAN_PORT = "27124";
           OBSIDIAN_HOST = "127.0.0.1";
        };
        enabled = true;
      };
    };
    "opencode/mcp.d/context7.json".text = builtins.toJSON {
      context7 = {
        type = "remote";
        url = "https://mcp.context7.com/mcp";
        enabled = true;
      };
    };
    "opencode/mcp.d/proxmox.json".text = builtins.toJSON {
      proxmox = {
        type = "local";
        command = ["nix" "run" "github:RekklesNA/ProxmoxMCP-Plus" "--"];
        env = {
           PROXMOX_HOST = "100.120.212.39";
           PROXMOX_USER = "root@pam";
           PROXMOX_TOKEN_NAME = "lore-mcp";
           PROXMOX_TOKEN_VALUE = "$(cat /home/chrisf/.config/secrets/proxmox_mcp_key)"; 
           PROXMOX_PORT = "8006";
           PROXMOX_VERIFY_SSL = "false";
        };
        enabled = true;
      };
    };
  };

  # Android ADB udev support now covered by systemd uaccess rules; keep brightnessctl
  services.udev.packages = [ pkgs.brightnessctl ];
  services.udev.extraRules = ''
    # Elgato Stream Deck (USB + hidraw)
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", MODE="0660", GROUP="plugdev"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0fd9", MODE="0660", GROUP="plugdev"

    # Optical drives (DVD/BluRay): allow the active user (seat) to access SCSI generic nodes.
    # Needed for tools like MakeMKV which use /dev/sg* (scsi_generic) in addition to /dev/sr*.
    SUBSYSTEM=="scsi_generic", ATTRS{type}=="5", TAG+="uaccess", GROUP="cdrom", MODE="0660"
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
    # Add extra debug output so kernel / systemd messages are visible on console.
    # Use panic=0 to avoid automatic reboot on panic so we can see the full trace.
    kernelParams = [
      "tsc=unstable"
      "debug"
      "ignore_loglevel"
      "log_buf_len=4M"
      "panic=0"
      "systemd.log_level=debug"
      "systemd.log_target=console"
    ];
    consoleLogLevel = 7;
    initrd.verbose = true;
    # v4l2loopback for virtual webcam support (OBS, conferencing apps)
    # sg is required to create /dev/sg* nodes (SCSI generic), used by MakeMKV and some disc tools.
    kernelModules = [
      "v4l2loopback"
      "sg"
    ];
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    extraModprobeConfig = ''
      # Dedicated virtual camera for OBS capture, fixed at /dev/video10
      options v4l2loopback video_nr=10 exclusive_caps=1 card_label=OBS-VirtualCam
    '';
  };

  # System performance settings moved to shared module

  # Automatic system updates (use flake to avoid channel-based reverts)
  system.autoUpgrade = {
    enable = true;
    flake = "github:ChrisLAS/hyprvibe#rvbee";
    operation = "boot";
    randomizedDelaySec = "45min";
    allowReboot = false;
    dates = "02:00";
  };

  # Power management provided by shared module

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
    # Set AMD EPP to performance on boot
    services.set-epp-performance = {
      description = "Set AMD EPP to performance for all CPU policies";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${setEppPerformanceScript}";
        RemainAfterExit = true;
      };
    };
    # Keep Netdata unit installed but do not enable it at boot
    services.netdata.wantedBy = pkgs.lib.mkForce [ ];
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

    # Write dunst config in the user's home *after login* (NOT during activation).
    # Boot-time activation runs very early; failures there can terminate PID 1 and kernel panic.
    user.services.hyprvibe-setup-dunst = {
      description = "Hyprvibe: write dunst config";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.writeShellScript "hyprvibe-setup-dunst" ''
          set -euo pipefail
          mkdir -p ${homeDir}/.config/dunst
          cat > ${homeDir}/.config/dunst/dunstrc << 'EOF'
          [global]
          follow = mouse
          history_length = 20
          indicate_hidden = yes
          separator_height = 2
          sort = yes
          idle_threshold = 0
          # Fallback timeout (seconds); urgency-specific values override this.
          timeout = 60

          [urgency_low]
          timeout = 60

          [urgency_normal]
          timeout = 60

          [urgency_critical]
          timeout = 60

          # Suppress noisy Bluetooth device connect/disconnect popups from Blueman
          [bluetooth_blueman_connected]
          appname = "Blueman"
          summary = ".*(Connected|Disconnected).*"
          skip_display = true
          skip_history = true

          # Some environments label as "Bluetooth"
          [bluetooth_generic_connected]
          appname = "Bluetooth"
          summary = ".*(Connected|Disconnected).*"
          skip_display = true
          skip_history = true
          EOF
        ''}";
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

    # Setup OpenCode configuration with MCP servers
    user.services.setup-opencode-config = {
      description = "Setup OpenCode configuration with MCP servers";
      after = [ "default.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${setupOpencodeConfigScript}";
      };
    };

    # Setup SSH config for remote host management
    user.services.setup-ssh-config = {
      description = "Setup SSH config for remote host management";
      after = [ "default.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${setupSshConfigScript}";
      };
    };

    # Setup SSH helper scripts (setup-ssh-keys, check-remote-sudo, ssh-ha, remote-exec)
    user.services.setup-ssh-helper-scripts = {
      description = "Setup SSH helper scripts for remote host management";
      after = [ "default.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${setupSshHelperScriptsScript}";
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
  # Speed up boot: disable NetworkManager-wait-online blocking service
  systemd.services."NetworkManager-wait-online".enable = false;

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
    resolved.enable = true;
    # Desktop support services moved to shared module (udisks2, gvfs, tumbler, blueman, avahi, davfs2, gnome-keyring, gdm)
    printing.enable = true;

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

  # No man pages handled by shared module

  # User configuration handled by hyprvibe.user

  # Podman + declarative containers
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

  # Crabwalk Monitor (Next.js Application)
  virtualisation.oci-containers.containers.crabwalk = {
    image = "ghcr.io/luccast/crabwalk:latest";
    autoStart = true;
    ports = [
      "3000:3000"
    ];
    environmentFiles = [
      "/home/chrisf/.config/secrets/openclaw-crabwalk.env"
    ];
    environment = {
      # Explicitly point to the gateway on the host's loopback from the container's perspective
      OPENCLAW_GATEWAY_URL = "ws://100.120.88.96:18789";
    };
    extraOptions = [
      "--network=host"
    ];
    volumes = [
      # Consolidated OpenClaw workspace path
      "/home/chrisf/.openclaw/workspace-main:/root/.openclaw/workspace"
    ];
    labels = {
      "io.containers.autoupdate" = "registry";
    };
  };

  # Ensure persistent data directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/companion 0777 root root -"
    # Disable CoW on directories that benefit from it (databases, VMs, downloads)
    "d /var/lib/docker 0755 root root -"
    "d /var/lib/libvirt 0755 root root -"
    "d /home/chrisf/Downloads 0755 chrisf users -"
    "d /home/chrisf/.steam 0755 chrisf users -"
    "d /home/chrisf/.local/share/Steam 0755 chrisf users -"
    "d /tmp 1777 root root -"
    "d /var/tmp 1777 root root -"
  ];

  # Open firewall for Companion
  networking.firewall.allowedTCPPorts = (config.networking.firewall.allowedTCPPorts or [ ]) ++ [
    8000
    51234
  ];

  # Disable CoW on specific directories for better performance
  systemd.services.disable-cow = {
    description = "Disable Copy-on-Write on specific directories";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/chattr +C /var/lib/docker /var/lib/libvirt /home/chrisf/Downloads /home/chrisf/.steam /home/chrisf/.local/share/Steam /tmp /var/tmp 2>/dev/null || true'";
      RemainAfterExit = true;
    };
  };
  networking.firewall.allowedUDPPorts = (config.networking.firewall.allowedUDPPorts or [ ]) ++ [
    51234
  ];

  # Copy Hyprland configuration to user's home
  # Disabled: migrated to hyprvibe.hyprland options
  system.activationScripts.copyHyprlandConfig_disabled = ''
    # Legacy Hyprland/Waybar/kitty/Oh My Posh setup script disabled.
    # All of these configs are now managed by hyprvibe.hyprland, hyprvibe.waybar, and hyprvibe.shell.
    # Keep the original body below for reference only; it is never executed.
    # IMPORTANT: Never use `exit` in activation scripts; if sourced by stage-2 init
    # it can terminate PID 1 and kernel-panic the boot.
    if false; then
    # BTC script for hyprlock
    cp --remove-destination ${./scripts/hyprlock-btc.sh} ${homeDir}/.config/hypr/hyprlock-btc.sh
    chmod +x ${homeDir}/.config/hypr/hyprlock-btc.sh

    mkdir -p ${homeDir}/.config/waybar
    cp --remove-destination ${./waybar.json} ${homeDir}/.config/waybar/config
    # Theme and scripts for Waybar (cyberpunk aesthetic + custom modules)
    cp --remove-destination ${./waybar.css} ${homeDir}/.config/waybar/style.css
    mkdir -p ${homeDir}/.config/waybar/scripts
    cp --remove-destination ${./scripts/waybar-dunst.sh} ${homeDir}/.config/waybar/scripts/waybar-dunst.sh
    cp --remove-destination ${./scripts/waybar-public-ip.sh} ${homeDir}/.config/waybar/scripts/waybar-public-ip.sh
    cp --remove-destination ${./scripts/waybar-amd-gpu.sh} ${homeDir}/.config/waybar/scripts/waybar-amd-gpu.sh
    cp --remove-destination ${./scripts/waybar-openrouter.sh} ${homeDir}/.config/waybar/scripts/waybar-openrouter.sh
    cp --remove-destination ${./scripts/waybar-brightness.sh} ${homeDir}/.config/waybar/scripts/waybar-brightness.sh
    cp --remove-destination ${./scripts/waybar-btc.py} ${homeDir}/.config/waybar/scripts/waybar-btc.py
    # CoinGecko BTC-only
    cp --remove-destination ${./scripts/waybar-btc-coingecko.sh} ${homeDir}/.config/waybar/scripts/waybar-btc-coingecko.sh
    cp --remove-destination ${./scripts/waybar-reboot.sh} ${homeDir}/.config/waybar/scripts/waybar-reboot.sh
    cp --remove-destination ${./scripts/waybar-mpris.sh} ${homeDir}/.config/waybar/scripts/waybar-mpris.sh
    chmod +x ${homeDir}/.config/waybar/scripts/*.sh
    chmod +x ${homeDir}/.config/waybar/scripts/*.py || true
    chown -R ${userName}:${userGroup} ${homeDir}/.config/waybar

    # Configure Kitty terminal
    mkdir -p ${homeDir}/.config/kitty
    cat > ${homeDir}/.config/kitty/kitty.conf << 'EOF'
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
    chown -R ${userName}:${userGroup} ${homeDir}/.config/kitty

    # Configure Oh My Posh default (preserve user-selected theme if present)
    mkdir -p ${homeDir}/.config/oh-my-posh
    cat > ${homeDir}/.config/oh-my-posh/config-default.json << 'EOF'
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
    [ -f ${homeDir}/.config/oh-my-posh/config.json ] || cp ${homeDir}/.config/oh-my-posh/config-default.json ${homeDir}/.config/oh-my-posh/config.json

    # Create additional Oh My Posh theme configurations
    cat > ${homeDir}/.config/oh-my-posh/config-enhanced.json << 'EOF'
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

    cat > ${homeDir}/.config/oh-my-posh/config-minimal.json << 'EOF'
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

    cat > ${homeDir}/.config/oh-my-posh/config-professional.json << 'EOF'
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

    chown -R ${userName}:${userGroup} ${homeDir}/.config/oh-my-posh

    # Create Atuin Fish configuration
    mkdir -p ${homeDir}/.config/fish/conf.d
    cat > ${homeDir}/.config/fish/conf.d/atuin.fish << 'EOF'
    # Atuin shell history integration
    if command -q atuin
      set -g ATUIN_SESSION (atuin uuid)
      atuin init fish | source
    end
    EOF

    # Create Oh My Posh Fish configuration
    cat > ${homeDir}/.config/fish/conf.d/oh-my-posh.fish << 'EOF'
    # Oh My Posh prompt configuration
    if command -q oh-my-posh
      # Initialize Oh My Posh with a custom theme
      oh-my-posh init fish --config ~/.config/oh-my-posh/config.json | source
    end
    EOF

    # Additional Fish configuration for better integration
    cat > ${homeDir}/.config/fish/conf.d/kitty-integration.fish << 'EOF'
    # Kitty terminal integration
    if test "$TERM" = "xterm-kitty"
      # Enable kitty shell integration
      kitty + complete setup fish | source
      
      # Set kitty-specific environment variables
      set -gx KITTY_SHELL_INTEGRATION enabled
    end
    EOF

    chown -R ${userName}:${userGroup} ${homeDir}/.config/fish

    # Hard-override fish prompt to bootstrap Oh My Posh on first prompt draw
    mkdir -p ${homeDir}/.config/fish/functions
    cat > ${homeDir}/.config/fish/functions/fish_prompt.fish << 'EOF'
    function fish_prompt
      if command -q oh-my-posh
        oh-my-posh print primary --config ~/.config/oh-my-posh/config.json
        return
      end
      printf '%s> ' (prompt_pwd)
    end
    EOF
    chown -R ${userName}:${userGroup} ${homeDir}/.config/fish/functions

    # Ensure Oh My Posh is initialized for all interactive Fish sessions
    mkdir -p ${homeDir}/.config/fish
    if ! grep -q "oh-my-posh init fish" ${homeDir}/.config/fish/config.fish 2>/dev/null; then
      cat >> ${homeDir}/.config/fish/config.fish << 'EOF'
    # Initialize Oh My Posh (fallback to ensure prompt loads)
    if status is-interactive
      if command -q oh-my-posh
        oh-my-posh init fish --config ~/.config/oh-my-posh/config.json | source
      end
    end
    EOF
    fi
    # GitHub token export for fish, read from local untracked file if present
    mkdir -p ${homeDir}/.config/secrets
    chown -R ${userName}:${userGroup} ${homeDir}/.config/secrets
    chmod 700 ${homeDir}/.config/secrets
    cat > ${homeDir}/.config/fish/conf.d/github_token.fish << 'EOF'
    if test -r ${homeDir}/.config/secrets/github_token
      set -gx GITHUB_TOKEN (string trim (cat ${homeDir}/.config/secrets/github_token))
    end
    EOF

    # Ensure ~/.local/bin is on PATH for user-installed scripts
    cat > ${homeDir}/.config/fish/conf.d/local-bin.fish << 'EOF'
    if test -d "$HOME/.local/bin"
      fish_add_path "$HOME/.local/bin"
    end
    EOF
    chown -R ${userName}:${userGroup} ${homeDir}/.config/fish
    # Install crypto-price (u3mur4) for Waybar module
    mkdir -p ${homeDir}/.local/bin
    chown -R ${userName}:${userGroup} ${homeDir}/.local
    runuser -s ${pkgs.bash}/bin/bash -l ${userName} -c 'GOBIN=$HOME/.local/bin ${pkgs.go}/bin/go install github.com/u3mur4/crypto-price/cmd/crypto-price@latest' || true

    # Copy monitor setup helper script
    cp ${../../scripts/setup-monitors.sh} ${homeDir}/.local/bin/setup-monitors
    chmod +x ${homeDir}/.local/bin/setup-monitors

    # OBS placement helper removed (clip-player deprecated)

    # clip-player script removed (deprecated)


    # Apply GTK theming (Tokyo Night Dark + Papirus-Dark + Bibata cursor)
    mkdir -p ${homeDir}/.config/gtk-3.0
    cat > ${homeDir}/.config/gtk-3.0/settings.ini << 'EOF'
    [Settings]
    gtk-theme-name=Tokyonight-Dark-B
    gtk-icon-theme-name=Papirus-Dark
    gtk-cursor-theme-name=Bibata-Modern-Ice
    gtk-cursor-theme-size=24
    gtk-application-prefer-dark-theme=true
    EOF
    mkdir -p ${homeDir}/.config/gtk-4.0
    cat > ${homeDir}/.config/gtk-4.0/settings.ini << 'EOF'
    [Settings]
    gtk-theme-name=Tokyonight-Dark-B
    gtk-icon-theme-name=Papirus-Dark
    gtk-cursor-theme-name=Bibata-Modern-Ice
    gtk-cursor-theme-size=24
    gtk-application-prefer-dark-theme=true
    EOF
    chown -R ${userName}:${userGroup} ${homeDir}/.config/gtk-3.0 ${homeDir}/.config/gtk-4.0

    # Configure qt6ct to use Adwaita-Dark and Papirus icons for closer match
    mkdir -p ${homeDir}/.config/qt6ct
    cat > ${homeDir}/.config/qt6ct/qt6ct.conf << 'EOF'
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
    chown -R ${userName}:${userGroup} ${homeDir}/.config/qt6ct
    # Install rofi brightness menu
    install -m 0755 ${./scripts/rofi-brightness.sh} ${homeDir}/.local/bin/rofi-brightness
    chown ${userName}:${userGroup} ${homeDir}/.local/bin/rofi-brightness

    # Install Oh My Posh theme switcher
    cat > ${homeDir}/.local/bin/switch-oh-my-posh-theme << 'EOF'
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
    chmod +x ${homeDir}/.local/bin/switch-oh-my-posh-theme
    chown ${userName}:${userGroup} ${homeDir}/.local/bin/switch-oh-my-posh-theme

    # Set Kitty as default terminal in desktop environment
    mkdir -p ${homeDir}/.local/share/applications
    cat > ${homeDir}/.local/share/applications/kitty.desktop << 'EOF'
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
    chown ${userName}:${userGroup} ${homeDir}/.local/share/applications/kitty.desktop

    # Update desktop database to register Kitty and ClipPlayer
    runuser -s ${pkgs.bash}/bin/bash -l chrisf -c '${pkgs.desktop-file-utils}/bin/update-desktop-database ~/.local/share/applications' || true

    # ClipPlayer desktop entry for file associations
    cat > ${homeDir}/.local/share/applications/clip-player.desktop << 'EOF'
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=ClipPlayer
    GenericName=Media Player
    Comment=Launch MPV with a stable title for OBS capture
    Exec=${homeDir}/.local/bin/clip-player %U
    Icon=mpv
    Terminal=false
    Categories=AudioVideo;Video;Player;
    MimeType=video/mp4;video/x-matroska;video/webm;video/x-msvideo;video/quicktime;video/ogg;audio/mpeg;audio/mp3;audio/ogg;audio/flac;audio/x-flac;audio/wav;audio/x-wav;application/ogg;
    EOF
    chown ${userName}:${userGroup} ${homeDir}/.local/share/applications/clip-player.desktop

    # Set ClipPlayer as default for common media MIME types
    mkdir -p ${homeDir}/.config
    cat > ${homeDir}/.config/mimeapps.list << 'EOF'
    [Default Applications]
    x-scheme-handler/http=firefox.desktop
    x-scheme-handler/https=firefox.desktop
    text/html=firefox.desktop
    video/mp4=mpv.desktop
    video/x-matroska=mpv.desktop
    video/webm=mpv.desktop
    video/x-msvideo=mpv.desktop
    video/quicktime=mpv.desktop
    video/ogg=mpv.desktop
    audio/mpeg=mpv.desktop
    audio/mp3=mpv.desktop
    audio/ogg=mpv.desktop
    audio/flac=mpv.desktop
    audio/x-flac=mpv.desktop
    audio/wav=mpv.desktop
    audio/x-wav=mpv.desktop
    application/ogg=mpv.desktop
    EOF
    chown ${userName}:${userGroup} ${homeDir}/.config/mimeapps.list
    fi
  '';

  # Programs
  programs = {
    virt-manager.enable = true;
    dconf.enable = true;
    gamemode.enable = true;
    firefox = {
      enable = true;
      package = pkgs.firefox;
      preferences = {
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "widget.wayland-dmabuf-vaapi.enabled" = true;
        "media.rdd-ffmpeg.enabled" = true;
        "media.hardware-video-decoding.enabled" = true;
      };
    };
    thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
    steam = {
      enable = true;
      # Steam Link + SteamVR tips for Hyprland/Wayland:
      # - Force PipeWire capture (`-pipewire`) to avoid "Desktop capture unavailable".
      # - Prefer X11 Qt backend for SteamVR helpers (avoids missing Qt "wayland" plugin issues).
      # - Ensure some host tools/libs exist inside the Steam runtime container (pressure-vessel).
      package = pkgs.steam.override {
        extraArgs = "-pipewire";
        extraEnv = {
          QT_QPA_PLATFORM = "xcb";
        };
        # Binaries needed inside the Steam runtime container
        extraPkgs =
          pkgs': with pkgs'; [
            psmisc # provides `killall`
          ];
        # Shared libs needed inside the Steam runtime container
        extraLibraries =
          pkgs': with pkgs'; [
            gamemode # provides libgamemode.so (fixes gamemodeauto dlopen failed)
          ];
        # Help SteamVR's vrwebhelper locate its own shipped libs (libcef.so, etc.)
        extraProfile = ''
          export LD_LIBRARY_PATH="''${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$HOME/.local/share/Steam/steamapps/common/SteamVR/bin/vrwebhelper/linux64:$HOME/.local/share/Steam/steamapps/common/SteamVR/bin/linux64"
        '';
      };
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
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      OZONE_PLATFORM = "wayland";
      LIBVA_DRIVER_NAME = "radeonsi";
      MOZ_DISABLE_RDD_SANDBOX = "1";
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

  system.configurationRevision = self.rev or "dirty";

  # Kernel/VM tuning and CPU governor override for mobile AMD APU
  powerManagement.cpuFreqGovernor = pkgs.lib.mkForce "schedutil";
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 10;
    # Never auto-reboot on kernel panic so we can capture the panic screen.
    "kernel.panic" = 0;
  };

  # Dunst config is written by `systemd.user.services.hyprvibe-setup-dunst` (see above),
  # not during early-boot activation.

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
  system.stateVersion = "23.11";
}
