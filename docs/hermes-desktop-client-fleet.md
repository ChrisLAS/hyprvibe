# Hermes Desktop Client Fleet

This flake manages two kinds of Hermes hosts:

- **Nomad** is the production Hermes host. It owns the full Hermes agent stack,
  gateways, profiles, skills, services, and the remote dashboard/API.
- **Nixvader and Nixstation** are front-end clients. They should install only
  the Electron Hermes Desktop application and remote-gateway launcher. They must not
  install a local Hermes agent environment, TUI, web application, or optional
  Python integration groups.

The client package is intentionally remote-first. A client does not become a
second Hermes host when the remote backend is unavailable.

## Source Map

The client configuration is in the `hyprvibe` flake:

```text
flake.nix
pkgs/hermes-desktop-nomad.nix
hosts/nixvader/system.nix
hosts/nixstation/system.nix
hosts/nixvader/hermes-pin.md
```

The production Nomad implementation remains in the separate `nomad-nixos`
repository. Do not copy Nomad's full Hermes profiles or services into a client
host.

## Package Design

The root `flake.lock` pins the `hermes-agent` input. The shared
`hermesAgentOverlay` selects upstream `minimal.hermesDesktop`, not the full
`desktop` package. Upstream's desktop wrapper still embeds the full local agent
as a fallback, so the overlay replaces that one fallback executable with a
failing explanatory stub and removes only the local-agent derivation from the
Nix string context. This keeps the Electron renderer and its build inputs while
excluding `hermes-agent-env`, `hermes-tui`, and `hermes-web`.

The wrapper in `pkgs/hermes-desktop-nomad.nix`:

1. Leaves gateway selection and credentials to Desktop's owner-only v2
   connection registry under `$HOME/.config/Hermes`.
2. Logs launch diagnostics to
   `$HOME/.cache/hermes-desktop-remote/launcher.log`.
3. Executes the immutable Nix-store `hermes-desktop` binary.

Register Nomad and Showfactory through **Settings -> Gateways** as remote
gateways on port `9119`. Do not use their OpenAI-compatible API ports for
Desktop. The Nix package disables the local Hermes fallback, so `This device`
is not a usable agent backend on these client-only installations.

It must never run `nix run`, resolve GitHub `HEAD`, or build dependencies when a
user clicks the desktop entry.

## Validation

For a client host, evaluate and build the host-specific toplevel:

```bash
nix build .#nixosConfigurations.nixstation.config.system.build.toplevel --no-link
nix build .#nixosConfigurations.nixvader.config.system.build.toplevel --no-link
```

Inspect the realized closure. It should contain `hermes-desktop` and Electron,
but not `hermes-agent-env`, `hermes-tui`, `hermes-web`, or a versioned local
`hermes-agent` output. Use `nix-store -qR <system-path>` and inspect the names.

Validate the generated launcher and desktop entry from the build output. Check
that the launcher contains a direct store path to `hermes-desktop`, not `nix
run`. Use Desktop's connection **Test** action to validate both HTTP and
WebSocket authentication; never print saved credential values.

## Install, Activation, And Upgrade

1. Read `AGENTS.md`, this document, and the host file before changing a client.
2. Update the pinned input deliberately with `nix flake update hermes-agent`.
3. Build the specific client toplevel and inspect its closure.
4. Stage the generation with `sudo nixos-rebuild boot --flake .#<host>`.
5. Reboot only after the operator approves the live interruption.
6. Launch, close, and relaunch Hermes Desktop from the graphical session.
7. Confirm there is no launch-time `nix` process and inspect the launcher log.

If an upstream revision changes the desktop package shape, update the overlay
and this validation before deploying it to either client. Do not restore the
full `hermes-agent` package merely to make a client build.

## Removal

To remove Hermes Desktop from one client, remove `hermesDesktopRemote`,
`hermesDesktopRemoteEntry`, and `hermes-desktop` from that host's package list,
then build and stage that host. Keep the shared flake input and overlay while
another client uses them. Remove those shared definitions only after all client
references are gone. Never remove Nomad's Hermes source or services as part of
client cleanup.

## Troubleshooting

- A closure containing `hermes-agent-env` or `hermes-tui` means the old full
  package or an old system generation is active. Check the flake revision,
  overlay, build output, booted generation, and current system path.
- A launcher log showing `nix run`, GitHub resolution, or a long build means an
  old wrapper is being executed. Inspect the desktop entry's `Exec=` path and
  the generated wrapper from the current system.
- Electron errors about a missing display during an SSH test are not proof that
  the package is broken. Test from the actual graphical session.
- Remote authentication failures usually mean the saved gateway credential is
  absent or stale. Re-test the specific gateway without exposing the token.
