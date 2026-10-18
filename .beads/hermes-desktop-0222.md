# Hermes Desktop 0.22.2 preparation

## Scope and approval

Chris approved preparing and validating a Nix-managed upgrade for Nixstation and
Nixvader after the 2026-10-17 audit. Builds/tests and source publication are in
scope; boot staging, live activation, reboots, backend upgrades, credential
changes, and chat submissions are not. Preserve the two owning branches and all
unrelated work. Nomad and Showfactory remain the configured remote backends.

Subsequent explicit approval: Chris answered **Yes** to staging both validated
upgrades for the next reboot, starting with Nixstation. Boot staging of the
exact published/validated local outputs is now authorized; live switching,
reboots, backend changes, and credential changes remain out of scope. Stage and
verify Nixstation first, then Nixvader, using each matching local-route receipt.

After inspection of the exact five-path Colony transfer mismatch, Chris
explicitly selected **Local validation (Recommended)** for Nixvader. This grants
an owner-local build/validation of the final source only, not collision
acceptance, reconciliation of the old receipt, staging, activation, or reboot.

This is a supplemental note in the existing Beads directory, not a replacement
tracker. Installed `bd` cannot read/write this shared schema (v32 vs v66;
`leases` table missing). `bd list` and `bd dolt pull` refuse; no migration,
bootstrap replacement, or issue-history overwrite is authorized or attempted.

## Verified baseline

- Both live clients are 0.17.6 and show Gateway ready with Nomad sessions.
- Both hosts authenticate to both backends: profiles/status HTTP 200 and
  websocket HTTP 101 followed by JSON-RPC data. Nomad has 7 profiles;
  Showfactory has 3. Credentials remain owner-only and were never printed.
- Nixstation's historical log has Nomad ECONNREFUSED; no current failure was
  reproduced. Both backends' `0.0.0` labels are not reliable release provenance.
- Nixstation source: `rollout/opencode2-nixstation` at `4c679a4`.
  Nixvader source: `main` at `9759588`. Do not merge their host differences.

## Candidate decisions and checks

- Stable release v0.22.2 resolves to
  `d923a5eb487a17c0a68801bba9ef0f56c81040a8`; only the Hermes lock node changes.
- Replace the obsolete Electron-header patch and generated-JS/string-context
  edits with supported Desktop arguments. Explicit local backend stub,
  Desktop-only external-update `payload=light` stamp, and filtered committed
  release icons exclude the local agent, pm runtime, and full upstream source.
  Keep the owning package set's Node overlays.
- Both NixOS assertion evaluations returned an empty failure list.
- Recipe checks and Python syntax check passed. The final package shared by
  both host recipes is
  `/nix/store/z03ydsaxb3y6h4kiv445d2q6awpks1cj-hermes-desktop-0.22.2`.
  Nixstation's realized package/provenance/stub/native-module/closure checks
  passed (319 paths); its full host closure/launcher checks passed (3,441 paths).
- An exploratory package build from main was interrupted deliberately: it used
  the upstream package set instead of the owning Node overlay. Retain its log at
  `/tmp/opencode/hermes-desktop-0222-package-build.log`; do not reuse its output
  as validation of the corrected candidate.
- Initial full Nixstation builds passed. Closure inspection then found the
  entire 209 MiB upstream source retained through icon build receipts; the
  filtered-asset follow-up removes it. Final closure diff changes only Desktop
  0.17.6 -> 0.22.2 and its install stamp, about 7.2 MiB added.
- Isolated Xvfb launch, close/relaunch, runtime provenance, and the new app's
  own HTTP+websocket tests passed on **both hosts** for both Nomad and
  Showfactory. Runtime reports
  appVersion/baseVersion 0.22.2, payload light, distribution nix, external update
  ownership. No chats were submitted. The original registry hash was unchanged;
  the temporary app and credential copies were removed.

## Exact source and validation state

