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

  # Generate OpenClaw gateway auth token if it doesn't exist
  # This token is idempotent: if the file exists, we preserve it; if missing, we generate a new one
  system.activationScripts.openclaw-token-gen = lib.stringAfter [ "lore-bootstrap" ] ''
    export HOME=/home/${userName}
    OPENCLAW_DIR=$HOME/.openclaw
    TOKEN_FILE=$OPENCLAW_DIR/openclaw-token.txt

    if [ ! -f "$TOKEN_FILE" ]; then
      # Generate a random 32-byte token, base64-encoded
      ${pkgs.openssl}/bin/openssl rand -base64 32 > "$TOKEN_FILE"
      chmod 600 "$TOKEN_FILE"
      chown ${userName}:users "$TOKEN_FILE"
      echo "[openclaw] Generated new gateway auth token: $TOKEN_FILE"
    else
      echo "[openclaw] Gateway auth token already exists, preserving: $TOKEN_FILE"
    fi
  '';

  # Configure Tailscale Serve to expose OpenClaw gateway dashboard to tailnet
  # Gateway runs on loopback (127.0.0.1:18789) and Tailscale Serve provides the public HTTPS endpoint
  # Accessible at https://rvbee.coin-noodlefish.ts.net/ (encrypted Tailscale tunnel to tailnet members only)
  system.activationScripts.openclaw-tailscale-serve-setup = lib.stringAfter [ "lore-bootstrap" ] ''
    TAILSCALE_BIN=${pkgs.tailscale}/bin/tailscale

    if [ ! -x "$TAILSCALE_BIN" ]; then
      echo "[openclaw] Tailscale binary not found, skipping Serve setup"
      exit 0
    fi

    # Check if Tailscale Serve is already configured
    CURRENT_SERVE=$($TAILSCALE_BIN serve status 2>&1 | grep -c "proxy http://127.0.0.1:18789" || true)

    if [ "$CURRENT_SERVE" -eq 0 ]; then
      echo "[openclaw] Setting up Tailscale Serve for OpenClaw gateway..."
      $TAILSCALE_BIN serve --bg --https 443 http://127.0.0.1:18789 2>&1
      if [ $? -eq 0 ]; then
        echo "[openclaw] Tailscale Serve configured: https://rvbee.coin-noodlefish.ts.net/ (tailnet-only)"
      else
        echo "[openclaw] Tailscale Serve setup failed; verify with: tailscale serve status"
      fi
    else
      echo "[openclaw] Tailscale Serve already configured for OpenClaw gateway"
    fi
  '';

  # Configure OpenClaw gateway authentication and Tailscale integration
  # Gateway binds to loopback (127.0.0.1) by default in local mode
  # Tailscale Serve provides secure public HTTPS endpoint via encrypted tunnel
  system.activationScripts.openclaw-gateway-config = lib.stringAfter [ "openclaw-token-gen" ] ''
    export HOME=/home/${userName}
    CONFIG_FILE=$HOME/.openclaw/openclaw.json
    TOKEN_FILE=$HOME/.openclaw/openclaw-token.txt

    if [ ! -f "$CONFIG_FILE" ]; then
      echo "[openclaw] Config file not found, skipping gateway config"
      exit 0
    fi

    # Read the token (fallback to existing if file doesn't exist)
    TOKEN=""
    if [ -f "$TOKEN_FILE" ]; then
      TOKEN=$(cat "$TOKEN_FILE" | tr -d '\n')
    fi

    # Use jq to safely merge gateway config
    # This merge only adds/updates specific fields, preserving all other user customizations
    ${pkgs.jq}/bin/jq \
      --arg token "$TOKEN" \
      '.gateway |= . + {
        tailscale: { mode: "serve" },
        auth: (.auth // {} | . + { allowTailscale: true }),
        controlUi: { basePath: "/" },
        trustedProxies: (
          (.trustedProxies // ["127.0.0.1", "::1"]) as $existing |
          (["127.0.0.1", "::1", "100.75.168.43", "100.64.0.0/10"] | unique) as $required |
          if ($existing | length) == 0 then $required
          else (($existing + $required) | unique)
          end
        )
      } | .gateway.auth |= if (.token | length) == 0 and ($token | length) > 0 then . + { token: $token } else . end' \
      "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

    chown ${userName}:users "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    echo "[openclaw] Gateway config merged: token auth + Tailscale Serve mode enabled"
  '';

  # Sync loop runner scripts and user unit files for split heartbeat/orchestration lanes.
  # Heartbeat: lightweight periodic checks (no recall lane)
  # Orchestration: hourly deep loop (recall-enabled lane)
  system.activationScripts.openclaw-loop-runner-sync = lib.stringAfter [ "lore-bootstrap" ] ''
    export HOME=/home/${userName}
    WORKSPACE_DIR=$HOME/.openclaw/workspace-lore
    USER_UNITS_DIR=$HOME/.config/systemd/user

    mkdir -p "$WORKSPACE_DIR" "$USER_UNITS_DIR"

    install -m 0755 ${./openclaw-loop/run-heartbeat.sh} "$WORKSPACE_DIR/run-loop.sh"
    install -m 0755 ${./openclaw-loop/run-orchestration.sh} "$WORKSPACE_DIR/run-orchestration.sh"

    install -m 0644 ${./openclaw-loop/lore-loop.service} "$USER_UNITS_DIR/lore-loop.service"
    install -m 0644 ${./openclaw-loop/lore-loop.timer} "$USER_UNITS_DIR/lore-loop.timer"
    install -m 0644 ${./openclaw-loop/lore-orchestration.service} "$USER_UNITS_DIR/lore-orchestration.service"
    install -m 0644 ${./openclaw-loop/lore-orchestration.timer} "$USER_UNITS_DIR/lore-orchestration.timer"

    chown -R ${userName}:users "$WORKSPACE_DIR" "$USER_UNITS_DIR"
    echo "[openclaw] loop runner scripts and unit files synced (heartbeat + orchestration split)"
  '';

  # Sync declarative memory-cognee plugin patch into OpenClaw extensions dir.
  # This keeps recall policy behavior stable across plugin/gateway updates.
  system.activationScripts.openclaw-memory-cognee-plugin-sync = lib.stringAfter [ "lore-bootstrap" ] ''
    export HOME=/home/${userName}
    PLUGIN_DIR=$HOME/.openclaw/extensions/memory-cognee

    mkdir -p "$PLUGIN_DIR/dist"
    install -m 0644 ${./openclaw-plugins/memory-cognee/openclaw.plugin.json} "$PLUGIN_DIR/openclaw.plugin.json"
    install -m 0644 ${./openclaw-plugins/memory-cognee/dist/index.js} "$PLUGIN_DIR/dist/index.js"
    install -m 0644 ${./openclaw-plugins/memory-cognee/README.md} "$PLUGIN_DIR/README.md"

    chown -R ${userName}:users "$PLUGIN_DIR"
    chmod 0755 "$PLUGIN_DIR" "$PLUGIN_DIR/dist"
    chmod 0644 "$PLUGIN_DIR/openclaw.plugin.json" "$PLUGIN_DIR/dist/index.js" "$PLUGIN_DIR/README.md"
    echo "[openclaw] memory-cognee plugin patch synced (declarative)"
  '';

  # Enforce memory-cognee policy defaults:
  # - recall enabled for interactive sessions
  # - cron sessions skipped via session-key deny regex
  # - autoIndex disabled by default (manual index-window workflow only)
  system.activationScripts.openclaw-memory-cognee-policy = lib.stringAfter [ "openclaw-gateway-config" "openclaw-memory-cognee-plugin-sync" ] ''
    export HOME=/home/${userName}
    CONFIG_FILE=$HOME/.openclaw/openclaw.json

    if [ ! -f "$CONFIG_FILE" ]; then
      echo "[openclaw] Config file not found, skipping memory-cognee policy merge"
      exit 0
    fi

    if ! ${pkgs.jq}/bin/jq -e '.plugins.entries["memory-cognee"]' "$CONFIG_FILE" >/dev/null 2>&1; then
      echo "[openclaw] memory-cognee not configured, skipping policy merge"
      exit 0
    fi

    ${pkgs.jq}/bin/jq '
      .agents.list = (
        if ((.agents.list // []) | map(.id) | index("heartbeat-agent")) == null
        then ((.agents.list // []) + [{ id: "heartbeat-agent" }])
        else .agents.list
        end
      )
      |
      .plugins.entries["memory-cognee"].config |= ((. // {}) + {
        searchType: "CHUNKS",
        autoRecall: true,
        autoIndex: false,
        maxResults: 6,
        minScore: 0,
        maxTokens: 512,
        recallSessionDenyPatterns: ["^agent:[^:]+:cron:(?!2d7d3035-fa8b-4f21-a324-f3e26689b3c2:run:)", "^agent:heartbeat-agent:main$"],
        recallSessionAllowPatterns: [],
        recallPolicyLog: true,
        recallMaxConcurrent: 1,
        recallQueueTimeoutMs: 1500
      })
    ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

    chown ${userName}:users "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    echo "[openclaw] memory-cognee policy merged (interactive recall on, cron recall off, autoIndex off)"
  '';

  # Shared agentic environment variables
  environment.variables = {
    LORE_CORE = "active";
    LORE_OS = "NixOS";
    OPENCLAW_NIX_MODE = "1";
    OPENCLAW_CONFIG_DIR = "/home/${userName}/.openclaw";
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
    bun # JavaScript runtime for QMD

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
      pkgs.curl
      pkgs.wget
      pkgs.openssh
      pkgs.procps
      pkgs.psmisc
      pkgs.iproute2
      pkgs.podman
      pkgs.docker-client
      pkgs.gh
      pkgs.coreutils
      pkgs.util-linux
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

  # Tailscale Serve: Expose OpenClaw gateway to tailnet via HTTPS
  # Dashboard accessible at https://rvbee.coin-noodlefish.ts.net/ (tailnet-only)
  # Tailscale Serve is configured via system activation script (openclaw-tailscale-serve-setup)
  # This service is a placeholder to document the setup and allow manual control
  systemd.user.services.openclaw-tailscale-serve = {
    description = "OpenClaw Tailscale Serve - Expose gateway to tailnet";
    documentation = [ "https://docs.openclaw.ai/gateway/tailscale.md" ];
    after = [ "openclaw-gateway.service" ];
    wants = [ "openclaw-gateway.service" ];
    wantedBy = [ "default.target" ];

    # This is a documentation/placeholder service. The actual Tailscale Serve config
    # is managed by system.activationScripts.openclaw-tailscale-serve-setup and persists
    # in Tailscale's own configuration. To control Serve manually:
    #   tailscale serve status         # View current configuration
    #   tailscale serve reset          # Disable Serve
    #   tailscale serve --help         # Full usage details

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;

      # No-op exec: service succeeds immediately (Serve is managed by activation script)
      ExecStart = "${pkgs.coreutils}/bin/true";

      # Process management
      KillMode = "none";

      # Logging
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "openclaw-tailscale-serve";
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
