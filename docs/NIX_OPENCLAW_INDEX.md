# nix-openclaw Documentation Index

This index documents research on how to override pnpm-deps hashes in consumer flakes that use nix-openclaw.

## Files in This Documentation

1. **NIX_OPENCLAW_RESEARCH.md** (502 lines, 15KB)
   - Comprehensive research document
   - All 9 sections with detailed technical explanations
   - References to source files
   - Three override approaches with code examples
   - Key technical concepts (FOD, platform handling, etc.)

2. **NIX_OPENCLAW_QUICK_REFERENCE.md** (295 lines, 7.5KB)
   - Quick reference guide with code snippets
   - Immediate copy-paste examples
   - Workflow steps
   - Troubleshooting section
   - Commands for debugging

## Quick Navigation

### If you want to understand the architecture
Start with: NIX_OPENCLAW_RESEARCH.md
- Section 1: Where pnpm-deps is defined
- Section 4: flake.nix structure
- Section 6: Key technical details

### If you want to implement in your config
Start with: NIX_OPENCLAW_QUICK_REFERENCE.md
- "Consumer Flake: Local Gateway Development"
- "Workflow: Computing Hash for Local Gateway"
- Troubleshooting section

### Key Takeaways

1. **Hash is defined in**: `nix/sources/openclaw-source.nix` in nix-openclaw repo

2. **Current hash value**: `sha256-QnKPVUPgy3znCQRmfqiIPtRLgZ0SPwWqUsJ4USF2LJE=`

3. **To override in your flake**:
   ```nix
   programs.openclaw.instances.default = {
     gatewayPath = "/path/to/local/openclaw";
     gatewayPnpmDepsHash = null;  # Let Nix compute it
   };
   ```

4. **Workflow**:
   - Set hash to null
   - Run `home-manager switch`
   - Copy suggested hash from error
   - Set hash in config
   - Run `home-manager switch` again

## Repository Structure

```
openclaw/nix-openclaw/
├── nix/
│   ├── sources/
│   │   └── openclaw-source.nix        # Hash is defined here
│   ├── packages/
│   │   ├── openclaw-gateway.nix       # Uses hash from sourceInfo
│   │   └── default.nix                # Package entrypoint
│   ├── lib/
│   │   └── openclaw-gateway-common.nix # Shared build logic
│   └── modules/
│       └── home-manager/
│           └── openclaw/
│               ├── options-instance.nix # gatewayPnpmDepsHash option
│               ├── config.nix           # How hash is passed
│               └── default.nix          # Module entrypoint
├── templates/
│   └── agent-first/
│       └── flake.nix                  # Consumer template
└── flake.nix                          # Root flake
```

## Key Files (GitHub URLs)

| File | Purpose | URL |
|------|---------|-----|
| openclaw-source.nix | Hash definition | https://github.com/openclaw/nix-openclaw/blob/main/nix/sources/openclaw-source.nix |
| openclaw-gateway.nix | Package definition | https://github.com/openclaw/nix-openclaw/blob/main/nix/packages/openclaw-gateway.nix |
| openclaw-gateway-common.nix | Build logic | https://github.com/openclaw/nix-openclaw/blob/main/nix/lib/openclaw-gateway-common.nix |
| options-instance.nix | Module options | https://github.com/openclaw/nix-openclaw/blob/main/nix/modules/home-manager/openclaw/options-instance.nix |
| config.nix | Module config | https://github.com/openclaw/nix-openclaw/blob/main/nix/modules/home-manager/openclaw/config.nix |
| agent-first template | Consumer template | https://github.com/openclaw/nix-openclaw/blob/main/templates/agent-first/flake.nix |
| root flake.nix | Main flake | https://github.com/openclaw/nix-openclaw/blob/main/flake.nix |

## Three Ways to Override Hash

### 1. Standard (Recommended for most users)
No override needed. Use nix-openclaw as-is. Pre-built packages include correct hashes.

### 2. Local Gateway Development (Recommended for contributors)
```nix
programs.openclaw.instances.default = {
  gatewayPath = "/Users/you/code/openclaw";
  gatewayPnpmDepsHash = null;
};
```
Best for local development. Let Nix compute the hash automatically.

### 3. Advanced (Custom package definition)
Use `pkgs.callPackage` to build a completely custom gateway with different:
- Source revision
- Source hash
- pnpmDepsHash

See NIX_OPENCLAW_RESEARCH.md Section 5 for full example.

## Understanding the Hash

### What is pnpmDepsHash?

A SHA256 hash of the **fixed-output derivation** containing all pnpm dependencies:
- Downloaded from npm registry
- Pinned by pnpm lockfile + version
- Platform-aware (different hash per platform)
- Used for security and caching

### Why separate from source hash?

Two hashes because:
1. **Source hash**: Upstream OpenClaw repository content
2. **pnpmDepsHash**: Downloaded pnpm dependencies cache

Different because npm dependencies are fetched separately via `fetchPnpmDeps`.

### How Nix handles it

1. Fetches source code with `sourceInfo.hash`
2. Reads pnpm-lock.yaml from source
3. Downloads pnpm cache with `pnpmDepsHash`
4. Uses both in build derivation

If either hash is wrong, Nix rejects it (security feature).

## Common Tasks

### Add local gateway development to your config

Edit your `flake.nix` in `programs.openclaw.instances.default`:
```nix
gatewayPath = "/Users/you/code/openclaw";
gatewayPnpmDepsHash = null;
```

### Compute the correct hash

1. Keep `gatewayPnpmDepsHash = null`
2. Run `home-manager switch --flake .#youruser`
3. Nix will show error with correct hash
4. Copy hash to `gatewayPnpmDepsHash`

### Update hash when pnpm-lock.yaml changes

Same process as computing:
1. Set `gatewayPnpmDepsHash = null`
2. Run `home-manager switch`
3. Copy new hash from error message

### Debug hash mismatch errors

Check:
1. Is `gatewayPath` correct and absolute?
2. Does pnpm-lock.yaml exist in that directory?
3. Is the pnpm version still `pnpm_10`?
4. Are you on the same platform (macOS/Linux) you're building for?

## Search Results Summary

**Repository**: github.com/openclaw/nix-openclaw

**Research Performed**:
1. Located pnpm-deps hash definition
2. Traced how hash is used in package builds
3. Found module options for overriding hash
4. Examined home-manager module integration
5. Reviewed consumer template
6. Analyzed three override approaches

**Key Finding**: The mechanism for hash override exists and is well-designed:
- `gatewayPnpmDepsHash` module option
- Integrates with `gatewayPath` for local development
- Uses `lib.fakeHash` to auto-compute hashes
- Clean separation between source and deps hashes

**Documentation Status**: Not yet documented in nix-openclaw user docs, but fully supported in code.

## Next Steps

1. If implementing local gateway: Follow NIX_OPENCLAW_QUICK_REFERENCE.md
2. If understanding architecture: Read NIX_OPENCLAW_RESEARCH.md
3. If debugging hash issues: See troubleshooting section in Quick Reference
4. If contributing upstream: Reference this research when discussing module design

