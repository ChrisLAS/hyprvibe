# Hokum desktop notifications

All four Hyprvibe desktops use the shared Hokum module: **Nixstation** (studio
workstation, multi-monitor DMS), **Nixvader** (Dell Latitude, DMS), **Nixbook** and
**RVBee** (legacy Waybar shell). Shell choice no longer changes the notification
server. `notify-send` and applications keep using `org.freedesktop.Notifications`.

## Durable ownership

- `pkgs/hokum.nix`: upstream stable **0.1.1**, fixed release URL and SHA256,
  NixOS ELF patching, dynamic Wayland/Vulkan dependencies, launcher and D-Bus
  activation file. Current fleet is x86_64; this recipe is explicitly x86_64.
- `modules/shared/notifications.nix`: enabled with Hyprland; installs Hokum and
  libnotify, disables Dunst packages, masks Dunst/Mako/SwayNC and both historical
  fallback units, and starts `hokum.service` with the graphical session **after
  Hyprland imports its Wayland environment**. Stops with the session.
- `configs/hyprland-base.lua`: no old notification autostart or control commands.
  Both shell fallback scripts retain Hokum rather than launching SwayNC.
- `modules/shared/dms.nix` and `patches/dms-external-notifications.patch`: DMS
  1.6.1 has no external-notification switch. Wrap its server declaration in an
  **uninstantiated QML Component**, keeping the rest of DMS intact. Patch before
  `make sync-shell` embeds QML in the Go executable. Strict patch context/fuzz=0
  makes an incompatible upstream change fail the build, not silently compete.
- `configs/dms/plugins/hokum/`: replaces DMS's built-in notification bell in both
  bars. Watches Hokum's DND property through its CLI; reconnects after restart.

Hokum's initial configuration comes from `configs/hokum/config.kdl` and is seeded
as a **writable** `~/.config/hokum/config.kdl`. This is deliberate: Settings and
DND write that same file. Existing preferences, custom themes/scripts and old
daemon configuration/history are not deleted. Package and service ownership is
Nix-managed; appearance preferences are user-owned. Stable 0.1.1 has no updater;
do not use the newer dev README's unsupported `check-for-updates` setting.

## Controls

| Action | Control |
| --- | --- |
| Hokum settings | Super+Shift+N, or left-click the DMS Hokum bell |
| Dismiss newest | Super+Alt+N |
| Toggle Do not disturb | Super+Ctrl+N, or right-click the DMS Hokum bell |
| Dismiss all | `hokum dismiss --all` |
| Activate newest notification | `hokum invoke` |
| Inspect / follow DND | `hokum dnd --json`, `hokum dnd --json --watch` |

Hokum does **not** provide DMS/SwayNC's persistent notification-history center or
DMS's inline-reply UI. Super+Shift+N now opens Hokum settings, not an old history
panel. App actions and default-click actions remain available. DMS's unrelated
volume/brightness OSDs, lock screen, calendar and desktop shell remain intact.
Do not use DMS's internal notification preferences/DND API to control Hokum.

## Validation

```console
nix build .#hokum --no-link
nix run .#hokum -- check configs/hokum/config.kdl
nix build .#nixosConfigurations.nixvader.config.programs.dms-shell.package --no-link
nix eval --impure --json --expr 'import ./scripts/check-hokum-fleet.nix { flake = builtins.getFlake (toString ./.); }'
```

`scripts/test-hokum-integration.py` runs only below `dbus-run-session`, creates
a temporary HOME/runtime and a headless Sway seat, and cleans up its processes.
Supply built binaries as `--hokum`, `--sway`, and optionally `--dms --quickshell`.
It checks notification ownership, delivery, same-ID replacement, dismissal, DND
and restart persistence. The optional check extracts the **built DMS binary's**
embedded UI through read-only IPC discovery with a fake `qs`, then loads the
exact disabled server component in real Quickshell and confirms it cannot own
the notification bus. It never starts the full DMS shell or touches a real seat.

## Rollout and post-reboot acceptance

Use each owning checkout/branch and the guided update workflow. Nixstation's
`rollout/opencode2-nixstation` has intentional differences from `main`; transfer
only this migration, not a merge of unrelated host changes. Do not update inputs
as part of this migration. Chris selected **boot staging only** on 2026-10-28:
no live switch/test, DMS restart, or reboot is approved.

Verified boot staging as of 2026-10-28 (not live desktop acceptance):

| Host | Generation | Exact candidate | State |
| --- | --- | --- | --- |
| Nixstation | 375 | `9f75179` | Boot-stage receipt verified; running DMS unchanged |
| Nixbook | 102 | `c44a980` | ESP assets verified; running Hyprland/Dunst unchanged |
| Nixvader | 81 | `5c81a5d` | Boot-stage receipt verified; running DMS unchanged |
| RVBee | — | Shared source published | Offline; not deployed |

Exact outputs/receipts and remaining operational issues are recorded in
`.beads/hokum-notifications.md` and `.beads/nixbook-update-20261028.md`.
Evidence-only commits published afterward do not require restaging these exact
candidates. Reboots and real-desktop notification checks remain separate.

After the owner reboots into the staged generation:

```console
systemctl --user status hokum.service
busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.Notifications GetServerInformation
systemctl --user is-enabled dunst.service mako.service swaync.service
notify-send 'Hokum' 'Notification migration test'
hokum dnd --json
```

Expect server `Hokum`, old services masked, a visible card, working settings /
DND bell and keybindings, and no notification-ownership failures in either
`journalctl --user -u hokum -u dms`. Verify on each physical host, not just one.
Offline hosts cannot be claimed deployed or live-verified.

Rollback: select the previous boot generation, then revert the migration source
and rebuild/boot-stage through the owning workflow. Never hand-edit the embedded
DMS extraction or install an old daemon alongside Hokum as a workaround.

Upstream references: [Hokum](https://github.com/anomalyco/hokum/tree/v0.1.1),
[v0.1.1 release](https://github.com/anomalyco/hokum/releases/tag/v0.1.1),
[configuration](https://github.com/anomalyco/hokum/blob/v0.1.1/docs/theming.md).
