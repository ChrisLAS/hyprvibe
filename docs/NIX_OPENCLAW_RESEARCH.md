# nix-openclaw pnpm-deps Hash Override Research

## Summary

This document provides comprehensive findings about how openclaw/nix-openclaw handles pnpm dependencies and how to override the hash in a consumer flake.

---

## 1. Where pnpm-deps is Defined

### Primary Location: `nix/sources/openclaw-source.nix`

**File**: `/nix/sources/openclaw-source.nix`

```nix
# Pinned OpenClaw source for nix-openclaw
{
  owner = "openclaw";
  repo = "openclaw";
  rev = "4abf398a17ad127935236f4f072a93e890e5581e";
  hash = "sha256-Gb/PUsgYGddCP3u8B2Lw8As17pAUCOUWDhA/PFLfMc0=";
  pnpmDepsHash = "sha256-QnKPVUPgy3znCQRmfqiIPtRLgZ0SPwWqUsJ4USF2LJE=";
}
```

This is a pure data structure that contains:
- `owner`, `repo`, `rev`: Source code location
- `hash`: Checksum of the upstream source
- **`pnpmDepsHash`**: The fixed-output derivation hash for pnpm dependencies

### Secondary Location: Package Build (`nix/packages/openclaw-gateway.nix`)

The gateway package accepts `pnpmDepsHash` as a parameter:

```nix
{
  lib,
  stdenv,
  fetchFromGitHub,
  ...
  sourceInfo,
  gatewaySrc ? null,
  pnpmDepsHash ? (sourceInfo.pnpmDepsHash or null),  # <-- DEFAULT from sourceInfo
}:
```

This parameter can be:
1. **Omitted** (uses sourceInfo.pnpmDepsHash)
2. **Passed explicitly** when building a local gateway
3. **Set to null** to use `lib.fakeHash` and let Nix compute it

### Shared Build Logic: `nix/lib/openclaw-gateway-common.nix`

The common build module handles the actual hash usage:

```nix
pnpmDeps = fetchPnpmDeps {
  pname = pnpmDepsPname;
  inherit version;
  src = resolvedSrc;
  pnpm = pnpm_10;
  hash = if pnpmDepsHash != null then pnpmDepsHash else lib.fakeHash;
  # ... other config ...
};
```

**Key insight**: If `pnpmDepsHash` is null, it uses `lib.fakeHash`, which causes Nix to compute the actual hash and report it.

---

## 2. Hash Specification Mechanism

nix-openclaw uses the **Nixpkgs standard `fetchPnpmDeps`** function, which is the canonical way to handle pnpm lockfiles in Nix.

### How it Works

1. **Single hash for all pnpm dependencies**: The entire pnpm workspace lockfile is downloaded as a fixed-output derivation (FOD).

2. **Hash format**: SHA256 in the form `sha256-<base64>`
   - Example: `sha256-QnKPVUPgy3znCQRmfqiIPtRLgZ0SPwWqUsJ4USF2LJE=`

3. **Platform independence**: The hash is computed from:
   - pnpm lockfile content
   - pnpm version (`pnpm_10` in this case)
   - npm config settings (platform, arch, etc.)

4. **Stored in**: `nix/sources/openclaw-source.nix` (not inline in package definition)

### Why This Approach?

- **Separation of concerns**: Source pins are separate from package definitions
- **Single source of truth**: One file (`openclaw-source.nix`) for all upstream pins
- **Reusability**: Multiple packages can reference the same source info
- **Clarity**: Pins are data, not mixed with build logic

---

## 3. Hash Override Documentation

nix-openclaw **does not yet document hash overrides in user-facing docs**, but the mechanism is available:

### For Local Gateway Development

**Module option in `nix/modules/home-manager/openclaw/options-instance.nix`:**

```nix
gatewayPnpmDepsHash = lib.mkOption {
  type = lib.types.nullOr lib.types.str;
  default = lib.fakeHash;
  description = "pnpmDeps hash for local gateway builds (omit to let Nix suggest the correct hash).";
};
```

This allows users to:
1. Build with a **local gateway source** (`gatewayPath`)
2. Specify a **custom pnpmDepsHash** for their local build
3. Omit the hash (use `lib.fakeHash`) to have Nix compute it

### Usage Pattern (From `config.nix`)

When `gatewayPath` is set to a local path, the module does:

```nix
gatewayPackage =
  if inst.gatewayPath != null then
    pkgs.callPackage ../../packages/openclaw-gateway.nix {
      gatewaySrc = builtins.path {
        path = inst.gatewayPath;
        name = "openclaw-gateway-src";
      };
      pnpmDepsHash = inst.gatewayPnpmDepsHash;  # <-- User-provided hash
    }
  else
    inst.package;  # <-- Use pre-built package
```

---

