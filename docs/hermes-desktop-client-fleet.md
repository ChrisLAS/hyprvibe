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

Known working client state as of 2026-08-31:

| Client | Gateways | Primary |
| --- | --- | --- |
| Nixstation | Nomad, Showfactory | Nomad |
| Nixvader | Nomad, Showfactory | Nomad |

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

## Connection Registry And Authentication

Desktop owns its per-user gateway registry at:

```text
$HOME/.config/Hermes/connections.json
```

It must be owned by the desktop user and mode `600`. Registry version 2 always
contains a mandatory local entry. On these remote-only clients that entry is a
UI placeholder, not a working backend. Seeing `This device` alongside Nomad is
expected and does not mean Nomad was registered twice. Do not select it, and do
not try to satisfy its authorization prompt.

The current non-secret connection inventory is:

| ID | Label | URL | Auth mode |
| --- | --- | --- | --- |
| `local` | `This device` | none | none |
| `nomad` | `Nomad` | `http://nomad.coin-noodlefish.ts.net:9119` | session token |
| `showfactory` | `Showfactory` | `http://100.65.102.108:9119` | session token |

Use Showfactory's Tailscale IP until its Hermes dashboard host allowlist accepts
`showfactory.coin-noodlefish.ts.net`; the hostname currently returns HTTP 400.
Nomad's hostname is accepted. Both gateways run Hermes `0.20.5` at the time of
this record, while the packaged Desktop is `0.17.0`; verify current pinned and
live versions rather than assuming those numbers remain current.

Desktop sends the saved credential as `X-Hermes-Session-Token` for REST and as
the websocket token for `/api/ws`. Nomad has a stable dashboard session token.
Showfactory preserves Basic authentication for browser access and additionally
accepts its stable Desktop session token through its Nix-owned compatibility
module. The Showfactory implementation and secret remain owned by its
`/etc/nixos` repository and `/var/lib/hermes/credentials/dashboard.env`.

Never put token values in Git, Markdown, shell history, logs, Nix expressions,
or the Nix store. On clients, Desktop currently uses a plaintext token envelope
because secure token storage is disabled; this is accepted only because
`connections.json` is owner-only. `secure-token-storage.json` records that
policy. Prefer the Desktop UI for normal additions. If automation is necessary,
transfer secret material without printing it, write through a mode-`600`
temporary file, validate JSON before atomic replacement, and unset temporary
variables.

A sanitized healthy registry has this shape:

```json
{
  "version": 2,
  "primary": "nomad",
  "launchMode": "primary",
  "lastUsed": "nomad",
  "connections": [
    {"id": "local", "kind": "local", "label": "This device"},
    {
      "id": "nomad",
      "kind": "remote",
      "label": "Nomad",
      "url": "http://nomad.coin-noodlefish.ts.net:9119",
      "authMode": "token",
      "token": {"encoding": "plain", "value": "REDACTED"}
    }
  ]
}
```

Do not copy this example literally: obtain each gateway's credential from its
authoritative secret source and add every required gateway. Back up an existing
registry before changing it. Copying a validated owner-only registry between
Chris's two client hosts is acceptable when both should have the same gateways,
but normalize `lastUsed` and re-test every endpoint on the destination.

## Add A Client Or Gateway

For a new client host:

1. Add the host to the `hyprvibe` flake and install `pkgs.hermes-desktop`, the
   shared `hermesDesktopRemote` wrapper, and `hermesDesktopRemoteEntry`.
2. Build the host and prove its closure is remote-only before activation.
3. Stage with `nixos-rebuild boot`, reboot with operator approval, and launch
   **Hermes Desktop (Remote Gateways)**, not the generic upstream entry.
4. Add each gateway through **Settings -> Gateways**, or seed a reviewed v2
   registry if the first-run UI is trapped on the disabled local backend.
5. Set `primary` and `lastUsed` to a real remote gateway, normally `nomad`.
6. Confirm registry ownership/mode, authenticated REST, websocket connection,
   gateway switching, and a clean close/relaunch.

For a new gateway, first make its Hermes dashboard reachable over the trusted
network on port `9119`, configure a stable Desktop-compatible session token for
both REST and websocket authentication, and validate its hostname allowlist.
Keep browser Basic/OAuth authentication separate if the host needs it. Then add
a uniquely named `remote` entry to each client's registry without changing
working entries or exposing credentials.

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

Read-only shell validation of each saved connection may extract the token into
a local variable and send it directly to `/api/profiles`, but output only the
HTTP status and unset the variable immediately. Expected status is `200`.
Check `backend-ownership.json` as well: an empty `backends` array is expected on
a remote-only client and proves `This device` has no local runtime owner.

## Install, Activation, And Upgrade

1. Read `AGENTS.md`, this document, and the host file before changing a client.
2. Update the pinned input deliberately with `nix flake update hermes-agent`.
3. Build the specific client toplevel and inspect its closure.
4. Stage the generation with `sudo nixos-rebuild boot --flake .#<host>`.
5. Reboot only after the operator approves the live interruption.
6. Launch, close, and relaunch Hermes Desktop from the graphical session.
7. Confirm there is no launch-time `nix` process and inspect the launcher log.
8. Confirm both Nomad and Showfactory still return authenticated HTTP 200 and
   open `/api/ws`; then switch between them in the UI.

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
- `Hermes backend died before its identity could be recorded` means Desktop
  selected the disabled `local` entry. Set `primary` and `lastUsed` to a valid
  remote entry, stop Desktop, and relaunch the remote-gateway desktop entry.
- An authorization wizard for `This device` is not a request for a Nous/Hermes
  online account. Do not use OAuth or **Authorize Desktop app** for these local
  Nix-managed gateways.
- If Desktop appears to show Nomad under `This device`, inspect the registry and
  `backend-ownership.json`. A single `nomad` remote entry plus an empty local
  ownership list indicates a UI/routing artifact, not a duplicate connection.
- Stop Desktop before replacing the registry so it cannot overwrite the file.
  Avoid broad `pkill -f` patterns that can match the SSH writer itself; select
  the Electron process by executable and inspected command line.
- Preserve `connections.json.before-*` backups until the repaired app has
  connected to every gateway. Never include those token-bearing backups in Git.
