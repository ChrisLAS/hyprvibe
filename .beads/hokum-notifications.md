# Hokum migration — Nixstation/Nixbook staged; Nixvader rollout active

- Request: durably replace desktop notifications across all Hyprvibe hosts,
  prioritizing Nixvader and Nixstation; remove competing notification servers
  and update shell/keybinding integrations.
- Scope: shared Nix package/module, DMS notification-server disablement, legacy
  startup removal, controls, tests, documentation, publication and safe staging.
  No reboot or Nixstation live switch/test is approved. Preserve unrelated work.
- Source: isolated `feature/hokum-notifications` worktree from `origin/main`
  (`68540b4`); original checkout has unrelated Nixstation edits, left untouched.
- Inspected: all four configured hosts (nixstation, nixvader, nixbook, rvbee).
  Nixstation is reachable and DMS owns org.freedesktop.Notifications. Nixbook
  returned online and its separately delegated published-source update is now
  boot-staged (see `.beads/nixbook-update-20261028.md`). Nixvader and RVBee were
  offline; leave Nixvader untouched until Chris is ready.
- Upstream: Hokum v0.1.1 provides CLI/D-Bus controls and native Linux binaries.
  No nixpkgs Hokum package found through MCP-NixOS. Pin the stable release and
  upstream SHA256. The stable release has no updater (the current dev README
  documents a newer feature); do not use its unsupported check-for-updates key.
- DMS 1.6.1's NotificationServer is unconditional and has no disable option.
  Package a small fail-closed QML patch; keep DMS's other desktop functions.
- Tracker blocker: `bd status` locally and on Nixstation refuses a remote-backed
  schema migration (v32 → v66). Do not migrate independently or replace existing
  issue databases. This file preserves task context alongside existing .beads
  handoffs until a compatible tracker is available.
- Initial evidence: Hokum builds and reports 0.1.1. All four hosts evaluate the
  new service with zero failed NixOS assertions and Dunst disabled. Full
  Nixstation evaluation exposed the pre-existing removed adb-sync alias; changed
  just that entry to better-adb-sync, independently of the original dirty tree.
- Chris explicitly chose **boot-stage only** on 2026-10-28. No live activation,
  DMS restart, test generation, or reboot. Offline hosts await availability.
- Package checks: stable Hokum config validation and headless card render pass.
  Patched DMS builds successfully. An isolated private D-Bus/headless Sway test
  passes notification ownership, delivery, replacement, dismissal, DND and restart
  persistence. The built DMS embeds the patch; its exact server Component loads
  in real Quickshell without claiming org.freedesktop.Notifications.
- Full toplevel derivation evaluation passes for all four hosts after the two
  narrow Nixstation compatibility fixes; none installs dunst, mako or SwayNC.
- Published: main and feature/hokum-notifications at bf92417 (compatibility
  prerequisite 85617fb). Nixstation-only migration cherry-pick 9f75179 is published
  on rollout/hokum-nixstation, preserving all owning-branch differences.
- Nixstation validation passed on the default owner-local guided route (no
  Colony fallback). Clean owning rollout/opencode2-nixstation at exact
  `9f751797ba3b78aa3027bb296db09d13fc7bf64b`, tree
  `e6caf3afe21d4a3daaca33b82644d88b645cfc62`. Full retained output:
  `/nix/store/ysix5xasr9fv51d31knnbzrr06mcnadn-nixos-system-nixstation-26.11.20260917.e554fab`.
  Matching `~/.local/state/nixstation-update/validation.json` records assertions
  passed. Main has not been merged into the owning branch.
- Nixstation boot staging **verified**: guided diff/commit/push/boot succeeded;
  owning branch is clean and matches origin at 9f75179. Generation **375** points
  to the retained ysix5x output above. The authoritative `local_boot_stage`
  receipt reports state `boot-staged`, `boot_stage_verified: true` and
  `live_activation_performed: false`; fleet
  `f8e3df5f57b3e265207e46180f0f2350a2d91c48d7d4df6ab2721b9e98434919`, child
  `a3449841ca2e09b041152a6ff2e81d529aeb035c0d19c4ff2f2b2a615115ca37`.
  `transfer_verified: false` is expected for this owner-local route, not a
  failed Colony transfer. The enclosing unrelated Colony status `not-started`
  is not the local boot-stage status.
- Live Nixstation is unchanged: `/run/current-system` still gyxvsnd, DMS
  MainPID still **1582505**, quickshell still owns Notifications under dms.service.
  `/run/booted-system` is hj5kkam; the pre-existing booted/active distinction is
  retained, not changed as part of staging. No live switch/test/reboot occurred.
