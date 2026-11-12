# Review XPS 14

Temporary Hyprvibe client for Chris's Dell XPS 14 DA14260 review unit.
Hostname `review-xps14`, user `chrisf`, no disk encryption. The operator explicitly
approved replacement without backing up the stock Ubuntu factory image.

## Ownership and removal

This directory owns every review-specific setting, authorized public key, display
profile, and installation helper. The only external registration is the
`nixosConfigurations.review-xps14` entry in `flake.nix`. Remove that entry and this
directory to retire the source configuration. Shared modules/lockfile and other
hosts need no changes. No Tailscale, Syncthing, Nebula, remote AI credentials,
Hypruse enrollment, or Colony builder enrollment is provisioned automatically.
If any are added later, record and revoke those identities before returning the unit.
Reinstall the factory OS and remove personal data before returning review hardware;
removing a flake entry does not erase a laptop.

## Hardware and desktop

- Core Ultra X7 358H, Arc B390/xe, 32GB RAM, KIOXIA 512GB NVMe.
- Panther Lake Wi-Fi/PCIe Bluetooth, SOF/SoundWire audio, IPU75xa camera.
- Latest kernel from the existing repository pin; redistributable/SOF firmware.
- Shared Hyprland Lua desktop, Dux Shell, Hokum, Fish/Kitty; internal panel
  preferred mode at 1.5x scale. Balanced power management, no old Latitude quirks.
- Firmware tools are installed but firmware updates are never automatic.
- Curated local desktop/development utilities rather than permanent-host AI/cloud
  runtimes and production synchronization state.

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
so subsequent activations retain the new password. SSH is public-key-only and retains
the existing host identity. Wi-Fi profiles are copied privately; no passwords or
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

The shared Beads database currently uses schema32, compatible with `bd`1.0.3.
For issue work use `nix run github:NixOS/nixpkgs/c27cdad491a991b11ed731760aa2ef8db0cb0410#beads -- ...`
instead of migrating the shared database with a newer client. Beads is deliberately
not included in this host's package list until the shared database is migrated.
