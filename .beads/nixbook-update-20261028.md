# Nixbook published-source update — 2026-10-28

## Authorization and acceptance

Chris explicitly requested independent background-agent work to bring online
Nixbook up to current published Hyprvibe source/pins including Hokum. Build and
boot-stage only: no live switch/test, desktop restart, or reboot. Do not touch
Nixvader or the parent's Nixstation work; no fleet-wide pin refresh. Preserve
unrelated work, host identity, shell choice and bootloader settings.

## Verified baseline and route

- Nomad isolated worktree: `/home/chrisf/build/hyprvibe-nixbook-update`, branch
  `ops/nixbook-update-20261028`; parent and stale original checkout untouched.
- Initial published `origin/main`: `c44a9804ad4418c08018a5d55035feacafbf2641`.
- SSH `nixbook` uses its existing verified host key; direct tailnet IP lacked a
  known-host entry, so used the known hostname, without disabling verification.
- Target hostname `nixbook`, user `chrisf`; owning checkout
  `/home/chrisf/build/config`, clean `main` at `d9e0e78` (2026-09 baseline).
  Origin `https://github.com/ChrisLAS/hyprvibe.git`.
- Read root policies, current guided/Colony/notification docs and target local
  policy/docs. No target-specific AGENTS or Nixbook guided wrapper discovered.
  Ordinary Nix is local (`builders =`), bootloader is systemd-boot, auto-upgrade
  already uses `operation = boot`, no reboot. `/etc/nixos/flake.nix` forwards to
  this owning checkout; use explicit `.#nixbook`, not stale wrapper locks.
- Current and booted system:
  `/nix/store/9ny7bbhjknpfdcl5aka5dbmz2js1ylc6-nixos-system-nixbook-26.11.20260917.e554fab`.
  Existing staged profile:
  `/nix/store/cx1b8vd1ziiaq85g2s6gl8irbvvcc4vn-nixos-system-nixbook-26.11.20260917.e554fab`
  (generation 101). Preserve previous generations.
- 399 GiB available on root/Nix and 2.6 GiB on ESP; ~13 GiB available RAM,
  AC online. No target jobs/builds observed. No Colony dispatch planned.

## Completed and active work

- Fetched target origin and verified clean source, fast-forward ancestry and no
  Nixbook hardware changes. Advanced owning `main` from `d9e0e78` to exact
  published `c44a9804ad4418c08018a5d55035feacafbf2641`. No input refresh:
  changes to lockfile are only those already published.
- Target evaluation passes all NixOS assertions (`[]` failed assertions).
  Existing notification checker scoped to Nixbook passes: legacy shell (`dms =
  false`), Hokum 0.1.1, no old server packages, all five old/fallback services
  disabled/masked, required D-Bus/session dependencies. Boot policy remains
  systemd-boot true / GRUB false / EFI writes true.
- Exact toplevel derivation:
  `/nix/store/izkn5is8s6rzbyy9qs4m7jki8ivzca9g-nixos-system-nixbook-26.11.20260917.e554fab.drv`.
  Expected output:
  `/nix/store/bvp3am6ma68ab13zcwgy38ikjdnyjw52-nixos-system-nixbook-26.11.20260917.e554fab`.
- Full build passed on Nixbook itself, existing ordinary local Nix route,
  bounded `--max-jobs 2 --cores 2`, no remote builder. Retained result/logs and
  before-state evidence: `~/.local/state/nixbook-update-20261028/`. Build source
  is checked clean and exact commit; `--no-update-lock-file` is enforced.
  Build ran 17:07:42–17:08:27 PDT. No source compatibility fixes were needed.
- Current desktop is still Hyprland PID 278880 with Dunst active. No user
  services were started/stopped. Notifications must remain old/live until reboot.
- Auto-upgrade service inactive; next timer ~02:12 on Oct 29, >9 hours away at
  admission. No competing target jobs. Existing staged generation 101 retained.

## Boot-stage acceptance — achieved

- `sudo nixos-rebuild boot --flake /home/chrisf/build/config#nixbook
  --no-update-lock-file --max-jobs 2 --cores 2` succeeded at 17:10 PDT. The
  system profile is now the exact verified `bvp3am6...` output above, generation
  **102**. Boot-stage logs explicitly say `action = boot`; no switch/test/reboot
  occurred. Systemd-boot version already matched and was not replaced.
