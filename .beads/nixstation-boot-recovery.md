# Nixstation recovery and current-main integration (2026-10-29)

## Active continuation: full desktop and current build

### Current checkpoint — diagnosed build failure; compatibility repair
- Candidate5a3ffa54 FAILED at21:12:02Z after2h28m. Exact failing derivation:
  vlh7zszk4523hnbfhzr1mwapl356mf4c-hypruse-0.10.0.drv. Wheel built, but the
  runtime dependency checker correctly rejected `mcp<2,>=1.2` with MCP2.2.0.
  Failed launcher/system-path/toplevel entries are downstream of that failure.
  No current validation/result receipts were written; existing9f75179 receipts
  still describe old generation375. Nothing boot-staged, activated, or rebooted.
- Confirmed via actual immutable5a3ffa54 evaluation that PINNED nixpkgs exposes
  python3Packages.mcp_1 version1.29.0 (default mcp2.2.0, Python3.14.8).
  Current upstream MCP-NixOS agrees, but pinned evaluation is authoritative.
  Small repair in pkgs/hypruse.nix selects mcp_1 with fallback to mcp on older
  nixpkgs. No dependency relaxation, skipped checks, or service-policy changes.
- Main build worker is failed/inactive, wrapper.lock is free; guided status has
  no running job. Preserve cached successful outputs. Next: publish intended
  package/harness source, fast-forward owning checkout while retaining refreshed
  flake.lock, then restart SAME persistent validation unit with a new exact
  guided snapshot (production source fix genuinely requires new validation).
  Do not refresh inputs or stage/reboot before the new receipts pass.
  Resource check at~137min: root97GiB/home31GiB/nix132GiB free,22GiB RAM available;
  bounded kernel query has no OOM, btrfs-error or I/O-error entries.
  current old DMS and Hokum both loaded/active at last check.
- Operator requested more updates at19:24Z. Same build still active/running,
  fresh work through12:24:50PDT, /nix133GiB free. Actual running Nix argv flags
  verified (only allowlisted flags emitted): --max-jobs4, --cores2, --builders''.
  No restart, source drift, extra build or resource-policy change.
- Read-only milestone watcher `/tmp/opencode/nixstation-live/current-progress.py`
  detected the failure. No watcher remains armed. Update its candidate guard
  after the new guided snapshot is recorded, then rearm while that build runs.
- Operator-requested status at19:14:35Z: same persistent validation unit still
  active/running, ~31minutes elapsed, fresh build messages through12:14:34PDT.
  Initial plan2764derivations; current work includes many JS dependency sources,
  Chrome, Herdr and Hokum. /nix134GiB free, /home31GiB, root97GiB. Bounded journal
  query reports no error/failing-exit entries. Existing validation.json is STILL
  old9f75179/gen375; do not mistake it for success of current5a3ffa54 build.
- At failure owning source abc0d1bd497b72aeb6d883d1142132152a142f6c, only refreshed
  flake.lock dirty; no other user changes. Exact guided private candidate:
  **5a3ffa54798ed087dde4ee6ef579aa608a54ba00**, tree96323f10da0d68a57298cfb6b81a119c1ed9214d.
- All4 hosts now pass assertions AND toplevel derivation evaluation against
  refreshed nixpkgs31ecbaca/Hyprland69ff6a, Dux2.0, Desktop0.22.5, SyncShell0.2.1.
  Actual owner preflight JSON: ~/.local/state/nixstation-update/current-20261029/
  fleet-preflight-abc0d1bd497b.json. Tmpfiles parser and migration tests pass.
- Full owner-local validation uses persistent transient user unit
  **nixstation-current-validation-20261029.service**, MainPID49689 at checkpoint;
  its journal retains Nix output independently of SSH. Original terminal monitor
  sh_188f8b0b6001bXSGKWt4wlWUJE returned failure. Existing wrapper uses4jobs/2cores,
  builders empty. Reuse SAME unit for diagnosed source repair, no duplicate work.
  Memory~2GiB; pre-build free root97GiB/home31GiB/nix150GiB.
- Do NOT advance owning source, refresh inputs, promote receipts, or boot-stage
  while this candidate builds. This local handoff edit is intentionally not yet
  synced to the owning source, so it cannot invalidate the exact running build.
