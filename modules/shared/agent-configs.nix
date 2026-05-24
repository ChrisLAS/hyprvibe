{
  lib,
  config,
  ...
}: let
  cfg = config.hyprvibe.agentConfigs;
  user = config.hyprvibe.user;
  codexConfig = "${cfg.path}/codex/config.shared.toml";
  codexAgents = "${cfg.path}/codex/AGENTS.md";
  codexDir = "${user.home}/.codex";
  liveConfig = "${codexDir}/config.toml";
  liveAgents = "${codexDir}/AGENTS.md";
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
          if [ -f ${lib.escapeShellArg codexConfig} ] || [ -f ${lib.escapeShellArg codexAgents} ]; then
            break
          fi
          sleep 5
        done

        if [ ! -f ${lib.escapeShellArg codexConfig} ] && [ ! -f ${lib.escapeShellArg codexAgents} ]; then
          echo "Shared Codex files not found under ${cfg.path}/codex; leaving ${codexDir} unchanged."
          exit 0
        fi

        link_shared_file() {
          source_path="$1"
          live_path="$2"
          label="$3"

          if [ ! -f "$source_path" ]; then
            echo "Shared Codex $label not found at $source_path; leaving $live_path unchanged."
            return
          fi

          if [ -L "$live_path" ] && [ "$(readlink -f "$live_path")" = "$source_path" ]; then
            return
          fi

          stamp="$(date +%Y%m%d-%H%M%S)"
          backup="$live_path.backup-before-shared.$stamp"
          diff_file="$live_path.diff-before-shared.$stamp"
          local_copy="$live_path.local-before-shared.$stamp"

          if [ -e "$live_path" ] || [ -L "$live_path" ]; then
            if [ -e "$live_path" ]; then
              cp -p "$live_path" "$backup"
              diff -u "$live_path" "$source_path" > "$diff_file" || true
            else
              : > "$diff_file"
            fi

            mv "$live_path" "$local_copy"
            for file in "$backup" "$diff_file" "$local_copy"; do
              if [ -e "$file" ] || [ -L "$file" ]; then
                chown ${lib.escapeShellArg user.name}:${lib.escapeShellArg user.group} "$file"
              fi
            done
            [ -e "$backup" ] && chmod 0600 "$backup"
            chmod 0640 "$diff_file"
            [ ! -L "$local_copy" ] && chmod 0600 "$local_copy"
            echo "Backed up existing Codex $label to $backup"
            echo "Wrote pre-link diff to $diff_file"
          fi

          ln -s "$source_path" "$live_path"
          chown -h ${lib.escapeShellArg user.name}:${lib.escapeShellArg user.group} "$live_path"
        }

        link_shared_file ${lib.escapeShellArg codexConfig} ${lib.escapeShellArg liveConfig} config
        link_shared_file ${lib.escapeShellArg codexAgents} ${lib.escapeShellArg liveAgents} AGENTS.md
      '';
    };
  };
}
