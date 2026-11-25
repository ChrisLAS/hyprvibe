# Review XPS 14

Temporary Hyprvibe client for Chris's Dell XPS 14 DA14260 review unit.
Hostname `review-xps14`, user `chrisf`, no disk encryption. The operator explicitly
approved replacement without backing up the stock Ubuntu factory image.

## Ownership and removal

This directory owns every review-specific setting, authorized public key, display
profile, and installation helper. The only external registration is the
`nixosConfigurations.review-xps14` entry in `flake.nix`. Remove that entry and this
directory to retire the host configuration. The Baud input/lock entry can be
removed separately if no other host uses it; shared fixes remain independent.
Tailscale and Syncthing are enrolled. Nebula, Hypruse and Colony builder enrollment
are not provisioned automatically. Before returning the unit, remove the laptop
from each Syncthing peer's declarative device and folder lists, retire its SOPS
device secret and revoke its Tailscale identity.
Reinstall the factory OS and remove personal data before returning review hardware;
removing a flake entry does not erase a laptop.

## Hardware and desktop

- Core Ultra X7 358H, Arc B390/xe, 32GB RAM, KIOXIA 512GB NVMe.
- Panther Lake Wi-Fi/PCIe Bluetooth, SOF/SoundWire audio, IPU75xa camera.
- Latest kernel from the existing repository pin; redistributable/SOF firmware.
- Shared Hyprland Lua desktop, Dux Shell, Hokum, Fish/Kitty; internal panel
  preferred mode at 1.5x scale. Balanced power management, no old Latitude quirks.
- Firmware tools are installed but firmware updates are never automatic.
- Baud is an additional terminal; upstream considers Linux/Wayland experimental and its licence is CC BY-NC-SA 4.0.
- Requested desktop and media apps are installed through Nix where available;
  Flatseal and AkiZip are reconciled from Flathub by a bounded system service.
- Sunshine binds only to this host's Tailscale address. Firefox MCP listens only
  on loopback and requires launching the dedicated Firefox MCP entry.
- Dux integrations are enabled; app credentials are managed separately.

## Production Syncthing

The Nix-managed system service runs as `chrisf`. Seven send-and-receive production
folders live beneath `/home/chrisf/syncthing`: `03-ChrisLAS-PRODS`, `04-LUP`,
`05-TWIB`, `06-Launch`, `07-WYAB`, `10-FRIDAY`, and `50-Heremes`. No backup,
Hyprvibe-hosts or agent-configs folders are enrolled. Laptop edits and deletions
propagate to peers: Syncthing is not a backup.

Nomad and Nixstation share all seven; Showfactory shares LUP, WYAB and Heremes.
The unique Syncthing identity is SOPS-encrypted to this laptop's SSH host key.
The web GUI listens only on `127.0.0.1:8384`; access it locally or use an SSH
tunnel. Check `systemctl status syncthing syncthing-init`, the GUI or
`syncthing cli show connections` for health and direct peer connections.
Initial sync can consume over 100 GiB; check disk space and folder completion
before relying on an offline copy.

## Zed external agents on NixOS

Zed can use `/run/current-system/sw/bin/codex-acp` as a custom external agent.
The Nix package avoids the registry-downloaded generic Linux binaries that do
not run unmodified on NixOS. Codex uses its existing local authentication.

For Nomad-backed OpenCode, use a Zed Terminal Thread running the host's existing
`opencode` command. Its remote-client wrapper connects to Nomad; OpenCode ACP
instead starts a private local server and does not support `--server`. Terminal
Threads use the backend's own MCP configuration, not Zed's MCP server entries;
the local HedgeDoc MCP is not automatically forwarded to Nomad. Remote sessions
also operate on Nomad's paths, not the laptop's local Documents folder. Zed
settings remain user-managed.

## Zed HedgeDoc MCP

Zed's `hedgedoc` context server invokes a user-local bridge at
`~/.local/bin/zed-hedgedoc-mcp`; after boot it delegates to the declarative
`/run/current-system/sw/bin/zed-hedgedoc-mcp`. The bridge preserves startup
using the temporary user-profile package until the staged generation is booted.
The Nix-managed launcher reads the existing two-line bot email/password file
`~/.config/secrets/hdocs` at startup; no credential is placed in the Nix store or
Zed settings. The server defaults to `https://h.docs.lol` and no particular note.
Zed's settings remain user-managed, so preserve the `context_servers.hedgedoc`
entry when editing them. The upstream server allows edits that the bot account
can perform; use a dedicated bot account and review tool approvals in Zed.

