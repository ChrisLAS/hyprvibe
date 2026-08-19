# Nixstation Gaming Cleanup TODO

Goal: remove the currently unused gaming stack from `nixstation`, including
32-bit graphics and audio support. Keep the cleanup host-specific; do not change
gaming support on `nixbook` or `rvbee`.

This document is a checklist only. None of the changes below have been applied.

## 1. Remove gaming packages

In `hosts/nixstation/system.nix`, remove these packages from the local
`packages` list:

- [ ] `lutris`
- [ ] `moonlight-qt` (all occurrences)
- [ ] `sunshine` (all occurrences)
- [ ] `wine-wayland`
- [ ] `steam-run` (all occurrences)
- [ ] `steam`
- [ ] `playonlinux`
- [ ] `vulkan-tools` if it is not wanted for graphics diagnostics
- [ ] `corefonts` if it is no longer needed by Wine or old documents

Several of these packages currently occur more than once. Remove every local
occurrence rather than leaving a duplicate behind.

Disable the shared gaming package group for this host:

```nix
hyprvibe.packages.gaming.enable = false;
```

This removes the shared `steam-run`, `moonlight-qt`, and `vulkan-tools`
packages from `nixstation` without changing the shared package module or the
other hosts.

## 2. Disable gaming integrations

In `hosts/nixstation/system.nix`:

- [ ] Remove the `programs.steam` block. This also removes the Gamescope Steam
  session and the Steam Remote Play and dedicated-server firewall openings.
- [ ] Remove `programs.gamemode.enable = true;` or set it to `false`.
- [ ] Remove `hardware.steam-hardware.enable = true;` or set it to `false`.
- [ ] Leave the commented Sunshine systemd service and security-wrapper code
  disabled, or remove those stale comments in a separate cleanup.

## 3. Disable 32-bit graphics

In `hardware.graphics` for `nixstation`:

```nix
graphics = {
  enable = true;
  enable32Bit = false;
  extraPackages = with pkgs; [
    libva-vdpau-driver
    libvdpau-va-gl
  ];
};
```

- [ ] Change `enable32Bit` from `true` to `false`.
- [ ] Remove `extraPackages32` and its `pkgs.pkgsi686Linux` dependency.
- [ ] Keep normal 64-bit graphics support and `extraPackages` intact.

Before doing this, confirm there are no remaining 32-bit non-gaming programs
that need OpenGL, Vulkan, VA-API, or VDPAU support.

## 4. Disable 32-bit PipeWire ALSA support

The shared services module currently enables 32-bit ALSA support for every
host. Override that setting only on `nixstation` so the other hosts are not
affected:

```nix
services.pipewire.alsa.support32Bit = lib.mkForce false;
```

- [ ] Replace the current host value of `true` with `lib.mkForce false`.
- [ ] Do not change `modules/shared/services.nix` as part of this host-specific
  cleanup.
- [ ] Keep PipeWire, normal ALSA, PulseAudio, and JACK enabled.

The `mkForce` is necessary because `modules/shared/services.nix` also defines
this option as `true`.

## 5. Check for leftovers

After editing, search for remaining gaming declarations:

```bash
rg -n 'steam|lutris|playonlinux|wine-wayland|moonlight|sunshine|gamemode|gamescope|enable32Bit|support32Bit|corefonts' \
  hosts/nixstation/system.nix modules/shared/packages.nix modules/shared/services.nix
```

Expected shared-module matches are acceptable when they are disabled for
`nixstation`. Check the evaluated system package list as well:

```bash
nix eval --json \
  .#nixosConfigurations.nixstation.config.environment.systemPackages \
  --apply 'builtins.map (p: p.name)' \
  | jq -r '.[]' \
  | rg 'steam|lutris|playonlinux|wine|moonlight|sunshine|vulkan-tools'
```

The final `rg` should produce no output.

## 6. Validate without activating

Run the narrow checks first:

```bash
git diff --check
nix eval .#nixosConfigurations.nixstation.config.system.build.toplevel.drvPath
nix build --no-link .#nixosConfigurations.nixstation.config.system.build.toplevel
```

Do not run `nixos-rebuild switch` or `nixos-rebuild test` on `nixstation`.
After a successful build, stage the result for the next boot with the normal
project workflow:

```bash
sudo nixos-rebuild boot --flake .#nixstation
```

## Rollback

If a required 32-bit application is discovered later, restore both of these
settings together:

```nix
hardware.graphics.enable32Bit = true;
services.pipewire.alsa.support32Bit = true;
```

Also restore the required `extraPackages32` entry and only the specific gaming
application or integration that is actually needed.