- Nixbook independent background work completed: candidate c44a980, generation
  **102**, output bvp3am6, ESP kernel/initrd byte-verified and live Hyprland/Dunst
  unchanged. Handoff published separately at 2a7dc61. No input refresh attempted.
- Nixvader online/ready per Chris on 2026-10-28. Verified clean owning checkout
  `/home/chrisf/build/config`, main at 68540b4, systemd-boot generation 80; active,
  booted and profile output all b5bd9aq. DMS MainPID **1675**, AC power online,
  285 GiB root / 848 MiB ESP available; no target build jobs observed.
  Last successful wrapper validation used route **local** at 68540b4 (l1c3jik
  retained output). Explicitly select `nixvader-update validate --local` upfront
  for this new migration candidate, matching the proven owner-local route and
  preserving the historical unresolved Colony transfer mismatch. This is not a
  failure-triggered fallback or replay under a new request key. No new input
  refresh, live activation, service restart or reboot is in scope.
- Nixvader pre-existing failure: `nixos-upgrade.service` failed because its
  legacy channel command cannot find `nixos-config`. Next timer is ~02:43 Oct 29,
  eight hours after admission. Preserve the failure evidence; no unrelated
  auto-upgrade repair or failed-unit reset as part of notification migration.
- Nixvader exact selected source is published main 5c81a5d; only notification changes,
  the already-reviewed Nixstation compatibility fixes and handoff docs differ
  from its clean 68540b4 checkout. `flake.lock` is unchanged.
- Nixvader previous JSON validation/source/result receipts plus active/booted/
  profile/DMS-PID baseline preserved under
  `~/.local/state/nixvader-update/history/hokum-before-5c81a5d/`.
  Owning main fast-forwarded cleanly to 5c81a5d. Full owner-local build succeeded,
  retaining `/nix/store/cc6ripr6rnqaf9kzyr0rc18zvsjgzagq-nixos-system-nixvader-26.11.20260917.e554fab`.
  The initial watcher ended after retaining the output but before updating the
  validation receipt; original transient Nomad log was no longer available.
  No target build remained, source was clean/unchanged, result symlinks and JSON
  matched exact 5c81a5d, and the kernel journal showed no OOM in the relevant
  interval. Root cause remains unknown; do not claim a compiler failure.
- Standard `nixvader-update resume --local` safely reused the completed output
  and recorded the matching assertions-passed validation receipt for 5c81a5d.
  Persistent target log: `~/.local/state/nixvader-update/hokum-validation-resume.log`.
  Actual output checks pass Hokum version/config, absent old binaries, all five
  old/fallback units masked, correct Hokum unit, and embedded DMS disablement.
- Nixvader guided diff/commit passed. Redundant wrapper `push` failed before any
  staging because the user Git credential helper references a garbage-collected
  `/nix/store/...-gh-2.97.0/bin/.gh-wrapped`. No credentials or Git config changed.
  Read-only `git ls-remote origin refs/heads/main` proves exact validated 5c81a5d
  is already published (same as local HEAD); source publication gate is met.
  The original aborted sequence is preserved in
  `~/.local/state/nixvader-update/hokum-boot-stage.log`.
- First actual `nixvader-update boot --local` is now running for exact published
  5c81a5d, retaining all normal source/validation/output checks. Target log:
  `~/.local/state/nixvader-update/hokum-boot-stage-published-candidate.log`.
  This is not a staging replay; the previous sequence stopped at push. Do not
  advance published main until exact staging completes. Progress notes remain
  on feature branch; final handoff publishes separately afterward.
- Additional checks: fleet assertion script passes, generated systemd unit has
  graphical-session lifecycle, D-Bus readiness, seed dependency and Wayland
  condition. Actual Nixstation retained output reports Hokum 0.1.1, contains no
  dunst/mako/swaync/swaync-client executables, and all five old/fallback user
  units resolve to /dev/null.
- Failed approaches: the stable binary rejected the dev-only update setting
  (removed); initial DMS patch needed writable parent directories (fixed before
  embedding); two long checks exceeded a 120s tool timeout (resumed with no tool
  timeout and completed). No weakened guards or runtime desktop edits.
- Diagnostic correction: `nixstation-update status` internally invokes SSH and
  consumed following lines of an SSH heredoc. Reran only the read-only live-state
  checks separately; never replayed staging. For future heredocs redirect guided
  commands' stdin from /dev/null when more script lines follow.
- Next: verify Nixvader's exact guided boot-stage receipt and unchanged live
  system/DMS PID, then publish final handoff without changing staged candidate.
  Nixstation/Nixbook await Chris-controlled reboot and physical-host checks from
  docs/NOTIFICATIONS.md. No reboot permission is granted. RVBee awaits
  connectivity. Do not claim staged hosts' real Hokum desktop accepted yet.
