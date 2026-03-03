# OpenClaw pnpm-deps Hash Fix Library
# =====================================
# This module provides a mechanism to override the pnpm-deps hash for openclaw
# packages when upstream hashes become stale.
#
# When you encounter:
#   error: hash mismatch in fixed-output derivation 'openclaw-gateway-pnpm-deps'
#   specified: sha256-OLDDDDDDD
#   got:       sha256-NEWWWWWWW
#
# Update the `overrides` mapping below with: openclaw-revision = "sha256-NEWWWWWWW"
# Then run: nix flake update openclaw
#
# The override will be automatically applied on the next rebuild.

{
  lib,
  ...
}:

rec {
  # Hash overrides for openclaw revisions
  # Map: openclaw-git-revision -> actual pnpm-deps hash
  overrides = {
    # Updated 2026-03-03: openclaw rev 8acd74a46b4cdafcda4bb77cccad60782111c739
    "8acd74a46b4cdafcda4bb77cccad60782111c739" = "sha256-wCFHU84/MaajfctbaBcUABuGFfnr9lbn/zVu0T9pisE=";
  };

  # Create a nixpkgs overlay that patches fixed-output derivations
  # This overlay replaces outputHash for openclaw-gateway-pnpm-deps
  mkOverlay =
    finalOpenclawRev:
    (final: prev: {
      # Intercept mkDerivation to patch pnpm-deps hash
      stdenv = prev.stdenv // {
        mkDerivation =
          args:
          let
            isPnpmDeps = (args.name or "") == "openclaw-gateway-pnpm-deps";
            newHash = overrides."${finalOpenclawRev}" or null;
          in
          if isPnpmDeps && newHash != null then
            prev.stdenv.mkDerivation (args // { outputHash = newHash; })
          else
            prev.stdenv.mkDerivation args;
      };
    });
}
