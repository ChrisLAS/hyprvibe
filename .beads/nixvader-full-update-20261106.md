# Nixvader full update — 2026-11-06

## Operator scope

Chris approved preserving local work, advancing to published main, refreshing
inputs, inspecting the build plan, using Colony for compilation when viable,
publishing validated source, and staging for boot. Cached packages should
download directly on Nixvader where possible. No switch/reboot, credential or
trust changes, Fakenas rerouting, or broad builder reconfiguration is included.

Chris subsequently approved the narrow reviewed systemd262 local-generation
exception, retaining Colony for heavy compilation. No full-host live switch or
reboot was added to that authority.

## Current hybrid candidate and execution (supersedes initial blocker below)

- Reviewed helper source `4119d02177f687a39c0b0d3a852db5289b07bc17` is published
  on Nomad main; subsequent `5cbf4f43` changes documentation only. The exact
  build retains the reviewed 4119 helper pin, not a moving input refresh.
- Candidate `5dfc256982a4a16f781240cdcac45aba3c188855`, tree
  `0430a48562f2649a99c5bc9bdd233b11d6d92353`, supersedes 9507 only to carry
  that helper pin. Strict no-build evaluation and zero failed assertions pass.
- Toplevel derivation
  `/nix/store/qad78cjc71p35j12188m8s1nfwlaizrk-nixos-system-nixvader-26.11.20261103.1d06008.drv`;
  job `7501f9ae92f02682552e563790af29cdde6e23f6b02c0e9aca9e168f0079882d`.
- Exact version262 recipe support preserves hook source/builder/architecture,
  static-output, source identity, fanout and future-version rejection guards.
  275 relevant regressions pass (3 skips); both small immutable helper packages
  build. Actual candidate selection passes, selecting52 recipes/consumers.
- The full selector additionally visits a generated hwdb beneath a substituted
  parent. There are THREE small generation recipes (udev, initrd rules, hwdb),
  not systemd compilation. The hardware-database dry-run has six lightweight
  generators sharing five existing rule prerequisites; no package compilation.
- All124 prebuilt outputs from the remaining49 consumer derivations were
  fetched directly on Nixvader from the signature-checked public cache and
  retained under `~/.local/state/nixvader-update-20261106/owner-cache-root*`.
- Scoped runtime helper rollout uses fleet
  `/nix/store/k5ciba7qdiymx0mm5qlp9h08i306niiv-colony-fleet` on both hosts and
  coordinator `/nix/store/1ww98qrx8qif6019n14vj1hjir4arda8-colony-coordinator`
  for ONLY the exact job. Nixvader worker drop-in
  `/run/systemd/system/colony-kernel@.service.d/90-nixvader-systemd262.conf`;
  Nomad exact `colony-coordinator@JOB.service.d/90-nixvader-systemd262.conf`.
  Existing owner2CPU/2GiB/480s/256tasks and coordinator12h2min/no-restart/
  no-new-privileges/control-group limits read back unchanged. Daemon-reload
  only, no active worker/service/host restart. Helpers have retained GC roots.
- Background orchestration is cache-only direct acquisition of the124 opaque
  outputs on Colony (never derivations), then the standard guided build gates.
  This avoids uploading the laptop's prebuilt packages back over its remote
  link. The coordinator still supervises the three bounded owner generators,
  their prerequisites, receipts and verified return copies before the main
  Colony compilation. No completed system build/transfer/stage is claimed yet.
- Preserve the exact source/pins/receipts. After success, cache-first final copy
  and ordinary guided validation, commit/push and explicit boot-stage still
  remain required. Remove ONLY these owned runtime drop-ins after terminal
  job and idle owner workers; do not blanket-revert units or replay requests.

## Preserved source and prepared candidate

- Owning checkout `/home/chrisf/build/config`, target `.#nixvader`.
- Initial main was clean at `827eb4e167d2278bf4319b8a3494029332c8e422`, with
  no stashes. Existing secondary branches/worktrees were left untouched.
