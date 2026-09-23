{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hyprvibe.opencode2Client;
  opencode2 = pkgs.callPackage ../../pkgs/opencode2-beta {};

  credentialSetup = ''
    secret_file=${lib.escapeShellArg cfg.secretFile}
    if [ ! -r "$secret_file" ]; then
      echo "OpenCode 2 server credential is not readable: $secret_file" >&2
      exit 1
    fi

    password_lines="$(${pkgs.gnugrep}/bin/grep -c '^OPENCODE_PASSWORD=' "$secret_file" || true)"
    if [ "$password_lines" -ne 1 ]; then
      echo "OpenCode 2 server credential must contain exactly one OPENCODE_PASSWORD entry" >&2
      exit 1
    fi

    OPENCODE_PASSWORD="$(${pkgs.gnused}/bin/sed -n 's/^OPENCODE_PASSWORD=//p' "$secret_file")"
    if ! ${pkgs.coreutils}/bin/printf '%s\n' "$OPENCODE_PASSWORD" \
      | ${pkgs.gnugrep}/bin/grep -Eq '^[A-Za-z0-9_-]{32,}$'; then
      echo "OpenCode 2 server credential has an unexpected format" >&2
      exit 1
    fi
    export OPENCODE_PASSWORD
  '';

  opencode2Nomad = pkgs.writeShellScriptBin "opencode2-nomad" ''
    set -euo pipefail
    ${credentialSetup}

    project_root=${lib.escapeShellArg cfg.projectRoot}
    if [ ! -d "$project_root" ]; then
      echo "OpenCode 2 requires the server project path to exist on the TUI client: $project_root" >&2
      echo "Create an empty local path mirror; filesystem tools still run on Nomad." >&2
      exit 1
    fi

    # OpenCode keys TUI state by the client process working directory. Start in
    # the canonical mirror so flags such as --auto do not select the caller cwd.
    cd "$project_root"

    if [ "$#" -eq 0 ]; then
      set -- "$project_root"
    fi

    exec ${lib.getExe opencode2} --server ${lib.escapeShellArg cfg.serverUrl} "$@"
  '';

  showfactoryCredentialSetup = ''
    secret_file=${lib.escapeShellArg cfg.showfactorySecretFile}
    if [ ! -r "$secret_file" ]; then
      echo "Showfactory OpenCode 2 credential is not readable: $secret_file" >&2
      echo "Provide OPENCODE_SERVER_PASSWORD in this local secret file." >&2
      exit 1
    fi

    password_lines="$( ${pkgs.gnugrep}/bin/grep -c '^OPENCODE_SERVER_PASSWORD=' "$secret_file" || true)"
    if [ "$password_lines" -ne 1 ]; then
      echo "Showfactory credential must contain exactly one OPENCODE_SERVER_PASSWORD entry" >&2
      exit 1
    fi

    OPENCODE_SERVER_PASSWORD="$( ${pkgs.gnused}/bin/sed -n 's/^OPENCODE_SERVER_PASSWORD=//p' "$secret_file")"
    if ! ${pkgs.coreutils}/bin/printf '%s\n' "$OPENCODE_SERVER_PASSWORD" \
      | ${pkgs.gnugrep}/bin/grep -Eq '^[[:xdigit:]]{32,}$'; then
      echo "Showfactory OpenCode 2 credential has an unexpected format" >&2
      exit 1
    fi
    export OPENCODE_SERVER_PASSWORD
  '';

  opencode2ShowfactoryHermes = pkgs.writeShellScriptBin "opencode2-showfactory-hermes" ''
    set -euo pipefail
    ${credentialSetup}

    project_root=${lib.escapeShellArg cfg.showfactoryProjectRoot}
    if [ ! -d "$project_root" ]; then
      echo "OpenCode 2 requires the Showfactory Location mirror on the TUI client: $project_root" >&2
      exit 1
    fi

    cd "$project_root"
    if [ "$#" -eq 0 ]; then
      set -- "$project_root"
    fi

    exec ${lib.getExe opencode2} --server ${lib.escapeShellArg cfg.serverUrl} "$@"
  '';

  opencode2Showfactory = pkgs.writeShellScriptBin "opencode2-showfactory" ''
    set -euo pipefail
    ${showfactoryCredentialSetup}

    project_root=${lib.escapeShellArg cfg.showfactoryProjectRoot}
    server_project_root=${lib.escapeShellArg cfg.showfactoryServerProjectRoot}
    if [ ! -d "$project_root" ]; then
      echo "OpenCode 2 requires the Showfactory Location mirror on the TUI client: $project_root" >&2
      exit 1
    fi

    # Keep TUI state in the local mirror while opening the real Showfactory
    # workspace on its OpenCode 2 backend.
    cd "$project_root"
    if [ "$#" -eq 0 ]; then
      set -- "$server_project_root"
    fi

    exec ${lib.getExe opencode2} --server ${lib.escapeShellArg cfg.showfactoryServerUrl} "$@"
  '';

  opencode2NomadStatus = pkgs.writeShellScriptBin "opencode2-nomad-status" ''
    set -euo pipefail
    ${credentialSetup}
    exec ${lib.getExe opencode2} api --server ${lib.escapeShellArg cfg.serverUrl} get /api/status
  '';
in {
  options.hyprvibe.opencode2Client = {
    enable = lib.mkEnableOption "OpenCode 2 stable client for the Nomad server";

    serverUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://nomad.coin-noodlefish.ts.net:8444";
      description = "Tailnet URL of the OpenCode 2 server";
    };

    projectRoot = lib.mkOption {
      type = lib.types.str;
      default = "/home/chrisf/build/nomad-nixos";
      description = "Nomad-side project selected by a no-argument remote TUI";
    };

    showfactoryProjectRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.hyprvibe.user.home}/opencode/showfactory";
      description = "Local mirror used to scope the Showfactory TUI state";
    };

    showfactoryServerUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://100.65.102.108:49374";
      description = "Tailnet URL of Showfactory's OpenCode 2 backend";
    };

    showfactoryServerProjectRoot = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/hermes/workspace";
      description = "Showfactory-side workspace opened by a no-argument TUI";
    };

    showfactorySecretFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.hyprvibe.user.home}/.config/secrets/showfactory-opencode2.env";
      description = "Local secret file containing OPENCODE_SERVER_PASSWORD";
    };

    secretFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.hyprvibe.user.home}/.config/secrets/opencode2-server.env";
      description = "Local environment file containing OPENCODE_PASSWORD";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${builtins.dirOf cfg.showfactoryProjectRoot} 0755 ${config.hyprvibe.user.name} ${config.hyprvibe.user.group} -"
      "d ${cfg.showfactoryProjectRoot} 0755 ${config.hyprvibe.user.name} ${config.hyprvibe.user.group} -"
    ];

    environment.systemPackages = [
      opencode2
      opencode2Nomad
      opencode2Showfactory
      opencode2ShowfactoryHermes
      opencode2NomadStatus
    ];
  };
}
