# Nixstation recovery and current-main integration (2026-10-29)

## Active continuation: full desktop and current build
- Chris reports basic Hyprland/keybinds work, but no bar/launcher/correct wallpaper.
  Requests a fully current Nixstation build and integration of pending Git work
  into main. Authorized diagnosis, source reconciliation/publication, input
  refresh/build/validation and safe boot staging. No new full live switch/test or
  reboot approved. Preserve user data, other worktrees and credentials; no agent
  delegation requested. Previous successful boot did NOT verify full desktop.
- Integration worktree: `/home/chrisf/build/worktrees/hyprvibe-nixstation-current-20261029`,
  branch `integration/nixstation-current-20261029`, based on current origin/main
  8c7691e. In-progress merge of fix branch80e4ee3 brings station rollout history
  and activation resilience into main without dropping Nixvader webcam/Firefox,
  Steam, Sunshine, or current documentation. Main's intentional release pins
  remain distinct from mutable flake-input refresh.
- Original Nomad main checkout remains untouched with its two pending station
  edits (better-adb-sync and experimental-features formatting); both are already
  semantically included by integration. Other worktrees clean at inventory time.
- Nixstation owning checkout clean on rollout/opencode2-nixstation9f75179. Keep
  owning branch identity required by deployed wrapper; it can fast-forward to
  the same integrated main revision rather than silently weakening branch guards.
- Root cause at17:55Z: dms.service LoadState=error/FileExists; journal says two
  services allocated org.freedesktop.Notifications. Hokum active, DMS never ran.
  This is a unit LOAD error, not visible in systemctl --failed. DMS unit from
  package still Type=dbus/BusName=Notifications although QML server was disabled.
- Durable fix in modules/shared/dms.nix patches packaged DMS unit to Type=simple
  and removes BusName line; keeps QML server patch. Fleet evaluation and actual
  built-unit integration tests now cover the missing unit boundary.
- Important failed attempt: BusName= empty drop-in is INVALID in systemd261,
  ignored by config_parse_bus_name (confirmed exact upstream source and journal).
  Merely setting Type=simple temporarily allowed DMS start but could transfer
  the load error to Hokum. Replaced this with a full corrected runtime unit.
- Full runtime unit at `/run/user/1000/systemd/user.control/dms.service`, derived
  from existing packaged unit with only Type/BusName edits; vanishes on reboot.
  `/run/user/1000/systemd/user/dms.service` was lower precedence than /etc and did
  NOT override it; moved to verified high-precedence runtime user.control path.
  Own initial invalid drop-in removed. No persistent user config override.
- At18:01Z: both units LoadState=loaded, LoadError empty; DMS Type=simple,
  BusName empty, MainPID10033; Hokum Type=dbus/BusName=Notifications, active.
  DMS started once at17:59:31Z; compositor and apps not restarted. Hypruse shows
  dms:bar on all4 monitors; screenshot of DP-1 verifies bar and correct mountain
  wallpaper. DMS logs report wallpaper/theme loaded and all bar plugins loaded.
  Bus GetServerInformation still returns Hokum0.1.1. Launcher visual test pending.
- All4 host assertions/toplevel derivation evaluations passed after merge/DMS
  serviceConfig changes (before final packaged-unit postInstall edit); rerun on
  final source. No full current build dispatched yet.
- Next: finish source merge/remaining pending branch inventory, refresh mutable
  inputs, rerun checks and publish integrated main. Fast-forward clean owning
  Nixstation checkout, then guided owner-local validation/staging with matching
  exact receipt. Verify actual desktop, not only session/service presence.

## Objective and authority
- Chris requested review/resumption of recovery: get Nixstation back online after
  `Switch root target contains no useable init.` Verify actual installed NixOS
  boot and pinned SSH, not merely successful chroot activation.
- Preserve user data, other checkouts/generations, and production SSH trust.
  Earlier cleanup removed only regenerable `.cache` contents and assistant tests.
  No Downloads/media/build-data deletion, firmware/bootloader change, full build,
  deployment, or live switch/test performed. Chris subsequently selected
  **Reboot it now**, explicitly approving one Ubuntu reboot and selecting/removing
  Ventoy locally for the internal-disk boot test. Sent `sudo systemctl reboot`
  through isolated live SSH, exit 0. No second reboot implicitly authorized.

## Access and source
- Live Ubuntu: `ssh -F /tmp/opencode/nixstation-live/ssh_config nixstation-live`;
  Aurora ProxyJump, Ubuntu at 192.168.7.9, separate temporary known_hosts.
- Installed host key still exactly matches fleet pin; do not replace it with
  Ubuntu's key. Production Tailscale address: 100.75.168.43.
- Installed checkout: `/home/chrisf/build/config/hyprvibe`, branch
  `rollout/opencode2-nixstation`; preserve its unrelated changes.
- Fix worktree: `/home/chrisf/build/worktrees/hyprvibe-nixstation-activation-resilience`,
  branch `fix/nixstation-activation-resilience`, based on deployed 9f751797.
- Source fix commit 0581cad910db673490ab54f21f1f13349dc6b6be: isolate Waybar
  strict mode/trap in subshell with explicit failure accounting; use explicit
  gnused paths in AccountsService activation. Published on the fix branch;
  not built into a new system or deployed.
- Beads CLI is blocked by remote schema v32 -> v66 coordination gate. No
  migration/bootstrap performed. This handoff follows existing `.beads/*.md`
  practice, not a second tracker.

