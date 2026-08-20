# Hermes Desktop package

Nixvader runs Hermes Desktop against the Nomad remote backend. The shared
launcher lives in `pkgs/hermes-desktop-nomad.nix`, and the desktop-only package
selection lives in the Hermes overlay in `flake.nix`. The pinned upstream
revision lives in the root `flake.lock` as `hermes-agent`.

The launcher executes an immutable store binary. It must not use `nix run`,
resolve GitHub `HEAD`, or build dependencies during an interactive launch.

## Desktop-only override

Upstream's `desktop` output embeds the full Hermes agent as a local fallback.
That pulls every optional Python integration into the closure and currently
hits upstream Python packaging failures that are irrelevant to remote mode.

Nixvader derives the Electron application from `minimal.hermesDesktop`, then
replaces the local-agent fallback with a small explanatory stub. The override
removes only the agent derivation from the install phase's Nix string context;
the renderer, Electron, icon, and desktop-entry references remain intact.

The expected closure contains `hermes-desktop-renderer`, `hermes-desktop`, and
Electron. It must not contain `hermes-agent-env`, `hermes-tui`, or `hermes-web`.

## Validation

```bash
nix build .#nixosConfigurations.nixvader.config.system.build.toplevel --no-link
sudo nixos-rebuild boot --flake .#nixvader
```

After reboot, launch, close, and relaunch Hermes Desktop from Vicinae. Both
launches should start immediately without a `nix` process. Runtime diagnostics
remain in `~/.cache/hermes-desktop-nomad/launcher.log`.

Update Hermes deliberately with `nix flake update hermes-agent`, rebuild, and
repeat the closure and launch tests. Do not replace the locked input with an
unpinned launcher command.
