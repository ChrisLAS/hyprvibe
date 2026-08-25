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
      | ${pkgs.gnugrep}/bin/grep -Eq '^[[:xdigit:]]{32,}$'; then
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

  opencode2NomadStatus = pkgs.writeShellScriptBin "opencode2-nomad-status" ''
    set -euo pipefail
    ${credentialSetup}
    exec ${lib.getExe opencode2} api --server ${lib.escapeShellArg cfg.serverUrl} get /api/health
  '';
in {
  options.hyprvibe.opencode2Client = {
    enable = lib.mkEnableOption "OpenCode 2 beta client for the Nomad server";

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

    secretFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.hyprvibe.user.home}/.config/secrets/opencode2-server.env";
      description = "Local environment file containing OPENCODE_PASSWORD";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      opencode2
      opencode2Nomad
      opencode2NomadStatus
    ];
  };
}
