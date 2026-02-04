{ config, pkgs, lib, openclaw, ... }:

let
  userName = config.hyprvibe.user.name;

  # Package provided by the top-level flake input
  openclaw-pkg = openclaw.packages.${pkgs.system}.default;

  crabwalk-pkg = pkgs.stdenv.mkDerivation rec {
    pname = "crabwalk";
    version = "1.0.9";
    src = pkgs.fetchurl {
      url = "https://github.com/luccast/crabwalk/releases/download/v${version}/crabwalk-v${version}.tar.gz";
      sha256 = "0yhkpgn8bn8wgcgzsrn2qnymwbkp0kbxrga43lj225g6a5xn7wx5";
    };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    setSourceRoot = "sourceRoot=.";
    installPhase = ''
      mkdir -p $out/bin
      cp -r . $out/opt
      ln -s $out/opt/bin/crabwalk $out/bin/crabwalk
      wrapProgram $out/bin/crabwalk \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.nodejs_20 pkgs.qrencode pkgs.gnugrep pkgs.coreutils ]}
    '';
  };
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
    python3            # Foundation for background sentries & logic shims
    babashka           # Low-latency Clojure scripting for agentic tasks
    crabwalk-pkg       # Real-time companion monitor
    
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

    # Fix Crabwalk .output symlink if needed after migration
    mkdir -p $HOME/.crabwalk
    ln -sf ${crabwalk-pkg}/opt/.output $HOME/.crabwalk/.output
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

  # Lore Real-time Listener (OpenClaw)
  systemd.services.openclaw-listener-lore = {
    description = "Lore Real-time OpenClaw Mattermost Listener";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.nodejs pkgs.bash pkgs.curl pkgs.jq pkgs.python3 pkgs.coreutils pkgs.gnugrep ];
    serviceConfig = {
      Type = "simple";
      User = "${userName}";
      ExecStart = "${pkgs.nodejs}/bin/node /home/chrisf/.openclaw/scripts/mattermost-websocket-listener.js";
      Restart = "always";
      RestartSec = "10s";
      Environment = [
        "MM_BOT_NAME=Lore"
        "MM_BOT_ID=dtdasoec43dd5d3kgdccd8skua"
        "MM_BOT_TOKEN=y4yuqsyrepbuteq4ae74p78djy"
        "NODE_PATH=${pkgs.nodejs}/lib/node_modules"
      ];
    };
  };

  # Data Real-time Listener (OpenClaw)
  systemd.services.openclaw-listener-data = {
    description = "Data Real-time OpenClaw Mattermost Listener";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.nodejs pkgs.bash pkgs.curl pkgs.jq pkgs.python3 pkgs.coreutils pkgs.gnugrep ];
    serviceConfig = {
      Type = "simple";
      User = "${userName}";
      ExecStart = "${pkgs.nodejs}/bin/node /home/chrisf/.openclaw/scripts/mattermost-websocket-listener.js";
      Restart = "always";
      RestartSec = "10s";
      Environment = [
        "MM_BOT_NAME=Data"
        "MM_BOT_ID=19suo8rne3bet8hf7kwocxn1rw"
        "MM_BOT_TOKEN=***REMOVED***"
        "NODE_PATH=${pkgs.nodejs}/lib/node_modules"
      ];
    };
  };

  # Uhura Real-time Listener (OpenClaw)
  systemd.services.openclaw-listener-uhura = {
    description = "Uhura Real-time OpenClaw Mattermost Listener";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.nodejs pkgs.bash pkgs.curl pkgs.jq pkgs.python3 pkgs.coreutils pkgs.gnugrep ];
    serviceConfig = {
      Type = "simple";
      User = "${userName}";
      ExecStart = "${pkgs.nodejs}/bin/node /home/chrisf/.openclaw/scripts/mattermost-websocket-listener.js";
      Restart = "always";
      RestartSec = "10s";
      Environment = [
        "MM_BOT_NAME=Uhura"
        "MM_BOT_ID=ckta36zrkjb4ig1ykf664s6e3h"
        "MM_BOT_TOKEN=***REMOVED***"
        "NODE_PATH=${pkgs.nodejs}/lib/node_modules"
      ];
    };
  };

  # Dax Real-time Listener (OpenClaw Mattermost)
  systemd.services.openclaw-listener-dax = {
    description = "Dax Real-time OpenClaw Mattermost Listener";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.nodejs pkgs.bash pkgs.curl pkgs.jq pkgs.python3 pkgs.coreutils pkgs.gnugrep ];
    serviceConfig = {
      Type = "simple";
      User = "${userName}";
      ExecStart = "${pkgs.nodejs}/bin/node /home/chrisf/.openclaw/scripts/mattermost-websocket-listener.js";
      Restart = "always";
      RestartSec = "10s";
      Environment = [
        "MM_BOT_NAME=Dax"
        "MM_BOT_ID=ypxxcpkhgpntdc4ehujftptu4e"
        "MM_BOT_TOKEN=bmr1hxp7wbb8xksdujib8ix16o"
        "NODE_PATH=${pkgs.nodejs}/lib/node_modules"
      ];
    };
  };

  # Dax Real-time Listener (OpenClaw Telegram)
  systemd.services.openclaw-station-dax = {
    description = "Dax Real-time OpenClaw Telegram Station";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.python3 pkgs.curl pkgs.coreutils pkgs.gnugrep ];
    serviceConfig = {
      Type = "simple";
      User = "${userName}";
      ExecStart = "${pkgs.python3}/bin/python3 /home/chrisf/.openclaw/scripts/dax_listener.py";
      Restart = "always";
      RestartSec = "10s";
      WorkingDirectory = "/home/chrisf/.openclaw/scripts";
    };
  };

  # Crabwalk OpenClaw Monitoring Dashboard
  systemd.user.services.crabwalk = {
    description = "Crabwalk OpenClaw Monitoring Dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "simple";
      User = "${userName}";
      # Using standard OpenClaw local port 3000
      ExecStart = "${crabwalk-pkg}/bin/crabwalk start -p 3000 -H 0.0.0.0 -g ws://127.0.0.1:18789 -t ***REMOVED***";
      Restart = "always";
      RestartSec = "10s";
      Environment = [
        "NODE_PATH=${pkgs.nodejs_20}/lib/node_modules"
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
