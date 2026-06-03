{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hyprvibe.opencode;
  user = config.hyprvibe.user;
  configDir = "${user.home}/.config/opencode";
  configFile = "${configDir}/opencode.json";
  baseConfig = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    model = "anthropic/claude-sonnet-4.5";
    autoupdate = true;
    theme = "opencode";
    mcp = {};
    provider = {
      "hermes-lore" = {
        npm = "@ai-sdk/openai-compatible";
        name = "Hermes Lore";
        options = {
          baseURL = "http://nomad.coin-noodlefish.ts.net:8643/v1";
          apiKey = "{file:~/.config/secrets/hermes_lore_api_server_key}";
        };
        models."hermes-lore" = {
          name = "Hermes Lore";
          tool_call = false;
        };
      };
      "hermes-data" = {
        npm = "@ai-sdk/openai-compatible";
        name = "Hermes Data";
        options = {
          baseURL = "http://nomad.coin-noodlefish.ts.net:8644/v1";
          apiKey = "{file:~/.config/secrets/hermes_data_api_server_key}";
        };
        models."hermes-data" = {
          name = "Hermes Data";
          tool_call = false;
        };
      };
      "hermes-number-one" = {
        npm = "@ai-sdk/openai-compatible";
        name = "Hermes Number One";
        options = {
          baseURL = "http://nomad.coin-noodlefish.ts.net:8645/v1";
          apiKey = "{file:~/.config/secrets/hermes_number_one_api_server_key}";
        };
        models."hermes-number-one" = {
          name = "Hermes Number One";
          tool_call = false;
        };
      };
    };
  };
in {
  options.hyprvibe.opencode.enable = lib.mkEnableOption "shared OpenCode configuration";

  config = lib.mkIf cfg.enable {
    systemd.user.services.hyprvibe-setup-opencode = {
      description = "Hyprvibe: setup OpenCode configuration";
      unitConfig.ConditionUser = user.name;
      after = ["default.target"];
      wantedBy = ["default.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "hyprvibe-setup-opencode" ''
          set -euo pipefail
          mkdir -p ${lib.escapeShellArg configDir}

          BASE_CONFIG=${lib.escapeShellArg baseConfig}
          if [ -d "/etc/opencode/mcp.d" ] && [ "$(ls -A /etc/opencode/mcp.d/*.json 2>/dev/null)" ]; then
            MERGED_MCP=$(${pkgs.jq}/bin/jq -s 'reduce .[] as $item ({}; . * $item)' /etc/opencode/mcp.d/*.json)
            FINAL_JSON="$(printf '%s\n' "$BASE_CONFIG" | ${pkgs.jq}/bin/jq --argjson mcp "$MERGED_MCP" '.mcp = $mcp')"
          else
            FINAL_JSON="$BASE_CONFIG"
          fi

          printf '%s\n' "$FINAL_JSON" > ${lib.escapeShellArg configFile}.tmp
          if ${pkgs.jq}/bin/jq . ${lib.escapeShellArg configFile}.tmp >/dev/null 2>&1; then
            mv ${lib.escapeShellArg configFile}.tmp ${lib.escapeShellArg configFile}
            chown ${lib.escapeShellArg user.name}:${lib.escapeShellArg user.group} ${lib.escapeShellArg configFile}
            chmod 0640 ${lib.escapeShellArg configFile}
          else
            echo "ERROR: generated OpenCode JSON is invalid; leaving existing config untouched." >&2
            rm -f ${lib.escapeShellArg configFile}.tmp
            exit 1
          fi
        '';
      };
    };
  };
}