## 4. nix-openclaw flake.nix Structure

**File**: `flake.nix` (root level)

```nix
{
  description = "nix-openclaw: declarative OpenClaw packaging";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    nix-steipete-tools.url = "github:openclaw/nix-steipete-tools";
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, nix-steipete-tools }:
    let
      # Source pins for OpenClaw
      sourceInfoStable = import ./nix/sources/openclaw-source.nix;
      
      # ... per-system package definitions ...
      
      packageSetStable = import ./nix/packages {
        pkgs = pkgs;
        sourceInfo = sourceInfoStable;
        steipetePkgs = steipetePkgs;
      };
    in
    {
      packages = packageSetStable // { default = packageSetStable.openclaw; };
      
      # Home Manager module for consumer use
      homeManagerModules.openclaw = 
        import ./nix/modules/home-manager/openclaw.nix;
    };
}
```

**Key outputs:**
- `packages.openclaw`: Full batteries-included package
- `packages.openclaw-gateway`: Gateway CLI only
- `homeManagerModules.openclaw`: Home Manager module for user configs

---

## 5. How to Override pnpmDepsHash in Consumer Flake

There are **three approaches** depending on your use case:

### Approach A: Override Source Pin (For All Consumers)

If you're using a **modified upstream source**, create your own `openclaw-source.nix`:

**In your consumer flake (e.g., `~/code/openclaw-local/flake.nix`):**

```nix
{
  description = "My OpenClaw config with custom upstream";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    # OPTION 1: Pin a different upstream commit
    nix-openclaw.url = "github:openclaw/nix-openclaw";
  };

  outputs = { self, nixpkgs, home-manager, nix-openclaw }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nix-openclaw.overlays.default ];
      };
    in
    {
      homeConfigurations."<user>" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          nix-openclaw.homeManagerModules.openclaw
          {
            home.username = "<user>";
            home.homeDirectory = "<homeDir>";
            # ... rest of config ...
          }
        ];
      };
    };
}
```

### Approach B: Local Gateway Development (Recommended for Dev)

For **local development** of the gateway itself, use `gatewayPath` + `gatewayPnpmDepsHash`:

**In your consumer flake:**

```nix
{
  # ... inputs ...
  
  outputs = { self, nixpkgs, home-manager, nix-openclaw }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nix-openclaw.overlays.default ];
      };
    in
    {
      homeConfigurations."<user>" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          nix-openclaw.homeManagerModules.openclaw
          {
            home.username = "<user>";
            home.homeDirectory = "<homeDir>";
            
            programs.openclaw = {
              documents = ./documents;
              
              instances.default = {
                enable = true;
                
                # Use a local gateway source
                gatewayPath = "/Users/you/code/openclaw";
                
                # Hash for the local pnpm lockfile
                # Set to null to have Nix compute it
                gatewayPnpmDepsHash = null;  # Nix will suggest the correct hash
                
                # Or specify it explicitly (once computed):
                # gatewayPnpmDepsHash = "sha256-YOUR_COMPUTED_HASH";
                
                plugins = [ /* ... */ ];
              };
            };
          }
        ];
      };
    };
}
```

**Workflow:**
1. Set `gatewayPath = "/path/to/openclaw"` (your local checkout)
2. Set `gatewayPnpmDepsHash = null` (use fakeHash)
3. Run `home-manager switch --flake .#<user>`
4. Nix will fail with: `hash mismatch, got sha256-XXXXXX, expected lib.fakeHash`
5. Copy the suggested hash into `gatewayPnpmDepsHash`
6. Run `home-manager switch` again

### Approach C: Override Package Definition (Advanced)

If you need to modify the package build itself, use `lib.callPackage`:

```nix
{
  # ... inputs ...
  
  outputs = { self, nixpkgs, home-manager, nix-openclaw }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nix-openclaw.overlays.default ];
      };
      
      # Custom gateway with overridden hash
      customGateway = pkgs.callPackage "${nix-openclaw}/nix/packages/openclaw-gateway.nix" {
        sourceInfo = {
          owner = "openclaw";
          repo = "openclaw";
          rev = "YOUR_CUSTOM_REV";
          hash = "sha256-YOUR_SOURCE_HASH";
          pnpmDepsHash = "sha256-YOUR_PNPM_HASH";  # <-- Override here
        };
      };
    in
    {
      homeConfigurations."<user>" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          nix-openclaw.homeManagerModules.openclaw
          {
            # ... standard config ...
            
            programs.openclaw.instances.default = {
              enable = true;
              package = customGateway;  # <-- Use custom package
              plugins = [ /* ... */ ];
            };
          }
        ];
      };
    };
}
```

---

## 6. Key Technical Details

### Fixed-Output Derivation (FOD)

The pnpmDepsHash is used in a **fixed-output derivation**:

