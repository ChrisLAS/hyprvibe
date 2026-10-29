# Nixvader Hokum service ownership fix — boot-staged 2026-10-29

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

## Completed verification and delivery
- Exact candidate `827eb4e` is published to main and the fix branch. Only the
  shared DMS service patch, two regression scripts and this ledger changed;
  flake.nix, flake.lock and Nixvader host source are unchanged.
- Four-host fleet assertions/toplevel derivation evaluations PASS. Nixbook
  toplevel remains exactly izkn5is8; Nixvader derivation ghx47533. Integration
  Python parses; actual old packaged DMS unit fails the new check as expected.
- Guided `validate --local` PASSED for exact candidate827eb4e, tree28485e08,
  retained output `/nix/store/2s508dfb5h3darzc3zvm9mbl483n2rl3-nixos-system-nixvader-26.11.20260917.e554fab`.
  Actual packaged and final DMS unit is Type=simple with NO BusName; Hokum is
  Type=dbus and the only top-level user unit claiming Notifications. Actual
  DMS drop-ins have no BusName and all five legacy service masks pass.
  Persistent target log: ~/.local/state/nixvader-update/hokum-busname-validation-20261029.log.
- Pre-change receipts and baseline are preserved on target under
  ~/.local/state/nixvader-update/history/hokum-busname-20261029/.
  PipeWire1771/WirePlumber1772 start times 2026-10-22 08:51:51 PDT are also recorded.
- Failed test-preparation approach: copying unsigned owner-built DMS to Nomad
  correctly failed signature enforcement. No signatures/trust settings changed.
  Instead copy only cache.nixos.org-signed headless Sway test tooling to the owner
  and execute the private-bus test against DMS where it was built.
- Private-bus/headless integration on owner PASSED against the exact built
  DMS9gb3vwy: ownership, delivery/replacement, dismiss, DND/persistence, built
  service type/no BusName, embedded disabled-server component in real Quickshell.
  Log: ~/.local/state/nixvader-update/hokum-busname-integration-isolated-20261029.log.
- First private UI test failed with "overlay didn't answer" while inherited
  desktop portal activation repeatedly tried unavailable GTK/Hyprland backends.
  A software Vulkan override did not fix it (hypothesis disproven). Keeping
  installed activation files off only the private bus with temporary
  XDG_DATA_DIRS/XDG_DATA_HOME resolved the timeout; production settings remain untouched.
- Guided commit succeeded and exact remote origin/main matches827eb4e; source
  already published from Nomad, no redundant target push/credential repair.
- Guided `nixvader-update boot --local` COMPLETED successfully. Generation84 is
  the default boot entry and profile, pointing to the exact validated2s508dfb
  output. Authoritative local_boot_stage: state=boot-staged,
  boot_stage_verified=true, live_activation_performed=false. transfer_verified
  false is expected on this owner-local route, not a failed transfer.
  Fleet d0e3a4b1021be5be8d73fda56d16bd01d323bb30b80fbbfc17b2df2657cb9db9;
  child01e6fd22427c6741f7c5ff658f642517ce2ae5b7ee9ee63639147739f65f630e.
  Target log hokum-busname-boot-stage-20261029.log; baseline/history directory
  also contains status-after.txt and boot-entries-after.json.
- Independent default-entry assertion passes; ESP kernel and initrd byte-match
  the exact validated output using read-only sudo cmp. No bootloader rewrite or
  staging replay was performed for verification.
- Post-stage checks PASS: same boot ID, current/booted b5bd9aq, DMS1675,
  PipeWire1771 and WirePlumber1772 with unchanged exact start timestamps; all
  active. Owning main clean at827eb4e. No full shell, compositor or audio restart,
  live switch/test or reboot occurred. Previous generations remain available.
- Remaining: real-desktop bars/launcher/card/settings/keybinding acceptance after
  a separately approved reboot. Never infer reboot authority from this handoff.
  Source fix already published to main; this evidence-only followup does not
  require restaging or changing the exact validated owning checkout.
