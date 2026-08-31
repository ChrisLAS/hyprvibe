{
  coreutils,
  hermes-desktop,
  lib,
  makeDesktopItem,
  writeShellScriptBin,
}:
# Remote-only Hermes Desktop launcher. Gateway URLs and credentials live in
# Desktop's owner-only connection registry so one app can use Nomad,
# Showfactory, and future Hermes hosts without a host-specific wrapper.
#
# Usage in a NixOS host:
#   environment.systemPackages = [
#     pkgs.hermes-desktop               # built from `hermes-agent` flake input
#     (pkgs.callPackage ../pkgs/hermes-desktop-nomad.nix { }).wrapper
#     (pkgs.callPackage ../pkgs/hermes-desktop-nomad.nix { }).entry
#   ];
#
let
  wrapper = writeShellScriptBin "hermes-desktop-remote" ''
    set -euo pipefail

    log_dir="$HOME/.cache/hermes-desktop-remote"
    ${coreutils}/bin/mkdir -p "$log_dir"
    log_file="$log_dir/launcher.log"

    {
      ${coreutils}/bin/printf '\n[%s] launching Hermes Desktop (remote gateways)\n' \
        "$(${coreutils}/bin/date --iso-8601=seconds)"
      exec ${hermes-desktop}/bin/hermes-desktop "$@"
    } >>"$log_file" 2>&1
  '';

  entry = makeDesktopItem {
    name = "hermes-desktop-remote";
    desktopName = "Hermes Desktop (Remote Gateways)";
    comment = "Connect to Nix-managed Hermes gateways";
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
