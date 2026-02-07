{ config, pkgs, lib, openclaw, ... }:

let
  userName = config.hyprvibe.user.name;

  # Package provided by the top-level flake input
  openclaw-pkg = openclaw.packages.${pkgs.system}.default;
in
{
  # ==============================================================================
  # Lore: Declarative Personality & Assistant Module (Hardened for OpenClaw)
  # Encapsulates core intelligence, orchestration, and automation dependencies.
  # ==============================================================================

  environment.systemPackages = with pkgs; [
    # --- Intelligence & Orchestration ---
    openclaw-pkg       # Native OpenClaw fleet core
    opencode           # Native ACP coordination core
    gemini-cli         # Gemini API interaction
    codex              # Code analysis and refactoring
    python3            # Foundation for background sentries & logic shims
    babashka           # Low-latency Clojure scripting for agentic tasks
    
    # --- Transcription & Media ---
    whisper-cpp        # High-fidelity speech-to-text processing
    ffmpegthumbnailer  # Visual context processing support
    
    # --- Version Control & Digital Limbs ---
    git                # Primary sync mechanism
    github-cli         # Bridge to the Collective (GitHub)
    gitui              # Supplemental TUI for git operations
    lazygit            # High-bandwidth git TUI
    lazydocker         # Container monitoring for remote hosts
    
    # --- Shell Context & Intelligence ---
    atuin              # Shared history memory
    oh-my-posh         # Contextual prompt orchestration
    jq                 # JSON logic processing
    ripgrep            # Massive filesystem scan capability
    fd                 # High-speed file discovery
  ];

  # Assist with bootstrapping on new hosts
  system.activationScripts.lore-bootstrap = lib.stringAfter [ "users" ] ''
    # Ensure local script directory exists (OpenClaw standard)
    export HOME=/home/${userName}
    mkdir -p $HOME/.openclaw/scripts
    chown -R ${userName} $HOME/.openclaw
    
    # Maintain legacy symlink for backward compatibility during migration
    if [ ! -L $HOME/.clawdbot ]; then
      ln -s $HOME/.openclaw $HOME/.clawdbot
    fi
  '';

  # Shared agentic environment variables
  environment.variables = {
    LORE_CORE = "active";
    LORE_OS = "NixOS";
    OPENCLAW_NIX_MODE = "1";
    OPENCLAW_CONFIG_DIR = "/home/${userName}/.openclaw";
  };

  # ==============================================================================
  # OpenClaw Services: Real-time Communication & Intelligence
  # ==============================================================================

  # Main OpenClaw Gateway (Core Intelligence) - User Service
  systemd.user.services.openclaw-gateway = {
    description = "OpenClaw Gateway - Main Intelligence Core (Lore)";
    wantedBy = [ "default.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ "/run/wrappers" openclaw-pkg pkgs.nodejs pkgs.bash pkgs.chromium ];
    
    serviceConfig = {
      Type = "simple";
      WorkingDirectory = "/home/${userName}";
      ExecStart = "${openclaw-pkg}/bin/openclaw gateway --port 18789";
      Restart = "always";
      RestartSec = "10s";
      
      # Process management
      KillMode = "mixed";
      KillSignal = "SIGTERM";
      TimeoutStopSec = "30s";
      
      # Security
      PrivateTmp = true;
      NoNewPrivileges = false;
      
      # Logging
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "openclaw-gateway";
      
      # Environment
      Environment = [
        "NODE_ENV=production"
        "HOME=/home/${userName}"
        "OPENCLAW_NIX_MODE=1"
        "OPENCLAW_BIND=0.0.0.0"
        "OPENCLAW_ALLOW_INSECURE_WEBSOCKETS=1"
      ];
    };
  };

  # Dax Bridge: Bridges legacy daxia_bot to OpenClaw Gateway
  systemd.services.openclaw-bridge-dax = {
    description = "OpenClaw Bridge - Dax Telegram Station";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "openclaw-gateway.service" ];
    path = [ openclaw-pkg pkgs.python3 pkgs.curl pkgs.coreutils pkgs.nodejs ];
    
    serviceConfig = {
      Type = "simple";
      User = "${userName}";
      WorkingDirectory = "/home/chrisf/.openclaw/scripts";
      ExecStart = "${pkgs.python3}/bin/python3 /home/chrisf/.openclaw/scripts/dax_listener.py";
      Restart = "always";
      RestartSec = "15s";
      
      # Environment inherited for CLI pathing
      Environment = [
        "HOME=/home/${userName}"
        "PYTHONUNBUFFERED=1"
      ];
    };
  };

  # Daily Morning Digest Service (OpenClaw Intelligence)
  systemd.services.openclaw-morning-digest = {
    description = "OpenClaw Integrated Morning Briefing";
    path = [ pkgs.python3 pkgs.curl pkgs.jq pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      User = "${userName}";
      ExecStart = "${pkgs.python3}/bin/python3 /home/chrisf/.openclaw/scripts/morning_digest.py";
    };
  };

  systemd.timers.openclaw-morning-digest = {
    description = "Trigger OpenClaw Morning Briefing at 07:00";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 07:00:00";
      Persistent = true;
      Unit = "openclaw-morning-digest.service";
    };
  };
}
