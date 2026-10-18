# Hermes Desktop 0.22.2 preparation

## Scope and approval

Chris approved preparing and validating a Nix-managed upgrade for Nixstation and
Nixvader after the 2026-10-17 audit. Builds/tests and source publication are in
scope; boot staging, live activation, reboots, backend upgrades, credential
changes, and chat submissions are not. Preserve the two owning branches and all
unrelated work. Nomad and Showfactory remain the configured remote backends.

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
  Desktop-only external-update stamp, and committed release icons exclude the
  local agent and pm runtime. Keep the owning package set's Node overlays.
- Both NixOS assertion evaluations returned an empty failure list.
- Recipe checks and Python syntax check passed; built closure/native-module
  checks and full owning-host builds remain required.
- An exploratory package build from main was interrupted deliberately: it used
  the upstream package set instead of the owning Node overlay. Retain its log at
  `/tmp/opencode/hermes-desktop-0222-package-build.log`; do not reuse its output
  as validation of the corrected candidate.

## Active / next executable work

Build the corrected package on Nixstation using the rollout branch's reviewed
Node overlay. Run `scripts/check-hermes-desktop.py` against the realized package;
validate both exact host candidates with their guided build routes, inspect
closures, and publish source branches. No running app/system has been upgraded.
