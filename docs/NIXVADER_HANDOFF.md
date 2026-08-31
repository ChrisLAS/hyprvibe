# Nixvader Handoff

This is the resume point for the Dell Latitude 7490 host `nixvader`.

## Current State

- Flake target: `.#nixvader`
- Host checkout: `/home/chrisf/build/config`
- Last known LAN address: `172.16.0.32`
- Tailscale address: `100.112.13.59`
- Tailscale name: `nixvader.coin-noodlefish.ts.net`
- Durable upstream branch: `ChrisLAS/hyprvibe` `main`
- Current source commit: `8fa46e0` (`Equip nixvader for mobile desktop work`)
- Theme commit: `904e36a` (`Align nixvader desktop theme with rvbee`)

Commit `8fa46e0` is pushed to `origin/main` and its exact tree passes:

```bash
nix build .#nixosConfigurations.nixvader.config.system.build.toplevel --no-link
```

A live switch of the application and integration changes succeeded before
network access to the laptop was lost. The only source change in `8fa46e0`
that was not in that live generation is a minor improvement to the lock
binding: it uses the current Hyprland instance instead of hard-coding instance
zero.

## Implemented

- RVBee-inspired Waybar, Qt dark styling, icons, and shared wallpaper
- Native laptop panel at `1920x1080@60`, scale `1`
- Intel laptop hardware, battery, backlight, Bluetooth, power, and thermal
  configuration retained
- Steam, Gamemode, and shared gaming packages removed
- Broad non-gaming desktop, media, backup, sync, and development application
  set installed
- CUPS printing enabled
- ChatGPT Desktop packaged from the locked OpenAI Debian metadata input
- `opencode2`, `opencode2-nomad`, and `opencode2-nomad-status` installed
- Hermes Desktop Nomad wrapper and desktop entry installed
- OpenCode and Hermes credentials provisioned outside the repository with mode
  `0600`
- Shared Hyprland launcher, logout, lock/DPMS, Obsidian, monitor wake,
  screenshot, and touch gesture bindings repaired
- Laptop power-profile menu bound to `SUPER+SHIFT+P`
- Dunst, Junction, NetworkManager applet, and persistent clipboard dependencies
  installed

The relevant sources are:

```text
hosts/nixvader/system.nix
hosts/nixvader/monitors.lua
hosts/nixvader/waybar.json
hosts/nixvader/waybar.css
configs/hyprland-base.lua
modules/shared/opencode2-client.nix
modules/shared/packages.nix
modules/shared/power.nix
pkgs/chatgpt-desktop.nix
```

## Network Blocker

After Tailscale authentication, the laptop stopped responding over its LAN
address even though video showed the Hyprland desktop running.

Observed from Nomad on 2026-08-17:

- Pi-hole DHCP still assigned `172.16.0.32` to `nixvader`.
- Nomad and Pi-hole both failed ARP resolution for `172.16.0.32`.
- The Tailscale control plane listed `nixvader` as enrolled and online at
  `100.112.13.59`.
- Nomad reported the peer as `InNetworkMap: true`, `InMagicSock: false`, and
  `InEngine: false`; `tailscale ping 100.112.13.59` returned `unknown peer`.
- No Tailscale admin/API credential or access-policy source was found in the
  Nomad repository or local secret directory.

The LAN failure and Tailscale policy visibility are separate issues. Check the
laptop's interface first, then inspect device approval and the active tailnet
access policy. The operator's intended policy is unrestricted host-to-host
tailnet access; retain only controls required for network operation.

On the laptop, collect:

```bash
ip -brief address
ip route
nmcli general status
nmcli device status
tailscale status
tailscale debug prefs | jq '{WantRunning, LoggedOut, CorpDNS, RouteAll, ExitNodeID}'
systemctl status NetworkManager tailscaled sshd --no-pager
```

From Nomad, verify both paths:

```bash
ping -c 3 172.16.0.32
tailscale ping -c 3 nixvader.coin-noodlefish.ts.net
ssh chrisf@172.16.0.32 hostname
ssh chrisf@nixvader.coin-noodlefish.ts.net hostname
```

## Reconcile The Host Checkout

The laptop checkout is expected to remain at `904e36a` with the audit changes
present as uncommitted working-tree edits. Do not discard anything until the
diff has been inspected.

```bash
cd /home/chrisf/build/config
git fetch origin
git status --short
git diff --stat origin/main
git diff origin/main
```

Expected result: the working files match `8fa46e0` except that the deployed
`SUPER+L` command contains `hyprctl -i 0 eval`, while `origin/main` contains
`hyprctl eval`.

Only if that expectation is confirmed, remove the copied deployment edits and
fast-forward to their committed equivalent:

