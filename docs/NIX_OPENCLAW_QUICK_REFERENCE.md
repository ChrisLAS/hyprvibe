# nix-openclaw pnpm-deps Quick Reference

Quick code snippets and commands for working with pnpm-deps hashes.

## Absolute File Paths (nix-openclaw repo)

```
https://github.com/openclaw/nix-openclaw/tree/main/nix/sources/openclaw-source.nix
https://github.com/openclaw/nix-openclaw/tree/main/nix/packages/openclaw-gateway.nix
https://github.com/openclaw/nix-openclaw/tree/main/nix/lib/openclaw-gateway-common.nix
https://github.com/openclaw/nix-openclaw/tree/main/nix/modules/home-manager/openclaw/options-instance.nix
https://github.com/openclaw/nix-openclaw/tree/main/nix/modules/home-manager/openclaw/config.nix
https://github.com/openclaw/nix-openclaw/tree/main/templates/agent-first/flake.nix
```

## Current Hash Values

From `nix/sources/openclaw-source.nix`:

```nix
{
  owner = "openclaw";
  repo = "openclaw";
  rev = "4abf398a17ad127935236f4f072a93e890e5581e";
  hash = "sha256-Gb/PUsgYGddCP3u8B2Lw8As17pAUCOUWDhA/PFLfMc0=";
  pnpmDepsHash = "sha256-QnKPVUPgy3znCQRmfqiIPtRLgZ0SPwWqUsJ4USF2LJE=";
}
```

## Consumer Flake: Local Gateway Development

### Minimal setup with hash override:

```nix
{
  description = "My OpenClaw config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-openclaw.url = "github:openclaw/nix-openclaw";
  };

  outputs = { self, nixpkgs, home-manager, nix-openclaw }:
    let
      system = "aarch64-darwin";  # or x86_64-darwin, x86_64-linux
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nix-openclaw.overlays.default ];
      };
    in
    {
      homeConfigurations."your-username" = 
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            nix-openclaw.homeManagerModules.openclaw
            {
              home.username = "your-username";
              home.homeDirectory = "/Users/your-username";  # or /home/your-username
              home.stateVersion = "24.11";
              programs.home-manager.enable = true;

              programs.openclaw = {
                documents = ./documents;
                
                instances.default = {
                  enable = true;
                  
                  # FOR LOCAL GATEWAY DEVELOPMENT:
                  gatewayPath = "/Users/you/code/openclaw";
                  gatewayPnpmDepsHash = null;  # Start with null, let Nix compute
                  
                  plugins = [
                    { source = "github:example/plugin"; }
                  ];
                };
              };
            }
          ];
        };
    };
}
```

## Workflow: Computing Hash for Local Gateway

### Step 1: Set null hash

```nix
gatewayPath = "/Users/you/code/openclaw";
gatewayPnpmDepsHash = null;
```

### Step 2: Try building

```bash
home-manager switch --flake .#your-username
```

### Step 3: Nix will report error like:

```
hash mismatch, got:
  sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
expected:
  lib.fakeHash
```

### Step 4: Copy the "got" hash

```nix
gatewayPnpmDepsHash = "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
```

### Step 5: Build again

```bash
home-manager switch --flake .#your-username
```

## Multiple Instances (Prod + Dev)

```nix
programs.openclaw.instances = {
  # Production instance (stable)
  prod = {
    enable = true;
    package = pkgs.openclaw;  # Pre-built
    stateDir = "${openclawLib.homeDir}/.openclaw-prod";
    gatewayPort = 18789;
    plugins = [ { source = "github:stable/plugin"; } ];
  };
  
  # Development instance (local gateway)
  dev = {
    enable = true;
    stateDir = "${openclawLib.homeDir}/.openclaw-dev";
    gatewayPort = 18790;
    gatewayPath = "/Users/you/code/openclaw";
    gatewayPnpmDepsHash = "sha256-YOURCOMPUTEDHASH";
    plugins = [ { source = "path:/Users/you/code/plugin"; } ];
  };
};
```

## Module Options Reference

From `nix/modules/home-manager/openclaw/options-instance.nix`:

