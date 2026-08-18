{
  coreutils,
  gnused,
  hermes-desktop,
  lib,
  makeDesktopItem,
  writeShellScriptBin,
}:
# Hermes Desktop (Nomad) launcher — exports the dashboard session token as
# `HERMES_DESKTOP_REMOTE_URL` + `HERMES_DESKTOP_REMOTE_TOKEN` so the locally
# built `hermes-desktop` Electron app talks to the nomad remote gateway
# instead of running an agent on the local machine.
#
# Usage in a NixOS host:
#   environment.systemPackages = [
#     pkgs.hermes-desktop               # built from `hermes-agent` flake input
#     (pkgs.callPackage ../pkgs/hermes-desktop-nomad.nix { }).wrapper
#     (pkgs.callPackage ../pkgs/hermes-desktop-nomad.nix { }).entry
#   ];
#
# The wrapper tolerates both bare tokens and `KEY=value` shells in the
# token file.
let
  wrapper = writeShellScriptBin "hermes-desktop-nomad" ''
    set -euo pipefail

    token_file="$HOME/.config/secrets/hermes_dashboard_session_token"
    if [ ! -r "$token_file" ]; then
      echo "Hermes Desktop remote token not found: $token_file" >&2
      echo "Copy it from nomad: ssh nomad 'cat ~/.config/secrets/hermes_dashboard_session_token' > $token_file" >&2
      exit 1
    fi

    # Tolerate either a bare token or a `KEY=value` (one-line shell) form.
    # Use gnused explicitly because pkgs.coreutils is the minimal variant
    # (no sed).
    token="$(${coreutils}/bin/tr -d '\n' < "$token_file" \
             | ${gnused}/bin/sed -n '1 { s/^[^=]*=//; s/[[:space:]]*$//; p; }')"
    if [ -z "$token" ]; then
      echo "Hermes Desktop remote token is empty: $token_file" >&2
      exit 1
    fi

    export HERMES_DESKTOP_REMOTE_URL="http://nomad.coin-noodlefish.ts.net:9119"
    export HERMES_DESKTOP_REMOTE_TOKEN="$token"

    log_dir="$HOME/.cache/hermes-desktop-nomad"
    ${coreutils}/bin/mkdir -p "$log_dir"
    log_file="$log_dir/launcher.log"

    {
      ${coreutils}/bin/printf '\n[%s] launching Hermes Desktop (Nomad)\n' \
        "$(${coreutils}/bin/date --iso-8601=seconds)"
      exec ${hermes-desktop}/bin/hermes-desktop "$@"
    } >>"$log_file" 2>&1
  '';

  entry = makeDesktopItem {
    name = "hermes-desktop-nomad";
    desktopName = "Hermes Desktop (Nomad)";
    comment = "Launch Hermes Desktop connected to the nomad remote gateway";
    exec = lib.getExe wrapper;
    terminal = false;
    categories = ["Utility"];
    # `hermes` 1024x1024 icon ships with the nix-built hermes-desktop derivation.
    icon = "hermes";
    type = "Application";
  };
in {
  inherit wrapper entry;
}
