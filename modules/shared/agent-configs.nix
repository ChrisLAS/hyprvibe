{
  lib,
  config,
  ...
}: let
  cfg = config.hyprvibe.agentConfigs;
  user = config.hyprvibe.user;
  codexConfig = "${cfg.path}/codex/config.shared.toml";
  codexDir = "${user.home}/.codex";
  liveConfig = "${codexDir}/config.toml";
in {
  options.hyprvibe.agentConfigs = {
    enable = lib.mkEnableOption "shared CLI agent configuration";

    path = lib.mkOption {
      type = lib.types.str;
      default = "${user.home}/Sync/agent-configs";
      description = "Path to the shared agent configuration repository.";
    };

    codex.enable = lib.mkEnableOption "shared Codex CLI config";
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${codexDir} 0750 ${user.name} ${user.group} -"
    ];

    systemd.services.link-codex-shared-config = lib.mkIf cfg.codex.enable {
      description = "Link Codex CLI to shared agent config";
      after = ["syncthing.service"];
      wants = ["syncthing.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        set -eu

        mkdir -p ${lib.escapeShellArg codexDir}
        chown ${lib.escapeShellArg user.name}:${lib.escapeShellArg user.group} ${lib.escapeShellArg codexDir}
        chmod 0750 ${lib.escapeShellArg codexDir}

        for _ in $(seq 1 60); do
          if [ -f ${lib.escapeShellArg codexConfig} ]; then
            break
          fi
          sleep 5
        done

        if [ ! -f ${lib.escapeShellArg codexConfig} ]; then
          echo "Shared Codex config not found at ${codexConfig}; leaving ${liveConfig} unchanged."
          exit 0
        fi

        if [ -L ${lib.escapeShellArg liveConfig} ] && [ "$(readlink -f ${lib.escapeShellArg liveConfig})" = ${lib.escapeShellArg codexConfig} ]; then
          exit 0
        fi

        if [ -e ${lib.escapeShellArg liveConfig} ] || [ -L ${lib.escapeShellArg liveConfig} ]; then
          stamp="$(date +%Y%m%d-%H%M%S)"
          backup="${liveConfig}.backup-before-shared.$stamp"
          diff_file="${liveConfig}.diff-before-shared.$stamp"
          local_copy="${liveConfig}.local-before-shared.$stamp"

          cp -p ${lib.escapeShellArg liveConfig} "$backup"
          diff -u ${lib.escapeShellArg liveConfig} ${lib.escapeShellArg codexConfig} > "$diff_file" || true
          mv ${lib.escapeShellArg liveConfig} "$local_copy"
          chown ${lib.escapeShellArg user.name}:${lib.escapeShellArg user.group} "$backup" "$diff_file" "$local_copy"
          chmod 0600 "$backup" "$local_copy"
          chmod 0640 "$diff_file"
          echo "Backed up existing Codex config to $backup"
          echo "Wrote pre-link diff to $diff_file"
        fi

        ln -s ${lib.escapeShellArg codexConfig} ${lib.escapeShellArg liveConfig}
        chown -h ${lib.escapeShellArg user.name}:${lib.escapeShellArg user.group} ${lib.escapeShellArg liveConfig}
      '';
    };
  };
}
