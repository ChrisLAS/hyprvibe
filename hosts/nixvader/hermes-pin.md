# Hermes Desktop package

Nixvader runs Hermes Desktop as a client for registered remote gateways. The shared
launcher lives in `pkgs/hermes-desktop-nomad.nix`, and the desktop-only package
selection lives in the Hermes overlay in `flake.nix`. The pinned upstream
revision lives in the root `flake.lock` as `hermes-agent`.

The working registry contains Nomad and Showfactory, with Nomad primary. Gateway
URLs, authentication design, registry schema, onboarding, upgrade validation,
and recovery are documented in `../../docs/hermes-desktop-client-fleet.md`.
The mandatory `This device` entry is intentionally unusable on this remote-only
host; it is not a duplicate Nomad profile.

The launcher executes an immutable store binary. It must not use `nix run`,
resolve GitHub `HEAD`, or build dependencies during an interactive launch.

## Desktop-only override

Upstream's `desktop` output embeds the full Hermes agent as a local fallback.
That pulls every optional Python integration into the closure and currently
hits upstream Python packaging failures that are irrelevant to remote mode.

Nixvader derives the Electron application from `minimal.hermesDesktop`, then
passes a small explanatory stub through upstream's `hermesAgent` argument.
The Desktop-only provenance stamp records the locked release and external Nix
update ownership without retaining the local Python/package-manager runtime.
The release's committed icon assets avoid building the full agent environment
for icon generation. No bundled JavaScript or Nix string context is rewritten.

The expected closure contains `hermes-desktop-renderer`, `hermes-desktop`, and
Electron. It must not contain `hermes-agent-env`, `hermes-tui`, or `hermes-web`.

## Validation

```bash
nix build .#nixosConfigurations.nixvader.config.system.build.toplevel --no-link
sudo nixos-rebuild boot --flake .#nixvader
```

After reboot, launch, close, and relaunch Hermes Desktop from Vicinae. Both
launches should start immediately without a `nix` process. Runtime diagnostics
remain in `~/.cache/hermes-desktop-remote/launcher.log`.

Review and update the explicit stable tag and `desktopVersion` in `flake.nix`
together, then run `nix flake update hermes-agent`, rebuild, and repeat the
closure and launch tests. `scripts/check-hermes-desktop.py` checks the recipe
and optionally the exact built package/system without touching credentials.
Do not replace the locked input with an unpinned launcher command.