## Diagnosis and prior evidence
- Home writes genuinely failed ENOSPC despite reported free space. Removing about
  20 GB cache restored small-file and 2 GiB write tests. Exact allocator cause is
  unproven; quotas were disabled. Do not assert corruption/metadata exhaustion.
- Original Waybar activation leaks `set -euo pipefail` into the shared shell.
  A failed desktop symlink aborts before final `/run/current-system` creation;
  systemd's compiled init path depends on that link.
- Earlier original-script chroot activation succeeded after freeing space.
  Tiny inode-exhausted tmpfs reproduction failed originally without current-system;
  fixed script still returned failure but created the link and resolved systemd.
  These are script/chroot tests, NOT an actual successful boot.
- Earlier fixed-script chroot test used an evaluated, unbuilt etc derivation and
  left `/etc/static` dangling with managed links removed. Found and repaired
  during this resumed session; do not run evaluated full activation on real root.

## Pre-reboot verified evidence, approximately 17:46–17:49 UTC
- Checks below ran in Ubuntu live USB, before the approved reboot.
- Root `/dev/nvme0n1p1` ext4: 97 GiB available (57% used).
  Home `/dev/sdb2` btrfs: 32 GiB available (88% used).
  Nix `/dev/sda1` btrfs: 150 GiB available (31% used).
  All five home btrfs device error counters zero.
- Current system profile remains generation 375:
  `/nix/store/ysix5xasr9fv51d31knnbzrr06mcnadn-nixos-system-nixstation-26.11.20260917.e554fab`.
- Read-only installed SQLite ValidPaths hash and NAR hash of copied generation
  directory MATCH EXACTLY:
  `sha256:c5f7727b8270dd286b1969886039b984819707e6c2b505e36e86b6a6b0a81af2`.
  This verifies this output directory, not every dependency in its closure.
- GRUB has 40 kernel/initrd references, two unique flat files, all present after
  correctly stripping GRUB `($drive1)` prefix. Root UUID lookup matches NVMe.
  Earlier naive path check incorrectly flagged these GRUB-prefixed paths missing.
- Installed init, activate, prepare-root, and systemd executable readable in chroot.
- Repaired ONLY generated `/etc` using generation 375's own Perl setup-etc helper
  with root briefly writable, nix/home still read-only. Exit 0; locale fallback
  warning only. Did NOT rerun full activation/secrets/user/desktop snippets.
- `/etc/static` restored to `/nix/store/lrsrd1mma9q27l2sj8hcjff3ysa7s8ny-etc/etc`.
  Chroot reads now pass for fstab, os-release, nsswitch.conf, sshd_config,
  systemd default.target, and PAM login. SSH public key unchanged. Diagnostic
  `/tmp/activate.fixed` absent.
- Final committed source activation evaluation succeeds including sed fix;
  no new full activation was executed. Output contains @out@ placeholder.
- Synced and normally unmounted ALL recovery mounts: home, nix, root, top,
  nixroot. Final findmnt reports RECOVERY_MOUNTS=none. No lazy unmount used.
- Scratch evidence: `/tmp/opencode/nixstation-live/` on Nomad. Earlier numbered
  diag scripts include invalid checks and invasive operations; do not rerun blindly.

## Actual boot verification, 17:51–17:53 UTC
- Approved single reboot succeeded. Bounded reconnect job completed; no monitor
  remains. `nixstation-ssh` connected with existing fleet-pinned trust at 17:51:42Z.
- Host identifies as nixstation/NixOS26.11, boot ID
  `f71204ef-8473-45b9-8113-886083694137`. Current AND booted system are gen375.
- At 17:52Z: system state `running`, no system OR user failed units, no jobs.
  SSH, Tailscale, and display-manager active. Local chrisf session on seat0 is
  active Wayland. No visual/UI interaction performed or needed for recovery.
- Actual initrd boot journal records original activation finished successfully,
  Waybar activation complete, and switch-root started. Bare-sed warnings persist
  in old deployed generation as expected; fixed source is NOT deployed.
- `/run/current-system/systemd/lib/systemd/systemd` executable and `/etc/fstab`
  readable after real boot. Disk space unchanged (home 32 GiB available,88% used);
  all home btrfs device counters zero. Bounded boot-kernel grep found no btrfs
  error/corruption, I/O-error, or EXT4-fs-error matches. Its no-match exit1 stopped
  the following tailscale-ip subcommand under set-e; not a boot/service failure.
- `scripts/test-activation-resilience.py` adds isolated evaluated-snippet tests:
  syntax, store-backed sed, success/failure shell-option and ERR-trap isolation,
  and reaching final system link despite synthetic failed desktop symlink.
  All4 tests pass on final source (both generic and preceding-Hyprland contexts).
  Original gen375 negative control fails5 assertions as expected; syntax passes.
  These local tests do not execute full activation or write real host configs.
- `git diff --check` passes. No full build, deployment, extra reboot, firmware
  edit, bootloader edit, or deletion of user data beyond earlier cache cleanup.
- Follow-up 17:53:54Z: Tailscale IP100.75.168.43, system still `running`, same boot.
- Published source fix0581cad and regression/evidence commitcaf910e to
  `origin/fix/nixstation-activation-resilience`; push succeeded and upstream set.

## Remaining delivery and optional follow-up
- Recovery objective achieved: actual installed boot plus healthy services verified.
- Fix and regression tests are published; this handoff records the final evidence.
  No resilience-fix build/staging/live activation is implied.
- Future approved owning-host guided update should include the resilience fix;
  current running generation remains vulnerable if home fills again.
- Further capacity cleanup requires Chris's choice; leave large user-data dirs.