- On success: inspect exact validation/result receipts; check actual Dux unit/QML,
  migration+activation regressions, Desktop package/provenance/closure and new
  Hyprland `--verify-config` (documented exact69ff6a source; does not run compositor).
  Then guided diff/commit/push on station, fast-forward integration to its exact
  validated candidate, publish that candidate on main without force, stage via
  owning wrapper, inspect exact receipt, and perform the approved reboot.
- Reboot authority persists: Chris selected **Reboot after validation**, conditioned
  on passed refreshed build and reconciled source on main; app closure warned.
  No live switch/test. Verify new boot ID/current+booted/profile, real loaded Dux
  notify/no BusName and Hokum dbus units (not merely --failed), bars on4 monitors,
  correct wallpaper, launcher, and migrated settings. Do not touch keyring auth.
- Existing unrelated libvirtd failure: missing Downloads/image autostart pool,
  observed before this build. No pool/data/config changes or reset performed.
  Old stashes and original dirty Nomad checkout are preserved, not removed.
- Read-only lsblk confirms the Ventoy USB is no longer attached; installed host
  is booted in BIOS mode from NVMe. No firmware change or extra boot-media gate
  is needed for the already-approved post-validation reboot.
- Full build success, new main publication, staging and current-build reboot
  remain UNVERIFIED. Existing recovered old desktop is still running normally.
- Safe checks against immutable5a3ffa54 completed: all4 activation regressions
  pass, all4 profile-migration tests pass, and Desktop0.22.5 recipe/provenance
  override checks pass (derivation bl716vrrdjb9b5pbqlm5si3an5qp17k7).
  Concurrent evaluation emitted an ignored eval-cache SQLite-busy warning; tests
  succeeded, no cache/database changes needed. dbus-run-session and qs exist on
  owner; sway is NOT on PATH. After full build, obtain only the pinned cached
  sway verification dependency if needed; do not overlap another compiler build.
- Completed READ-ONLY artifact probe against immutable5a3ffa54, using actual
  nix-store --check-validity, not mere directory existence. Realized outputs:
  Dux `/nix/store/fd6gvjsdbvcjd3zsls83hq20j8jd7f38-dux-shell-2.0.0`,
  Hyprland `/nix/store/ndbx6dmxyb8dlck2pdy7k5lbi7g3h22d-hyprland-0.57.0+date=2026-10-29_69ff6a4`,
  Quickshell `/nix/store/5zjsqdacgkfk1vif63cil60y023b3vnp-quickshell-0.3.2`.
  Actual shipped Dux unit verified Type=notify/NotifyAccess=main and NO BusName.
  Desktop `/nix/store/60vcl5mccjz6h7l6yslpqxcqznxzrhyl-hermes-desktop-0.22.5`
  is NOT yet realized. Hokum ExecStart root5xq29zimc46ng4b06mz04syprnc26a0j.
- Candidate Hyprland0.57 --verify-config PASSED on exact already-built immutable
  config `/nix/store/szpdzy3nq85xqdxgzfngy2lwqamq3r7r-hyprvibe-hyprland-config/hyprland.lua`.
  Exact69ff6a CCompositor source confirms verification returns before Wayland
  server/backend initialization, no startup/shutdown callbacks. Test uses isolated
  HOME/runtime. Parser prints config ok/exit0; Socket2/log-path warning occurs in
  no-compositor verification mode, NOT a real running desktop failure.
- Pinned Sway test output yl8mwqqr3xj01i6daa82r0kwlasvk2hk is not realized, but
  exact cache.nixos.org narinfo returns200 (MCP current-catalog sway path differs;
  use PINNED path only). To advance independent checks safely, verification helper
  uses cache-only nix-store --realise with max-jobs0/builders empty, all standard
  signature/hash checks intact; no second compiler build. Full headless private
  D-Bus/Sway/Hokum/Dux check fetched only3cachedpaths/5.2MiB (zero compilation).
  It passed actual Dux unit/embedded disabled component, bus ownership, notify,
  replacement and DND operations, then FAILED at Hokum dismiss: overlay didn't
  answer. Retained output shows private D-Bus activated portals with wrong/no
  display, not the isolated Sway env. This is NOT a main build failure and not
  yet proven a renderer/package bug. No actual desktop service changes.
