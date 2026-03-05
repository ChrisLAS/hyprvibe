{
  lib,
  ...
}:

{
  # ==============================================================================
  # OpenClaw pnpm-deps Hash Override Module
  # ==============================================================================
  # Provides a mechanism to override the pnpm-deps hash for openclaw packages
  # when upstream hashes diverge from actual build outputs.
  #
  # When you encounter a hash mismatch error like:
  #   error: hash mismatch in fixed-output derivation
  #   specified: sha256-OLDDDDDDD
  #   got:       sha256-NEWWWWWWW
  #
  # Update the openclawPnpmHashes mapping below with the new hash.
  # ==============================================================================

  options.hyprvibe.openclaw.pnpmHashOverrides = lib.mkOption {
    description = "Hash overrides for openclaw pnpm-deps by revision";
    type = lib.types.attrsOf lib.types.str;
    default = {
      # openclaw rev -> pnpm-deps hash from actual Nix build output
      "8acd74a46b4cdafcda4bb77cccad60782111c739" = "sha256-xPGDG4JohOkLX1w03lMc0L55uhLlT+fJQm4I9IFpQzY=";
    };
    example = {
      "abc123def456" = "sha256-XXXXXXXXXXXXXXXX...";
    };
  };

  #config = {
  #  hyprvibe.openclaw.pnpmHashOverrides = {
  #    # Updated: 2026-03-03 for openclaw rev 8acd74a46b4cdafcda4bb77cccad60782111c739
  #    "8acd74a46b4cdafcda4bb77cccad60782111c739" = "sha256-xPGDG4JohOkLX1w03lMc0L55uhLlT+fJQm4I9IFpQzY=";
  #  };
  #};
}
