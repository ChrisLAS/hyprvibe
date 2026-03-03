# OpenClaw pnpm-deps Hash Mismatch Fix

## Problem

When the upstream `openclaw/nix-openclaw` repository updates its `pnpm-lock.json` without updating the corresponding hash in `flake.nix`, you'll see:

```
error: hash mismatch in fixed-output derivation 'openclaw-gateway-pnpm-deps'
         specified: sha256-OLDDDDDDD
            got:    sha256-NEWWWWWWW
```

## Solution

This configuration provides an automatic hash override mechanism so you can rebuild without waiting for upstream fixes.

### Step 1: Get the correct hash

From the build error, extract the `got:` hash (shown as `sha256-NEWWWWWWW` above).

### Step 2: Update the override

Edit `lib/openclaw-pnpm-fix.nix` and add your openclaw revision to the `overrides` mapping:

```nix
overrides = {
  "8acd74a46b4cdafcda4bb77cccad60782111c739" = "sha256-wCFHU84/MaajfctbaBcUABuGFfnr9lbn/zVu0T9pisE=";
  "NEW-REVISION-HERE" = "sha256-NEWWWWWWW";
};
```

You can find the openclaw revision in `flake.lock`:

```bash
cat flake.lock | jq '.nodes.openclaw.locked.rev'
```

### Step 3: Rebuild

```bash
nixos-rebuild switch --flake .#rvbee
```

The override will be automatically applied.

## How It Works

The override is implemented as a nixpkgs overlay that patches `mkDerivation` to replace the output hash for the `openclaw-gateway-pnpm-deps` fixed-output derivation.

## Reporting

If you encounter this issue, please consider:

1. **Report to upstream**: Open an issue at https://github.com/openclaw/nix-openclaw with:
   - The command you ran
   - The full error output
   - Your nixpkgs version (from `flake.lock`)

2. **Check for existing fixes**: The latest build may have already addressed this in a newer revision.

## Implementation Details

- **Location**: `lib/openclaw-pnpm-fix.nix`
- **Integration point**: `hosts/rvbee/system.nix`  (via nixpkgs overlay)
- **Scope**: Only affects `openclaw-gateway-pnpm-deps` derivation name
- **Future-proof**: Works with any openclaw version
