# Hex on nixstation

Hex is pinned in `flake.nix`, installed through its upstream NixOS module,
and started by `hosts/nixstation/hex.nix` as a systemd user service for the
primary user. It follows `nixos-fake-graphical-session.target`, after Hyprland
imports the Wayland environment, and stops with the desktop session.

The host's Hyprland config binds F8 to dictation and F9 to Annotate through
Hex's GlobalShortcuts portal actions. Hold F8 to dictate and release it to
transcribe and paste. Tap F9 to start or finish Annotate; hold it while
recording to draw. Annotate may ask for screen-sharing permission. Sending
captures to OpenCode also needs a running OpenCode service.

The service reapplies only the declared shortcut settings before starting.
Other preferences, history, and downloaded models remain in
`~/.local/share/hex`. No model download happens during NixOS activation.
Use the system application launcher or `hex` to open Settings. Autostart is
owned by systemd; leave Hex's separate Launch at login setting off.
Before startup, the service archives any old Hex-managed user desktop entry
under `~/.local/share/hex/migration-backups`, so the system launcher takes
precedence. Custom entries and symlinks are left alone.

## Runtime compatibility and build time

Hex's nixpkgs follows the system's nixpkgs. Its original pinned runtime used
glibc 2.42, which could not load nixstation's Mesa driver requiring glibc
2.44. Sharing nixpkgs fixes this without a custom loader wrapper.

Ordinary configuration changes reuse Hex when its derivation is unchanged.
Updating nixpkgs can change the compiler or native dependencies and require
a full Hex build, even while Hex's source remains pinned. A missing binary
cache entry means a local build; expect tens of minutes on this host for a
cold build. Updating Hex itself can also require a rebuild. Keep its source
pin deliberate, retain normal Nix generations, and do not disable package
tests merely to reduce build time.

The initial compatibility build passed 1,345 tests (19 ignored), initialized
the RX 570 through Vulkan, and opened the window and tray without a loader
workaround. Physical F8/F9 checks after deployment remain necessary.

## Validation and deployment

```bash
nix build .#nixosConfigurations.nixstation.config.programs.hex.package
systemctl --user status hex.service
hex status
hyprctl globalshortcuts
```

Use the owning `nixstation-update` workflow for full validation and boot
staging. Do not live-switch or reboot without explicit approval.

After the first staged boot, verify a single Hex process, the tray and
window, F8 dictation/paste, F9 Annotate, and startup after logging in again.
Then retire the temporary `~/.local/bin/hex-nix` launcher. The old
Hex-managed desktop entry is archived automatically on service startup.
Preserve user data and models.
