{
  config,
  pkgs,
  lib,
  openclaw,
  ...
}:

let
  userName = config.hyprvibe.user.name;

  # Package provided by the top-level flake input
  openclaw-pkg = openclaw.packages.${pkgs.system}.default;

  # Python environment for embedding service
  embeddingPython = pkgs.python3.withPackages (ps: with ps; [
    fastapi
    uvicorn
    sentence-transformers
    pydantic
    httpx
    torch
    numpy
  ]);
in
{
  # ==============================================================================
  # Lore: Declarative Personality & Assistant Module (Hardened for OpenClaw)
  # Encapsulates core intelligence, orchestration, and automation dependencies.
  # ==============================================================================

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
  # Vector Memory: Self-Hosted Qdrant + Embedding Service (Replaces Voyage AI)
  # ==============================================================================

  # Enable Qdrant vector database
  services.qdrant = {
    enable = true;
    settings = {
      storage = {
        storage_type = "mmap"; # Memory-mapped for efficiency on Ryzen 5700U
      };
      service = {
        http_port = 6333;
        grpc_port = 6334;
        host = "127.0.0.1"; # localhost only for security
      };
      telemetry_disabled = true; # Privacy: disable telemetry
      log_level = "INFO";
    };
  };

  # Embedding Service User
  users.users.embedding-service = {
    isSystemUser = true;
    group = "embedding-service";
    home = "/var/lib/embedding-service";
    createHome = true;
    description = "Embedding service for vector memory";
  };
  users.groups.embedding-service = { };

  # Embedding service directories
  systemd.tmpfiles.rules = [
    "d /var/lib/embedding-service 0755 embedding-service embedding-service -"
    "d /var/cache/embedding-service 0755 embedding-service embedding-service -"
    "d /var/cache/embedding-service/huggingface 0755 embedding-service embedding-service -"
    "d /var/cache/embedding-service/transformers 0755 embedding-service embedding-service -"
  ];

  # Embedding Service Package (Python + FastAPI + sentence-transformers)
  systemd.services.embedding-service = {
    description = "Embedding Service - all-MiniLM-L6-v2 via sentence-transformers";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "simple";
      User = "embedding-service";
      Group = "embedding-service";
      WorkingDirectory = "/var/lib/embedding-service";

      # Start script that downloads model and runs FastAPI
      ExecStart = pkgs.writeShellScript "embedding-service-start" ''
        export HF_HOME=/var/cache/embedding-service/huggingface
        export TRANSFORMERS_CACHE=/var/cache/embedding-service/transformers
        export SENTENCE_TRANSFORMERS_HOME=/var/cache/embedding-service/sentence-transformers
        export HF_TOKEN_FILE=/etc/secrets/huggingface_token

        # Run embedding server
        ${embeddingPython}/bin/python ${./embedding-service/app.py}
      '';

      Restart = "always";
      RestartSec = "10s";

      # Resource limits appropriate for Ryzen 5700U
      MemoryMax = "512M";
      CPUQuota = "200%"; # 2 cores max

      # Security hardening
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [
        "/var/cache/embedding-service"
        "/var/lib/embedding-service"
      ];

      # Logging
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "embedding-service";
    };

    environment = {
      PYTHONUNBUFFERED = "1";
      EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2";
      EMBEDDING_PORT = "18000";
      EMBEDDING_HOST = "127.0.0.1";
    };
  };

  # System packages for vector memory
  environment.systemPackages = with pkgs; [
    # --- Intelligence & Orchestration ---
    openclaw-pkg # Native OpenClaw fleet core
    opencode # Native ACP coordination core
    gemini-cli # Gemini API interaction
    codex # Code analysis and refactoring
    python3 # Foundation for background sentries & logic shims
    babashka # Low-latency Clojure scripting for agentic tasks

    # --- Vector Memory Stack ---
    qdrant # Vector database
    (python3.withPackages (
      ps: with ps; [
        sentence-transformers # Embedding models
        fastapi # API server
        uvicorn # ASGI server
        httpx # HTTP client
        pydantic # Data validation
      ]
    ))
    curl # Health checks

    # --- Transcription & Media ---
    whisper-cpp # High-fidelity speech-to-text processing
    ffmpegthumbnailer # Visual context processing support

    # --- Version Control & Digital Limbs ---
    git # Primary sync mechanism
    github-cli # Bridge to the Collective (GitHub)
    gitui # Supplemental TUI for git operations
    lazygit # High-bandwidth git TUI
    lazydocker # Container monitoring for remote hosts

    # --- Shell Context & Intelligence ---
    atuin # Shared history memory
    oh-my-posh # Contextual prompt orchestration
    jq # JSON logic processing
    ripgrep # Massive filesystem scan capability
    fd # High-speed file discovery
  ];

  # ==============================================================================
  # OpenClaw Services: Real-time Communication & Intelligence
  # ==============================================================================

  # Main OpenClaw Gateway (Core Intelligence) - User Service
  systemd.user.services.openclaw-gateway = {
    description = "OpenClaw Gateway - Main Intelligence Core (Lore)";
    wantedBy = [ "default.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [
      "/run/wrappers"
      openclaw-pkg
      pkgs.nodejs
      pkgs.bash
      pkgs.chromium
    ];

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
    after = [
      "network-online.target"
      "openclaw-gateway.service"
    ];
    path = [
      openclaw-pkg
      pkgs.python3
      pkgs.curl
      pkgs.coreutils
      pkgs.nodejs
    ];

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
    path = [
      pkgs.python3
      pkgs.curl
      pkgs.jq
      pkgs.coreutils
    ];
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