- Default boot entry:
  `nixos-ff035b59ca97de1573b341d14968738b28ba51571ef60809152c0675e2fef940.conf`.
  Its `init=` points to the exact output. Previous generation **101** remains
  available. ESP kernel and initrd both pass byte comparisons against output:
  kernel SHA256 `4b146d5029a4605181c41308863e718aba4b8b7886c94ddc31a4dd56c42c0385`;
  initrd SHA256 `3e5693e03181cf37be333cb677fa780600f6d1a2b983b4ad8cff84f382978d43`.
- `nix-store --verify-path` passed for toplevel and exact Hokum output
  `/nix/store/hqqbyiq3y85wv1a575q8mdz09dg5x33p-hokum-0.1.1`. No signature or
  content-verification settings changed; outputs built on target, not copied
  from an untrusted store.
- Inspected actual built system: all five old/fallback user units resolve to
  `/dev/null`; Hokum unit is Type=dbus, correct bus name, seeded writable config
  dependency, graphical-session target membership. D-Bus activation file
  `app.hokum.Notifications.service` names `org.freedesktop.Notifications` and
  `SystemdService=hokum.service`. No old daemon executable or runtime closure
  package remains. Stable Hokum `check configs/hokum/config.kdl` passes.
- Built immutable Hyprland composition
  `/nix/store/lkb5xyv36n14s8d6zr9p229yapx12nh0-hyprvibe-hyprland-config`
  has correct Hokum bindings and environment import before graphical-session
  startup; no SwayNC/Dunst/Mako references. Legacy Waybar shell retained.
- Post-staging `/run/current-system` and `/run/booted-system` both unchanged at
  `9ny7bb...`; Hyprland PID **278880** and executable unchanged; Dunst still
  active and Hokum inactive, as expected before reboot. No desktop restart.
- Owning Nixbook checkout remains clean `main` at `c44a980`; lockfile SHA256
  matches pre-build. Nixvader and parent's Nixstation jobs/source untouched.
- Complete target evidence lives in `verification.log`, `build.log`,
  `staging.log`, `boot-entries-before`, `boot-entries-after`, before-state files
  and retained `result` under the state directory above.

## Remaining work / handoff

Boot-staging objective achieved with no host blocker. Actual Hokum desktop
acceptance is deliberately pending a separately Chris-approved Nixbook reboot:
follow `docs/NOTIFICATIONS.md` post-reboot checks for bus owner, visible card,
settings, dismissal/DND, persistence and absence of competing services. No live
desktop success is claimed. Generation 101 remains the boot rollback option.

Current published nixpkgs remains `e554fab72f81915600f3f449b786fd9af40439a5`
(2026-09-17); this updates to published repository pins, not latest upstream.
A new nixpkgs/Hyprland input refresh or discretionary application upgrades is
distinct additional scope, not attempted. Build emitted existing package-path
collision/deprecation warnings (e.g. multiple PostgreSQL/Thunar/portal entries),
not build failures; unrelated package cleanup was not included.

Publish this handoff independently from exact staged candidate; do not restage
merely to append documentation. No newly created stash or temporary branch was
used on Nixbook; retained result/state are intentional recovery evidence.

## Tracking

Nomad `bd status`, `bd dolt pull`, `bd dolt push` all refuse independent remote
schema v32 -> v66 migration. No migration/replacement performed. On Nixbook,
`bd status` succeeds against its existing embedded local DB but reports zero
issues; do not initialize independent issue history there. Supplemental handoff
follows existing repository practice. `bd status` created an empty untracked
`.beads.gate.lock` on target; removed only that agent-created empty lock before
source advancement. Existing local DB/backups and issues were not discarded.

Diagnostics corrected without source changes: a handwritten option query used
nonexistent fallback names; replaced with the existing repository checker.
An SSH nested-quote diagnostic failed parsing before execution; use `bash -s`
heredoc for subsequent remote scripts. Initial D-Bus activation filename query
assumed a conventional name; corrected to package's actual
`app.hokum.Notifications.service`. ESP reads require sudo; read-only evidence
checks rerun successfully with existing sudo authorization. None required source
changes or a new build candidate.