- Corrected LOCAL integration test harness to set XDG_CURRENT_DESKTOP=sway and
  update activation environment on the PRIVATE bus only (NO --systemd). Do NOT
  sync/commit this or advance the frozen owning source during main validation.
  A first stdin-run attempt failed before testing because __file__ was <stdin>
  and relative config assets resolved under/home; corrected via explicit owner
  script filename in `/tmp/opencode/nixstation-live/run-current-shell-check.py`.
  Focused rerun with proper __file__ fixed the display hypothesis: ALL functional
  checks passed, including dismissal/restart, but teardown failed because private
  portal activation mounted runtime/gvfs (EBUSY on TemporaryDirectory cleanup).
  Corrected local harness to normally unmount ONLY its own runtime/gvfs and doc
  FUSE mounts after its children terminate; no force/lazy/global unmount or pkill.
  PASS output now emitted only after context cleanup succeeds.
- FINAL candidate headless check (shell sh_18962bb4c001e45V8WTFyKp0v6) EXIT0:
  private Wayland/D-Bus ownership, notifications, replacement, dismissal, DND and
  restart persistence all pass; actual Dux unit and exact disabled QML server
  component pass. Portal PipeWire/broken-display messages are private test
  teardown/no-audio-environment warnings, not actual user-session failures.
  Verified no mounts remained and removed ONLY known own failed-test directory
  `/tmp/opencode/hokum-test-rqrtjsxi`. Successful test cleans its own sandbox.
  Harness fixes are now included with the required Hypruse source repair, since
  full validation must run again anyway. Earlier guards against moving owning
  source applied while5a3ffa54 was running; it is now terminal. User informed.

### Scope and completed preparation history
- Chris reports basic Hyprland/keybinds work, but no bar/launcher/correct wallpaper.
  Requests a fully current Nixstation build and integration of pending Git work
  into main. Authorized diagnosis, source reconciliation/publication, input
  refresh/build/validation and safe boot staging. Subsequently Chris selected
  **Reboot after validation**, explicitly approving reboot after the refreshed
  build passes and reconciled source is on main, with app closure warned.
  No full live switch/test approved. Preserve user data, other worktrees and credentials; no agent
  delegation requested. Previous successful boot did NOT verify full desktop.
- Integration worktree: `/home/chrisf/build/worktrees/hyprvibe-nixstation-current-20261029`,
  branch `integration/nixstation-current-20261029`, based on current origin/main
  8c7691e. Merge b79503a of fix branch80e4ee3 brings station rollout history
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
- Completed pending source/history integration: station recovery/rollout,
  both Hermes staging-note branches, and the local station Uplink branch.
  Remaining Nixvader rollout has ZERO patch-non-equivalent commits against the
  integrated tree; preserve it rather than reintroduce old source snapshots.
  A trial merge of that duplicate branch was cleanly aborted in this isolated
  worktree; no user work was discarded. All other local/remote feature branches
  are now ancestors. Legacy beads-sync is retained as tracker history, not merged
  into the source tree; do not independently migrate its shared database.
- Source integration7c1562a published and clean owning station checkout safely
  fast-forwarded to it without changing owning branch name. Guided input refresh
  is running via `nixstation-update update` (shell sh_188d6c840001TXs55JiX7pncVz);
  no full build yet. All4 host final pre-refresh assertions/toplevel evaluations
  passed including packaged-unit source edit. Visible login-keyring prompt is
  user-only: do not interact with or bypass it. Launcher visual check deferred
  while that authentication prompt is active.
- Official GitHub latest non-prerelease Hermes stable is v0.22.5 (published
  2026-10-23). Current-build request includes updating Desktop release pin and
  provenance version together; Nomad/Showfactory backends remain unchanged.
- Nixstation has three historical stashes (2026-03-13,2025-10-26,2025-09-10),
  inspected without popping/dropping. They contain old lockfiles, Sunshine/game
  disablement/Boost workarounds and older app-removal/communication preferences.
  Modern main already incorporates applicable package renames/buffer sizing;
  preserve newer explicit Sunshine/gaming and monitor-aware communication layout.
  Stashes remain intact as history, not blindly applied as current requirements.
- Initial refresh SSH monitor hit its240s tool timeout, but remote python15769
  and nix15846 continue and retain wrapper.lock. Do NOT launch a duplicate update
  or alter owning source while it runs. Await the same operation's lock release,
  then inspect lock/source receipt before any retry. No build issued yet.
- That refresh ended without writing a lock/snapshot (old9f receipt unchanged).
  Informed retry moved monitoring into persistent transient user unit
  nixstation-current-inputs-20261029.service, source d83b9cf with Desktop0.22.5.
  Retained journal establishes actual blocker: syncshell-dms/v0.2.0 tag no longer
  exists (GitHub422). Official tags/latest release confirm v0.2.1/622dbb45 is the
  supported privacy-hardened release. Upgrade that explicit input, then restart
  the SAME prep unit; do not create duplicate work or rerun a full build.