```nix
pnpmDeps = fetchPnpmDeps {
  hash = if pnpmDepsHash != null then pnpmDepsHash else lib.fakeHash;
  # ...
};
```

This means:
- Nix **downloads** the pnpm cache (pinned by lockfile + pnpmDepsHash)
- The **download is cached** in `/nix/store` with the hash as the store path name
- If the hash doesn't match, Nix **rejects the download** (security feature)
- Using `lib.fakeHash` makes Nix **compute and report** the actual hash

### Why One Hash for All Dependencies?

- pnpm's lockfile (`pnpm-lock.yaml`) is deterministic
- All dependencies are downloaded in one atomic operation
- One FOD = simpler cache management, no partial states

### Platform Handling

The hash accounts for platform via `npm_config_*` environment variables:

```nix
pnpmDeps = fetchPnpmDeps {
  npm_config_arch = pnpmArch;      # x64, arm64, etc.
  npm_config_platform = pnpmPlatform;  # darwin, linux, etc.
  # ...
};
```

So the **same upstream lock** produces **different hashes per platform** (expected behavior).

---

## 7. Flake Template Structure

nix-openclaw provides a template at `templates/agent-first/flake.nix`:

```nix
{
  description = "OpenClaw local";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    nix-openclaw.url = "github:openclaw/nix-openclaw";
  };

  outputs = { self, nixpkgs, home-manager, nix-openclaw }:
    let
      system = "<system>";  # REPLACE: aarch64-darwin, x86_64-darwin, x86_64-linux
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nix-openclaw.overlays.default ];
      };
    in
    {
      homeConfigurations."<user>" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          nix-openclaw.homeManagerModules.openclaw
          {
            home.username = "<user>";
            home.homeDirectory = "<homeDir>";
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;

            programs.openclaw = {
              documents = ./documents;
              config = { /* ... */ };
              instances.default = {
                enable = true;
                plugins = [ /* ... */ ];
              };
            };
          }
        ];
      };
    };
}
```

---

## 8. Recommendations for Consumer Config

Based on the nix-openclaw architecture, here are best practices:

### Standard Setup (No Hash Overrides Needed)

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  home-manager.url = "github:nix-community/home-manager";
  nix-openclaw.url = "github:openclaw/nix-openclaw";
};

# Use nix-openclaw's pre-built packages (includes correct hashes)
```

### Local Gateway Development

```nix
programs.openclaw.instances.default = {
  gatewayPath = "/Users/you/code/openclaw";
  gatewayPnpmDepsHash = null;  # Let Nix compute it
  plugins = [ /* ... */ ];
};
```

### Multiple Upstream Versions (Prod + Dev)

```nix
inputs = {
  nix-openclaw-stable.url = "github:openclaw/nix-openclaw?ref=v0.1.0";
  nix-openclaw-dev.url = "github:openclaw/nix-openclaw";
};

programs.openclaw.instances = {
  prod = {
    package = nix-openclaw-stable.packages.${system}.openclaw;
    plugins = [ /* prod plugins */ ];
  };
  dev = {
    package = nix-openclaw-dev.packages.${system}.openclaw;
    gatewayPort = 18790;
    plugins = [ /* dev plugins */ ];
  };
};
```

---

## 9. Summary Table

| Component | Location | Type | Override Method |
|-----------|----------|------|-----------------|
| Source pin | `nix/sources/openclaw-source.nix` | Data file | Use different rev/hash |
| pnpmDepsHash | Inside sourceInfo | SHA256 string | Via `gatewayPnpmDepsHash` option |
| Gateway package | `nix/packages/openclaw-gateway.nix` | Derivation | `gatewayPath` + custom hash |
| Home Manager module | `nix/modules/home-manager/openclaw.nix` | NixOS module | Consumer flake integration |
| Template | `templates/agent-first/flake.nix` | Boilerplate | Reference implementation |

---

## References

- **Repository**: https://github.com/openclaw/nix-openclaw
- **Main flake.nix**: https://github.com/openclaw/nix-openclaw/blob/main/flake.nix
- **Source pins**: https://github.com/openclaw/nix-openclaw/blob/main/nix/sources/openclaw-source.nix
- **Gateway package**: https://github.com/openclaw/nix-openclaw/blob/main/nix/packages/openclaw-gateway.nix
- **Common build logic**: https://github.com/openclaw/nix-openclaw/blob/main/nix/lib/openclaw-gateway-common.nix
- **Home Manager module**: https://github.com/openclaw/nix-openclaw/blob/main/nix/modules/home-manager/openclaw.nix
- **Module options**: https://github.com/openclaw/nix-openclaw/blob/main/nix/modules/home-manager/openclaw/options-instance.nix
- **Module config**: https://github.com/openclaw/nix-openclaw/blob/main/nix/modules/home-manager/openclaw/config.nix