- **Nixstation complete for preparation:** candidate
  `da7f564f0bb8f20ada42072404201d487a0d8f12`, validated through the guided
  owner-local route, published on `rollout/opencode2-nixstation`. Retained output:
  `/nix/store/w1yd4pzhp0xkflnm57bwacd40k1zkv4v-nixos-system-nixstation-26.11.20260917.e554fab`.
  Exact receipt: `~/.local/state/nixstation-update/validation.json` on Nixstation.
  No boot staging, live switch or reboot was performed.
- **Nixvader complete for preparation:** after explicit operator route approval,
  candidate `7aca66a4b505fbdf7ac2290a0dfc69b9a4467052` passed
  `nixvader-update validate --local` and was published on owning `main`.
  Retained output:
  `/nix/store/b5bd9aq53knjzzlkcdr9i2skwy66l622-nixos-system-nixvader-26.11.20260917.e554fab`.
  Exact receipt: `~/.local/state/nixvader-update/validation.json` on Nixvader.
  Its package and full 2,720-path host closure/launcher checks passed. The older
  Colony build/transfer receipt below remains unresolved history; it was not
  reconciled, retried, accepted, or silently re-keyed.
- These evidence-note changes are on preparation branches only. They do not
  replace either exact validated/published deployment candidate above.
- Both running clients remain 0.17.6. Nixstation's active system remains `gyxvsnd`;
  Nixvader's remains `7xq8ajs`. Their pre-existing booted/active differences were
  not changed or treated as permission to activate.

## Preserved Nixvader Colony transfer limitation

- Fleet: `5730c24beb1655ed1eab1d7cad1176ef80c95775a51fcbe13bc308b234c82ed6`.
  Job: `16dd90c767c8483d079b8c3039f3019dc6166e8b338368f6638c174ca6f1b463`.
  Attempt: `e040128bbf3043a8b0cc12a0155f0322`.
  Transfer child: `17f7eeacff1259dc440412ab3e8bb5ceaa85673caae597a9d5e6cee5ce922c0b`.
- Output: `/nix/store/l589chr23fn80krnynmh1mj6bhfn2j4v-nixos-system-nixvader-26.11.20260917.e554fab`.
  Worker failed with `destination closure differs before retention`; fleet state
  remains `transfer-outcome-unknown`, build verified, transfer not verified.
- Source and destination have the same 2,720 paths and reference sets. Five
  pre-existing active paths differ in NAR hash/size: gws, hyprtoolkit,
  xdg-desktop-portal-hyprland, aquamarine, hyprutils. All five passed
  `nix store verify --no-trust` on both stores. The transferred Hermes Desktop
  itself has matching NAR hashes. Exact fingerprints are in the companion JSON.
- No reconciliation, collision exception, copy retry, staging, or activation
  was attempted. Prior collision approvals do
  not apply to this fleet. Do not waive verification or change request IDs.
- Chris approved owner-local validation for the final source. Old wrapper JSON
  receipts were archived on Nixvader under
  `~/.local/state/nixvader-update/hermes-0222-colony-blocked-5438e0b/`, then the
  clean owning main checkout was fast-forwarded and local validation succeeded.
  Neither global build routing nor verification policy changed.

## Remaining / next executable action

Preparation and validation are complete for both desktops. Chris approved next-
boot staging only. Next: recheck exact owning source/publication, validation and
local build receipts, record the live/booted/profile baseline, then run and
verify `nixstation-update boot --local` followed by `nixvader-update boot --local`.
Use only the exact validated owning revisions; do not promote these evidence-
note commits into either owning checkout. Do not use a Colony transfer receipt,
silently change routes, replay an uncertain stage, live-switch, or reboot.

Nixvader's GitHub helper points at a garbage-collected gh 2.97 store path. The
guided push succeeded using a command-scoped Git helper override to the already
installed `/run/current-system/sw/bin/gh`, reusing existing scoped credentials.
No credential, login, or persistent Git configuration was changed. Durable repair
of that unrelated user Git helper is follow-up work, not a Hermes prerequisite.