```bash
git diff > /tmp/nixvader-pre-sync.patch
git restore --source=HEAD --staged --worktree -- \
  configs/hyprland-base.lua \
  flake.lock \
  hosts/nixvader/monitors.lua \
  hosts/nixvader/system.nix \
  modules/shared/packages.nix \
  modules/shared/power.nix
git merge --ff-only origin/main
git status --short --branch
```

If any unrelated changes appear, stop and preserve them instead of running the
restore command.

## Build And Activate

```bash
cd /home/chrisf/build/config
nix build .#nixosConfigurations.nixvader.config.system.build.toplevel --no-link
sudo nixos-rebuild switch --flake .#nixvader
```

Then log out and back in so all session-start applications and environment
changes are exercised.

## Acceptance Checks

### System And Desktop

```bash
systemctl --failed --no-pager
systemctl --user --failed --no-pager
systemctl is-active tailscaled cups cups-browsed NetworkManager systemd-resolved display-manager
hyprctl configerrors
hyprctl monitors
hyprctl layers -j | jq '[.[]?.levels[][]? | select(.namespace | contains("waybar"))] | length'
```

Expected: no failed units, all listed services active, no Hyprland config
errors, one native `1920x1080@60` monitor at scale `1`, and one Waybar layer.

Confirm the repaired bindings manually:

- `SUPER+SPACE`: Vicinae
- `SUPER+F`: Junction browser chooser
- `SUPER+O`: Obsidian
- `SUPER+B`: brightness menu
- `SUPER+SHIFT+P`: power-profile menu
- `SUPER+L`: lock and display off
- `SUPER+ALT+L`: display on
- `Print`: region to clipboard
- `SHIFT+Print`: region to `~/Pictures`

### OpenCode V2

The secret path is `$HOME/.config/secrets/opencode2-server.env`. Do not print
its contents.

```bash
stat -c '%U:%G %a %n' "$HOME/.config/secrets/opencode2-server.env"
opencode2-nomad-status
cd /home/chrisf/build/nomad-nixos
opencode2-nomad
```

Expected: mode `600`, a successful health response from
`https://nomad.coin-noodlefish.ts.net:8444`, and an attached TUI using Nomad's
project backend.

### ChatGPT Desktop

```bash
command -v chatgpt-desktop
grep -E '^(Name|Exec)=' /run/current-system/sw/share/applications/chatgpt.desktop
chatgpt-desktop
```

The installed package was built successfully as version `26.810.52044`.
Future metadata updates use:

```bash
nix flake update chatgpt-linux-metadata
```

Review and commit the resulting `flake.lock` change after rebuilding.

### Hermes Desktop

The provisioned Nomad secret path is
`$HOME/.config/secrets/hermes_dashboard_session_token`. Do not print its
contents. Desktop's active saved credentials live in its owner-only connection
registry; the standalone Nomad secret file is not exported by the launcher.

The wrapper executes the immutable Nix-store Hermes Desktop binary. Gateway
URLs and credentials live in Desktop's owner-only v2 registry at
`$HOME/.config/Hermes/connections.json`; the wrapper does not force Nomad or
export a token. The shared client-fleet package selection uses
`minimal.hermesDesktop` and removes the unused local-agent fallback. Nixvader
is a remote client with Nomad and Showfactory registered; Nomad is primary.

```bash
stat -c '%U:%G %a %n' "$HOME/.config/secrets/hermes_dashboard_session_token"
nix build .#nixosConfigurations.nixvader.config.system.build.toplevel --no-link
hermes-desktop-remote
tail -n 100 "$HOME/.cache/hermes-desktop-remote/launcher.log"
```

Expected: mode `600`, a successful NixOS build, an immediate launch without a
`nix` process, and Hermes Desktop able to switch between Nomad and Showfactory.
The mandatory `This device` registry entry has no local backend and should not
be authorized or used. The realized
closure should not contain `hermes-agent-env`, `hermes-tui`, `hermes-web`, or a
versioned local `hermes-agent` output. For the complete client install,
upgrade, removal, and troubleshooting procedure, read
`docs/hermes-desktop-client-fleet.md`.

## Known Validation

Before connectivity was lost, the live generation had:

- active CUPS, NetworkManager, systemd-resolved, and display manager
- no failed system or user units
- no Hyprland configuration errors
- generated ChatGPT, Obsidian, and Hermes desktop entries
- expected OpenCode, ChatGPT, Hermes, Obsidian, Junction, Dunst,
  NetworkManager applet, and power-profile commands
- no `steam` or `gamemoderun` command

Backend acceptance remains incomplete only because the laptop became
unreachable immediately after Tailscale enrollment.