- Read-only later health check finds libvirtd failed at17:53:58Z (four seconds
  after last earlier healthy snapshot), after startup reports missing autostart
  storage pool directory `/home/chrisf/Downloads/image`. Do not disable pools,
  fabricate VM data, remove files, or hide its failure. Track separately from DMS;
  no libvirt restart or configuration change performed.
- Also observed boot tmpfiles errors resolving user0750: shared Syncthing rules
  failed to escape spaces in `/scary/Dropbox/Chris Fisher`. Correct shared path
  rendering using same \\x20 representation already used by station Uplink rule.
  This changes parsing, not Syncthing folder IDs/modes/sync directions.
- Final input preparation succeeded at18:16:39Z after that source correction,
  using the SAME persistent prep unit (Result=success/ExecMainStatus0). Current
  station source aa0ad78 has ONLY flake.lock dirty. Private prepared snapshot
  5dad1a07653a47db494f7535d890cf16fa6bc557, treecd3b790b53e16d50b298a079b945890a3576c30a.
  No full build has used it yet. Refreshed nixpkgs31ecbaca (Oct27), Hyprland69ff6a
  (Oct29), Desktop0.22.5/bf0203a, SyncShell0.2.1/622dbb45, and mutable inputs.
- Concurrent main827eb4e adopted the identical DMS source fix/checks during
  preparation. Merged that published lineage into integration; only its Nixvader
  handoff note was newly added. Before full validation, fast-forward the owning
  checkout to final integration WITHOUT overwriting its refreshed dirty lock;
  guided validation snapshots that final source+lock, not the obsolete5dad prep.
- Pre-current baseline JSON is `/tmp/opencode/nixstation-live/pre-current-baseline.json`
  on Nomad. Source-revision-specific preflight assertions are running against
  prepared5dad (same code); inspect any exact evaluation error before full build.
- Fresh nixpkgs preflight returns four failed removed-option assertions: upstream
  DMS is now Dux Shell2.0.0/programs.dux-shell; VPN/dynamic-theming/audio-wavelength/
  calendar feature toggles were removed (dependencies built in/runtime detected,
  calendar backend remains separately installed). This is a real compatibility
  boundary, not permission to drop desktop features or pin an old whole system.
- Adapted canonical package/module, removed only those obsolete toggles, kept
  `dms` CLI/unit and stable local hyprvibe.dms interface. Upstream2.0 unit already
  Type=notify/NotifyAccess=main with NO BusName: remove legacy unit patch/Type
  override and retain native readiness. Keep QML server disablement for Hokum;
  its exact patch applies to2.0 with zero fuzz (offset46 only), tested upstream
  source. Updated built-unit test for notify readiness and extracted QML discovery.
- Dux2 uses .config/dms and .local/state/dms. Added copy-only, staged-rename
  legacy migration before profile seed; do not overwrite existing new dirs or
  remove old profile data. Four disposable-home tests pass, including ENOSPC
  failure cleanup, private modes and rerun preservation. Bash/Nix syntax and
  diff checks pass. Current recovered desktop still runs old DMS untouched.
- Compatibility source06a842b is published and owning source fast-forwarded,
  retaining refreshed lock. Station failed-assertion evaluation now returns[].
  Full fleet toplevel preflight found shared tmate-unstable-2022-08-07 newly
  blocked as insecure/CVE-2018-19387. Chris explicitly chose **Remove tmate**
  from shared base packages; SSH/tmux unaffected. No insecure-package exception.
- First preflight SSH command had a quoting syntax error before execution;
  corrected using a reviewed local bash script over stdin, not nested quoting.
  Actual preflight then ran and produced the package blocker above.
- All10 generated Dropbox/Uplink tmpfiles rules now pass field checks AND real
  systemd-tmpfiles --create --dry-run in an isolated synthetic root; target dirs
  were not created. No real Syncthing folders modified by this verification.
- After approved tmate removal, fleet preflight reaches RVBee's single obsolete
  boot.initrd.verbose assertion (scripted stage1 removed upstream). Remove that
  no-effect setting in source only; no RVBee access/deployment. Other console
  verbosity remains unchanged. Final all-host preflight gates the owner-local
  full build; do not rerun mutable input selection.

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