- Backup branch `backup/nixvader-before-full-update-20261106` retains that revision.
- Fetched and advanced main fast-forward-only to published
  `94d63f79e4bb83e976457948ffb5bad62672ca7e`.
- All floating flake inputs refreshed on Nixvader. Explicit tags/revisions retained.
  nixpkgs is `1d060086d60cb76a40cf37109f979d88a5bd6396` (2026-11-03),
  Hyprland `ab6141897d57e609e24c571a762c30c963e0885a`, and colony-client
  `8bf67b5a306f707499617d9cb7e6c30fcf1edf7b`.
- Existing Git credentials work. A stale credential-helper store path initially
  caused the Git input to reuse cache. A per-command helper override using the
  installed gh corrected it; no credential or persistent Git setting changed.
- Guided managed-lock snapshot is
  `9507b515c6efd16416bc6db0c9028ab57aea91c0`, tree
  `4609f63593e7ebec46fddccda6673bb822eb765b`. Its pending-update branch is
  preserved separately; this is NOT a validated or promoted system update.

## Verified pre-build plan

- Exact candidate evaluation succeeds. A single nixpkgs source-copy/patch IFD
  prerequisite was built with one job/two cores/180-second timeout after its
  dry-run proved no missing dependencies. No system packages were compiled.
- Target derivation:
  `/nix/store/ky9ajhz6rgbg3jf9sxv7bs3p018hggls-nixos-system-nixvader-26.11.20261103.1d06008.drv`.
- Exact candidate NixOS assertion evaluation passed with zero failed assertions.
- Laptop-store dry-run reports 1,804 missing derivations and 3,386 cache paths:
  11.0 GiB download / 30.0 GiB unpacked. These include generated files and
  source archives, not 1,804 expensive compilations or Colony cache misses.
- Missing derivations include Hyprland, GWS, Hermes Desktop and Node builds.
  No missing i686 derivations appear in this laptop-store dry-run, although
  the full current dependency graph includes i686 dependencies.
- Fresh Colony/Nixvader/Nomad admission was idle and healthy before preparation.
  No Colony job has been created or released for this candidate.

## Initial blocker before dispatch (resolved by reviewed helper above)

The candidate uses systemd 262. The installed owner policy and published
colony-client source bind udev checks to the reviewed systemd 261.2 recipe.
Running the pure installed `colony_kernel.select` against the exact graph fails:

`ValueError: udev-check-hook systemd version requires review`

No policy was loosened, check skipped, older nixpkgs substituted, local
compilation fallback selected, or failed coordinator job replayed. The failure
is pre-dispatch policy incompatibility, not a demonstrated systemd262 compiler
or Colony runtime failure.

Fakenas is operational with modern kernel/Nix sandboxing and has a successful
Nov3 Nomad build. Its installed manual service hardcodes Nomad, advertises only
x86_64, and is not a Nixvader guided route. The retained systemd262 diagnostic
design does not claim production/coordinator qualification. Switching to it needs
explicit route/qualification scope; do not copy credentials or broaden trust.

## Network and continuation

The installed guided transfer omits destination substitution. Scratch
`/tmp/opencode/nixvader-update-20261106/build-cache-first.py` on Nomad is prepared
but NOT run: use ordinary guided build gates, hold before automatic transfer,
then standard `nix copy --substitute-on-destination` to Nixvader with existing
pinned SSH. Normal full manifest verification and guided validation must still
pass afterward. A successful copy alone cannot authorize promotion/staging.

Target logs/plans are retained in
`~/.local/state/nixvader-update-20261106/`; source receipt remains in the normal
`~/.local/state/nixvader-update/colony/source.json`. The main working tree's only
source change is the managed lockfile; it is intentionally not promoted until
the builder decision and exact validation succeed. Do not discard it.

Next: follow the exact hybrid candidate's existing guided build, not a new
input update or a new builder. Boot staging remains authorized after
verified build, full transfer, source publication and matching validation.
No live activation/reboot has occurred.
Current system, booted system and staged profile remain the original
`/nix/store/2s508dfb5h3darzc3zvm9mbl483n2rl3-nixos-system-nixvader-26.11.20260917.e554fab`.
