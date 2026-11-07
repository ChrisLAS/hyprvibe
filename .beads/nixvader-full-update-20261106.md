# Nixvader full update — boot-staged 2026-11-07

## Result and authority

The approved update is complete through **boot staging**, not live activation.
Chris approved preserving local work, advancing main, refreshing floating
inputs, Colony compilation with direct cache downloads on Nixvader, publishing
the validated source, and staging for boot. He additionally approved the narrow
reviewed systemd262 owner-generation exception. No switch/reboot, credential or
trust changes, Fakenas rerouting, broad builder change, or test disabling occurred.

Owning `/home/chrisf/build/config` main is clean and matches published main:
`46f56d4f427310ca5dee0f47636dd6e6d07f42ee`.
This documentation branch is supplementary; it is not the staged revision.
Existing branches/worktrees were preserved. Original source remains on
`backup/nixvader-before-full-update-20261106` at
`827eb4e167d2278bf4319b8a3494029332c8e422`.

## Exact validated identity

- Source revision: `46f56d4f427310ca5dee0f47636dd6e6d07f42ee`
- Source tree: `20a8a15c1b934cbea3cdaad8c2a5755287ade8b3`
- Fleet: `175a644bdafa3ff2d1970fef0a3bbe7f5b4b298c00105fc2aff21053de679022`
- Job: `8397d6664c79226a9a75d066f3d4cb91c272c46c1cd1f6f9cad28ade9aff9fc9`
- Attempt: `44e3d008a98e452da08c750eb2d52d92`
- Child: `5cb02e57a83cb72ea76e636026b3d2ce87f03a1aff34feee07afabefed235f51`
- Derivation: `/nix/store/zvr665pfddsf8knccijh0n4qcvbzm0i0-nixos-system-nixvader-26.11.20261103.1d06008.drv`
- Output: `/nix/store/0nq9jiv200w3mah2igj0q1zldn4ssqkm-nixos-system-nixvader-26.11.20261103.1d06008`
- Closure hash: `4232281ac0200d0c3d2341ad33e04d9ff58ecc6ac120bc52190563faa5fb5c94`
- nixpkgs: `1d060086d60cb76a40cf37109f979d88a5bd6396`
- Hyprland: `ab6141897d57e609e24c571a762c30c963e0885a`
- Reviewed colony-client pin: `4119d02177f687a39c0b0d3a852db5289b07bc17`

## Verified delivery

The complete Colony build succeeded. Cache-first destination copy completed,
then the ordinary owning `nixvader-update validate --colony` verified the full
manifest and recorded the matching validation receipt. Closure diff was reviewed;
`commit` promoted the exact candidate, `push` published it, and `boot --colony`
returned `boot-staged`. Root control reports build, transfer and boot-stage
verification true with no attention required. No acceptance receipt was forged
or failed job/budget reset.

The root staging receipt records dry activation accepted, durable source,
boot assets accepted, and **live_activation_performed=false**. Independent
checks confirmed both EFI kernel and initrd bytes match the staged output.
The system profile points to that output. Boot entry is:

`nixos-7ccd9b990355bcd54cd6dc8f35c57ad5c21cbf85d261a276c548248e39f2ec1a.conf`

It is **generation85**, NixOS26.11.20261103.1d06008, Linux7.2.15-zen1.
Both `/run/current-system` and `/run/booted-system` still point to the original:

`/nix/store/2s508dfb5h3darzc3zvm9mbl483n2rl3-nixos-system-nixvader-26.11.20260917.e554fab`

The two task-owned runtime helper overrides were removed after terminal
coordinator success and idle owner workers; daemon-reload only, no restarts.
Retained store roots and evidence remain for diagnosis, not broad cleanup.

## Diagnosed build corrections

- Systemd262 recipe support was reviewed against exact hook/source/builder/
  architecture/output fingerprints. Existing guards, transfer verification and
  owner2CPU/2GiB/480s/256tasks limits were retained. There were only three small
  owner generators: udev rules, initrd rules and hwdb. Heavy builds stayed on
  Colony. The other49 selected consumer derivations'124 cached outputs were
  fetched directly on Nixvader and independently cache-warmed on Colony.
- DuxShell2.0.0's IPC test helper used `t.TempDir`, embedding full test names in
  Unix-socket paths beneath Colony's long build root. Initial environment-only
  fixes failed: Colony `/tmp` is noexec and pinned Go1.27 also uses GOTMPDIR for
  `testing.TempDir`. Those workarounds and their insufficient hook-only fixture
  were removed, not left deployed.
- Final `patches/dux-short-ipc-test-path.patch` changes **only** the test helper
  to a private `os.MkdirTemp("", "dms-")` with checked cleanup. All original
  upstream test functions remain byte-identical; full Go checks stay enabled.
  The real pinned-Go reproducer fails before the patch and passes both socket
  fixtures afterward. The actual Dux package and entire system then built.
  Four disposable-home Dux migration regressions also passed.
- Reviewed helper implementation passed275 relevant tests (3 skips). No mount,
  security, signature-trust, worker-limit or generic local-fallback weakening.

## Evidence and next action

On Nixvader:

- `~/.local/state/nixvader-update/validation.json`
- `~/.local/state/nixvader-update/colony/source.json`
- `/var/lib/colony-jobs/staging/5cb02e57a83cb72ea76e636026b3d2ce87f03a1aff34feee07afabefed235f51.json`
- `/var/lib/colony-jobs/stage-requests/5cb02e57a83cb72ea76e636026b3d2ce87f03a1aff34feee07afabefed235f51.json`
- `~/.local/state/nixvader-update-20261106/`

Nomad diagnostics remain in `/tmp/opencode/nixvader-update-20261106/`.
Canonical live/root receipts supersede stale watcher/result files.

**Only after Chris chooses to reboot**, run `nixvader-update health` and verify
the booted output, desktop, Dux profile migration and notifications. No visual
or post-reboot acceptance is claimed. The successful build retained an optional
desktop native-X11-helper compiler warning (`X11/Xlib.h` absent); runtime feature
acceptance remains unverified. The pre-existing channel-based `nixos-upgrade`
failure is separate and was not repaired as part of this guided flake update.
