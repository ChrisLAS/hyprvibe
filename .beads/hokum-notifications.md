# Hokum notification migration — active

- Request: durably replace desktop notifications across all Hyprvibe hosts,
  prioritizing Nixvader and Nixstation; remove competing notification servers
  and update shell/keybinding integrations.
- Scope: shared Nix package/module, DMS notification-server disablement, legacy
  startup removal, controls, tests, documentation, publication and safe staging.
  No reboot or Nixstation live switch/test is approved. Preserve unrelated work.
- Source: isolated `feature/hokum-notifications` worktree from `origin/main`
  (`68540b4`); original checkout has unrelated Nixstation edits, left untouched.
- Inspected: all four configured hosts (nixstation, nixvader, nixbook, rvbee).
  Nixstation is reachable and DMS owns org.freedesktop.Notifications. The other
  three are offline in Tailscale; Nixvader SSH times out.
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
- Active: Nixstation's clean rollout/opencode2-nixstation checkout was advanced
  by fast-forward to 9f75179. Its installed `nixstation-update validate` is running
  the default owner-local route (verified in the deployed helper; no Colony
  fallback). Previous active system gyxvsnd and boot-staged w1yd4p are unchanged
  until explicit boot staging after validation. Main has not been merged there.
- Additional checks: fleet assertion script passes, generated systemd unit has
  graphical-session lifecycle, D-Bus readiness, seed dependency and Wayland
  condition; old dunst/mako/swaync generated units are disabled/masked.
- Failed approaches: the stable binary rejected the dev-only update setting
  (removed); initial DMS patch needed writable parent directories (fixed before
  embedding); two long checks exceeded a 120s tool timeout (resumed with no tool
  timeout and completed). No weakened guards or runtime desktop edits.
- Next: await the owning Nixstation validation result, publish that exact owning
  branch through the wrapper, boot-stage the retained output and record receipt.
  Nixvader, Nixbook and RVBee await connectivity; all physical-host notification
  and widget acceptance awaits boot into the new generations.
