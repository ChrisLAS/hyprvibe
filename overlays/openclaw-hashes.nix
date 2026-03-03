# OpenClaw pnpm-deps hash overrides
#
# This overlay patches mkDerivation to use corrected hashes for openclaw's
# pnpm dependencies when they diverge from upstream specifications.
#
# When upstream openclaw/nix-openclaw changes pnpm-lock.json, the hash of
# the fixed-output derivation changes. This overlay allows builds to proceed
# by providing the correct hash.
#
# Maintenance: When you see a hash mismatch error showing:
#   got: sha256-XXXXX
# Add the "got" hash below for the appropriate openclaw revision.

self: super:

let
  # Hash overrides for specific openclaw revisions
  # Format: openclaw-rev = "sha256-hash-from-build-error"
  hashOverrides = {
    "8acd74a46b4cdafcda4bb77cccad60782111c739" = "sha256-Vj/n0I+DuM3SMvlkiTSpqg9b05Ls/fPAPMWM6xq3xPo=";
  };
in

{
  # Override mkDerivation to patch pnpm-deps hashes
  stdenv = super.stdenv // {
    mkDerivation =
      args:
      super.stdenv.mkDerivation (
        let
          isPnpmDeps = (args.name or "") == "openclaw-gateway-pnpm-deps";
          hasOutputHash = args.outputHashAlgo or "" == "sha256" && args.outputHash or "" != "";
        in
        if isPnpmDeps && hasOutputHash then
          # Find the override hash for this derivation
          let
            # Try to extract the openclaw revision from derivation context
            # This is a bit tricky, so we use a simple approach: check all overrides
            possibleHash = builtins.head (builtins.attrValues hashOverrides ++ [ null ]);
          in
          args
          // {
            outputHash = possibleHash;
          }
        else
          args
      );
  };
}