The upstream flake is pinned in `flake.lock`; it does not update itself. To take
an upstream update deliberately, use `nix flake lock --update-input hedgedoc-mcp`,
review the lock change, validate/build on this laptop, commit/publish it, and
stage a boot using this host's normal process. Whole-document replacement is
not enabled. Review the server's own concurrency and verification limitations.

## Local-only build and updates

All downloads and compilation for this unit run on the Dell. Builders are empty,
distributed builds disabled, with two jobs/six cores per job. Do not route this
host through the permanent clients' Colony update wrappers.

```sh
cd ~/build/hyprvibe
nix build .#nixosConfigurations.review-xps14.config.system.build.toplevel
sudo nixos-rebuild boot --flake .#review-xps14
# Reboot deliberately, then check the booted system and desktop.
```

The initial `chrisf` password hash is transferred privately from Ubuntu's `dell`
account to `/var/lib/review-xps14/login-password-hash`. Use the same existing
password initially. After changing it with `passwd`, refresh the provisioned hash
without printing it (`sudo sh -c 'getent shadow chrisf | cut -d: -f2 > /var/lib/review-xps14/login-password-hash'`)
so subsequent activations retain the new password. SSH permits the owner-approved
password and public-key authentication and retains the existing host identity. Wi-Fi profiles are copied privately; no passwords or
SSH private keys belong in this directory, the Nix store, or issue notes.

## Installation and recovery

Build `.#nixosConfigurations.review-xps14.config.system.build.reviewInstaller`
on Ubuntu on the Dell. It carries the exact complete client closure in a compressed
RAM store. The store is archived as 1 GiB chunks because newc has a 4 GiB
per-file limit. Early boot reconstructs and SHA-256 verifies the image before
mounting the root filesystem, freeing each consumed chunk to bound RAM use.
The launch helper uses the legacy kexec load API because kexec_file_load rejects
the large initrd, and stops if kernel lockdown is active. No security settings
are changed automatically. Before kexec, privately stage current Wi-Fi profiles, SSH host keys,
login hash and a clean source snapshot in the ESP handoff archive. The installer
loads that archive read-only through an explicitly ordered systemd service before
NetworkManager and SSH. The legacy postBootCommands hook is disabled because
the pinned nixos-init does not execute it. Diagnostics are saved to the ESP
every 90 seconds until live SSH checks confirm the installer. It never erases disks on
boot. Verify root SSH, the active Wi-Fi connection, RAM/store integrity, hardware
and the selected closure first; Ubuntu remains bootable until the explicit install.
The Ubuntu-side staging helper is `sudo python3 hosts/review-xps14/prepare-handoff.py`;
it expects the source snapshot at `~dell/.local/state/review-xps14-install/source.tar.gz`.
The installer reboots to the existing Ubuntu entry after eight minutes unless
successful live SSH checks create `/run/review-xps14/confirmed`. Disarm that timer
before running `review-xps14-install --check`, then explicitly install.

`review-xps14-install --erase-ubuntu` checks model, disk size, original root
partition UUID, RAM-root filesystem, connectivity and provisioning files. It
formats ONLY the original Ubuntu root partition as ext4 `nixos-review`, retaining
the original ~1GB EFI and ~12GB OEM recovery partition. It installs the built
closure without rebuilding and does not reboot automatically. After successful
NixOS boot, remove the private ESP handoff and obsolete Ubuntu EFI directory/entry
only after checking their exact identities. Do not repartition unrelated disks.

Source is restored under `/home/chrisf/build/hyprvibe`; `/etc/nixos` links to it.
For subsequent changes use `--flake /home/chrisf/build/hyprvibe#review-xps14`.

## Acceptance evidence

Before erasing Ubuntu, record its baseline: the factory image reported no ALSA
soundcards and deferred SOF/SoundWire probing, plus camera/CVS driver warnings.
Those are not proof of NixOS regressions. Post-install checks must distinguish
enumerated devices from actual playback/capture and verify:

- correct current/booted profile, no failed units, SSH/sudo and Wi-Fi;
- live xe acceleration, panel scaling, Hyprland config errors, Dux/Hokum ownership;
- sound/microphone, camera, Bluetooth, brightness, battery/power controls;
- lid/suspend/resume and external displays when the operator can observe them.

Do not claim physical playback/capture, battery life or suspend reliability from
configuration evaluation or a successful build alone.

The shared Beads database currently uses schema32, compatible with `bd` 1.0.3.
This host installs Beads from the pinned compatible nixpkgs revision; do not run
a newer Beads client against the shared database without an agreed migration.
