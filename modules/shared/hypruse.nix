{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hyprvibe.hypruse;
  user = config.hyprvibe.user;
  hypruse = pkgs.callPackage ../../pkgs/hypruse.nix {};
  expectedHost = config.networking.hostName;
  listenAddress = cfg.tailscaleAddresses.${expectedHost} or null;
  stateDir = "${user.home}/.local/state/hypruse";

  launcher = pkgs.writeShellScript "hypruse-${expectedHost}-launcher" ''
    set -euo pipefail
    actual="$(${pkgs.inetutils}/bin/hostname -s)"
    if [[ "$actual" != ${lib.escapeShellArg expectedHost} ]]; then
      echo "hypruse identity mismatch: expected ${expectedHost}, got $actual" >&2
      exit 1
    fi
    export HYPRUSE_AUTH_GUARD=strict
    export HYPRUSE_STRICT=1
    export HYPRUSE_MARK=1
    export HYPRUSE_CLIPBOARD=0
    export HYPRUSE_JOURNAL=${lib.escapeShellArg "${stateDir}/journal.ndjson"}
    export HYPRUSE_JOURNAL_TEXT=0
    export HYPRUSE_SCREENSHOT_MODE=image
    exec ${lib.getExe hypruse}
  '';

  status = pkgs.writeShellScriptBin "hypruse-status" ''
    set -euo pipefail
    expected=${lib.escapeShellArg expectedHost}
    actual="$(${pkgs.inetutils}/bin/hostname -s)"
    [[ "$actual" == "$expected" ]] || {
      echo "identity mismatch: expected=$expected actual=$actual" >&2
      exit 1
    }
    systemctl --user is-active --quiet hypruse-mcp.service
    printf 'hypruse-%s: active at http://%s:%s/mcp\n' \
      "$actual" ${lib.escapeShellArg listenAddress} ${toString cfg.port}
  '';

  panic = pkgs.writeShellScriptBin "hypruse-panic" ''
    set -euo pipefail
    systemctl --user stop hypruse-mcp.service
    ${lib.getExe hypruse} stop 2>/dev/null || true
    echo "Hypruse control stopped on $(${pkgs.inetutils}/bin/hostname -s)"
  '';
in {
  options.hyprvibe.hypruse = {
    enable = lib.mkEnableOption "host-identified Hypruse MCP desktop control";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8765;
      description = "Tailnet Streamable HTTP MCP port";
    };

    tailscaleAddresses = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        nixstation = "100.75.168.43";
        nixvader = "100.112.13.59";
      };
      description = "Stable host identities and Tailscale listener addresses";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = listenAddress != null;
        message = "hyprvibe.hypruse requires a tailscaleAddresses entry for ${expectedHost}";
      }
    ];

    environment.systemPackages = [hypruse status panic];
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [cfg.port];

    systemd.user.services.hypruse-mcp = {
      description = "Hypruse MCP desktop control (${expectedHost})";
      documentation = ["https://github.com/IlyasKhallouki/hypruse"];
      wantedBy = ["graphical-session.target"];
      after = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      unitConfig.ConditionUser = user.name;
      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${stateDir}";
        ExecStart = "${lib.getExe pkgs.mcp-proxy} --host ${listenAddress} --port ${toString cfg.port} -- ${launcher}";
        Restart = "on-failure";
        RestartSec = "3s";
        UMask = "0077";
      };
    };
  };
}
