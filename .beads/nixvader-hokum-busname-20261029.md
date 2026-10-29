# Nixvader Hokum service ownership fix — 2026-10-29

## Objective and authority
- Chris approved building, verifying and boot-staging the DMS/Hokum conflict fix
  on Nixvader. Keep Hokum. No live switch/test, desktop/service restart or reboot.
- Preserve other host work, package pins, the iPhone webcam changes, credentials,
  existing generations and running applications. Nixbook needs no change.
- Isolated branch/worktree: `fix/nixvader-hokum-busname-20261029` at
  `/home/chrisf/build/worktrees/hyprvibe-nixvader-hokum-busname-20261029`, based on
  published main `8c7691e`. Do not edit the concurrently active Nixstation tree.
- Existing Beads remote schema migration is blocked (v32 -> v66); follow the
  existing supplemental `.beads/*.md` handoff convention, no database migration.

## Verified baseline
- Nixvader owning checkout `/home/chrisf/build/config`, clean main `8c7691e`.
- Running/booted output `b5bd9aq53knjzzlkcdr9i2skwy66l622`; boot ID
  `5b6c1cb6-41a6-46e7-8c70-c26833e4f34c`. DMS PID1675, start time
  2026-10-22 08:51:50 PDT, loaded/active; Hokum not loaded in current generation.
- Default boot entry is generation83, output
  `/nix/store/fclj3ha2i04qbjfrsmlw8aq948z1z99l-nixos-system-nixvader-26.11.20260917.e554fab`.
  Both its DMS base unit and Hokum unit declare Notifications. DMS override does
  not remove the inherited name. Exact Nixstation conflict is present for next boot.
- Last validation receipt refers to revision `1a2eaca`, output fclj3ha.
- AC online, 282GiB root and 910MiB ESP free; no build/update process or jobs.
- Nixbook already booted bvp3am6, at SDDM greeter; no DMS unit, old daemons masked,
  only Hokum declares Notifications. Physical logged-in notification acceptance
  remains unverified; no Nixbook changes authorized or needed for this conflict.

## Implementation and execution plan
- Reuse the reviewed shared DMS fix from Nixstation integration without unrelated
  branch/history or input refresh: patch the packaged unit to Type=simple and
  remove its BusName. Retain the embedded-QML server disablement.
- Extend fleet checks and private-bus integration test to check the built unit.
- Explicit upfront route: `nixvader-update validate --local`, then matching
  `boot --local`, following the recent successful owner-local receipts and known
  unresolved Colony transfer parity. This is not a failure-triggered fallback.
- Validate committed/published exact source, inspect actual built unit/drop-ins
  and sole notification ownership, then boot-stage through guided wrapper.
- Verify matching staging receipt, default boot assets, unchanged boot ID,
  active/booted outputs, DMS PID/start time and source cleanliness.

## Current state / next action
- Baseline inspected; narrow source fix and regression checks prepared.
- Next: commit, evaluate checks, publish main, advance clean owning checkout,
  run guided validation. Do not reboot or restart services.