```nix
# For local gateway builds
gatewayPath = lib.mkOption {
  type = lib.types.nullOr lib.types.str;
  default = null;
  description = "Local path to OpenClaw gateway source (dev only).";
};

gatewayPnpmDepsHash = lib.mkOption {
  type = lib.types.nullOr lib.types.str;
  default = lib.fakeHash;
  description = "pnpmDeps hash for local gateway builds (omit to let Nix suggest the correct hash).";
};
```

## Advanced: Custom Package with Hash Override

```nix
let
  system = "aarch64-darwin";
  pkgs = import nixpkgs {
    inherit system;
    overlays = [ nix-openclaw.overlays.default ];
  };
  
  # Custom gateway with your own pnpm hash
  customGateway = pkgs.callPackage 
    "${nix-openclaw}/nix/packages/openclaw-gateway.nix" 
  {
    sourceInfo = {
      owner = "openclaw";
      repo = "openclaw";
      rev = "4abf398a17ad127935236f4f072a93e890e5581e";
      hash = "sha256-Gb/PUsgYGddCP3u8B2Lw8As17pAUCOUWDhA/PFLfMc0=";
      pnpmDepsHash = "sha256-YOUR_CUSTOM_HASH_HERE";  # <-- Override
    };
  };
in
{
  # ... rest of flake config ...
  programs.openclaw.instances.default = {
    package = customGateway;
    # ...
  };
}
```

## Useful Commands

### Check what gateway package is being used

```bash
home-manager generations | head -5
```

### View OpenClaw gateway service status (macOS)

```bash
launchctl print gui/$UID/com.steipete.openclaw.gateway
```

### View gateway logs (macOS)

```bash
tail -50 /tmp/openclaw/openclaw-gateway.log
```

### View OpenClaw gateway service status (Linux)

```bash
systemctl --user status openclaw-gateway
```

### View gateway logs (Linux)

```bash
journalctl --user -u openclaw-gateway -f
```

## Key Concepts

### Fixed-Output Derivation (FOD)

The pnpmDepsHash is used in a FOD:
- Downloads the pnpm cache atomically
- Stored in `/nix/store/HASH-pnpm-deps/...`
- If hash doesn't match, Nix rejects the download (security)
- Using `lib.fakeHash` makes Nix compute the actual hash

### Why Platform-Specific Hashes?

The hash accounts for:
- pnpm version (pnpm_10)
- Platform (darwin, linux)
- Architecture (arm64, x86_64)

Same upstream lock ≠ same hash on different platforms (expected).

### Separation of Concerns

- **Source pins**: `nix/sources/openclaw-source.nix` (data)
- **Package definition**: `nix/packages/openclaw-gateway.nix` (logic)
- **Consumer config**: Your flake (usage)

This keeps pins centralized and reusable.

## Troubleshooting

### "hash mismatch" when building local gateway

Solution: Copy the suggested hash from error message into `gatewayPnpmDepsHash`.

### Changes to pnpm-lock.yaml not picked up

Solution: The hash is based on lockfile content. If you modify the lockfile:
1. Set `gatewayPnpmDepsHash = null`
2. Run `home-manager switch` (will fail with new hash)
3. Copy new hash into config
4. Run `home-manager switch` again

### "path does not exist" for gatewayPath

Solution: Ensure the path is absolute and the directory exists:
```nix
gatewayPath = "/Users/you/code/openclaw";  # Not relative paths
```

### Multiple instances on same machine

Use different:
- `stateDir` (e.g., `~/.openclaw-prod`, `~/.openclaw-dev`)
- `gatewayPort` (e.g., 18789, 18790)
- `launchd.label` / `systemd.unitName` (auto-generated from instance name)

## Summary

| Task | Approach |
|------|----------|
| Standard setup (no local gateway) | Just use `nix-openclaw` as-is |
| Local gateway development | Use `gatewayPath` + `gatewayPnpmDepsHash = null` |
| Custom upstream commit | Pin different rev in nix-openclaw input |
| Multiple instances | Use `instances.prod` and `instances.dev` |
| Override build logic | Use `pkgs.callPackage` with custom sourceInfo |

