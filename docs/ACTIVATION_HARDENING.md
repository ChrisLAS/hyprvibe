# Hyprvibe activation audit and boot-staged hardening plan

- **Audit date:** 2026-10-31
- **Source baseline:** `94d63f79e4bb83e976457948ffb5bad62672ca7e` (`main`)
- **Hosts:** Nixstation, Nixvader, Nixbook, RVBee
**Status:** audit and implementation plan; hardening has **not** been implemented or staged.

## Outcome and boundaries

Optional desktop/application provisioning must not prevent the OS from booting
or make SSH, networking, logging, or the user manager depend on application
readiness. A failed setup job should preserve the previous usable files, report
an actionable error, and affect only its explicit consumers.

The implementation is complete only when **all four hosts have validated,
published, retained exact outputs staged for their next boot**. No live switch,
`nixos-rebuild test`, reboot, application restart, credential replacement, or
unrelated cleanup is part of that rollout. Actual post-reboot acceptance remains
a later, separately authorized operation; staging is not proof of a successful boot.

This audit used repository source and pinned Nix evaluation, not live host state.
It did not inspect secret contents or change any host. Evaluation fetched pinned
sources/substitutes and realized the repository's source-only patched-nixpkgs
derivation through import-from-derivation; it did **not** build a host closure.
All four host assertions and toplevel derivation evaluations passed. That is
evaluation evidence, not build, deployment, or fault-injection evidence.

## 1. Evaluated inventory

| Host | Desktop backend | Active custom root snippets | `hyprvibe-setup-*` user jobs | Source bootloader | Existing guided staging |
| --- | --- | --- | --- | --- | --- |
| Nixstation | Dux/DMS | 5 | 6 | BIOS GRUB, `/dev/nvme0n1` | Yes; owner-local |
| Nixvader | Dux/DMS | 3 | 7 | systemd-boot/EFI | Yes; Colony route |
| Nixbook | Waybar + swaybg | 3 | 6 | systemd-boot/EFI | Not enrolled |
| RVBee | Waybar + hyprpaper | 2 | 6 | systemd-boot/EFI | Not enrolled |

There are **six distinct active custom root snippets, used 13 times across the
fleet**. All **25** evaluated `hyprvibe-setup-*` jobs are oneshots without an
explicit `TimeoutStartSec`. All four primary users have linger enabled, so
`default.target` user setup may run at boot, before a graphical session exists.

The evaluated user-activation inventory contains only the generated `script`
aggregate, not additional custom user activation fragments. The root definition
inventory also includes ordinary nixpkgs activation and, on relevant hosts,
sops-nix. Those essential upstream mechanisms are not blanket migration targets.

All audited custom root snippets have `supportsDryActivation=false` by default.
A successful staging dry activation therefore does **not** exercise these home
writes. Fault-injection and disposable-boot tests remain necessary.

### Root-snippet decisions

| Snippet and source | Active hosts | Finding | Planned disposition |
| --- | --- | --- | --- |
| `hyprlandBase`, `modules/shared/hyprland.nix:116` | All four | Home writes, direct config truncation, recursive ownership work; unscoped `set -u` and `ERR` trap modify the shared activation shell. Much of the work is duplicated in the user setup job. | Remove from root activation. Render templates at build time; bounded user publication for remaining writable state/compatibility links. |
| `waybar`, `modules/shared/waybar.nix:36` | All four, including Dux hosts | Strict-mode isolation now contains the known boot failure, but root home writes and duplicate user setup remain. Root path includes extra variants, ownership and helper behavior that must not be lost. | Remove root implementation after consolidating a single, behavior-complete user/store-backed owner. Retain the legacy fallback on Dux hosts. |
| `installPowerProfileScript`, `modules/shared/power.nix:158` | Nixbook, Nixvader | Writes a large, static executable into home during activation. Its embedded `set -euo pipefail` is heredoc payload, not an executed activation setting. | Package the executable in the Nix store/system profile; preserve menu callers and any needed legacy path via a narrowly scoped compatibility link. Preserve power behavior. |
| `nixstationAccountsServiceSession`, `hosts/nixstation/system.nix:1504` | Nixstation | Privileged mutable AccountsService update; some rewriting truncates the live file. Declarative default session is already set, but existing persisted overrides require care. | Prefer existing declarative session settings. If a persisted-state repair is still needed, use a bounded privileged atomic merge preserving unrelated keys, with only AccountsService-scoped coordination—not an essential boot/login prerequisite. |
| `nixstationLauncherEntries`, `hosts/nixstation/system.nix:1533` | Nixstation | Root copies executables/desktop entries into home. | Store-backed packages/desktop entries, with bounded migration of known old generated user overrides; preserve Flatpak launch behavior and desktop-entry precedence. |
| `nixstationDisableMaestralAutostart`, `hosts/nixstation/system.nix:1551` | Nixstation | Deletes a user autostart file on every activation. | Preserve the explicit autostart-disable intent through managed XDG override/migration, touching only the known entry and preserving user-modified files. |

### Defined but inactive: do not confuse source search with execution

- `setUserIcon` in `modules/shared/user.nix:88` is inactive on all four hosts
  because their configured icon is null. Harden its implementation or replace it
  with store-backed AccountsService artwork before it can be enabled; do not
  introduce a new root home-write path later.
- `hosts/rvbee/lore.nix` contains **13 legacy activation definitions**. It is not
  imported by the current RVBee configuration, and none appears in the evaluated
  activation graph. Preserve historical material; do not enable, migrate,
  revive, or delete the legacy stack as part of this hardening task.

## 2. Already-systemd work still needs hardening

### Local desktop/setup jobs

| Jobs | Hosts | Required work |
| --- | --- | --- |
| `hyprvibe-setup-hyprland`, `hyprvibe-setup-waybar` | All | Remove duplicate root ownership; build-time rendering; atomic user publication; explicit bounded start/stop; correct consumer ordering. |
| `hyprvibe-setup-shell` | All | Generate static Fish fragments at build time. Preserve optional secret-file references without reading credentials into derivations/logs. Preserve custom prompt configuration and avoid broad cache cleanup as a setup side effect. |
| `hyprvibe-setup-kitty` | Nixbook, Nixvader, RVBee | Replace direct truncating writes with store-backed managed configuration/atomic publication, with a policy for existing user edits. |
| `hyprvibe-setup-hokum` | All | Keep first-run writable config seeding and sole-notification ownership; add bounds and safe first-publication/concurrency behavior. |
| `hyprvibe-setup-dms` | Nixstation, Nixvader | Retain existing copy-only legacy migration, preservation of existing profiles, and per-profile hash. Add explicit bounds, serialization and a safe multi-file publication/recovery contract; keep Dux notify readiness. |
| `hyprvibe-setup-herdr` | Nixstation, Nixvader | Preserve unmanaged Ghostty content. Do not treat every `awk` failure as an empty input and then replace the existing file; distinguish absent config from read/parse/I/O failure, and atomically publish. |
| `hyprvibe-setup-opencode` | Nixbook, RVBee | Keep the existing JSON validation, but use unique same-directory temporaries, cleanup, bounds and defined overwrite/ownership behavior. Do not re-enable the V1 generator on V2 clients. |

Other custom oneshots need the same classification rather than a blanket timeout
override: RVBee SSH-config/helper installation; GitHub-token environment import;
Nixstation R2 template/config generation; short EPP/modprobe/Bluetooth helpers;
and Nixbook Companion's local pre-start seeding. Preserve existing SSH trust,
credential sources, mounts and production behavior. Do not rotate credentials,
rewrite SSH identity, or restart active media/agent workflows during staging.

**Ordering nuance, checked rather than assumed:** several services have both
`After=default.target` and `WantedBy=default.target`. That pattern alone is not a
proven ordering cycle: a disposable `systemd-analyze --user verify` reproduction
passes, and systemd 262's `unit_add_default_target_dependency()` explicitly
avoids adding a contradictory default edge. Do not “fix” these just by removing
ordering. Instead verify actual consumer dependencies and readiness; post-target
setup can still race an application that has no explicit dependency on it.

### Long/network jobs on the startup transaction

These are separate from the original init failure, but show why merely moving
commands into oneshot services is insufficient:

| Source/job | Evaluated concern | Planned boundary |
| --- | --- | --- |
| `modules/shared/agent-configs.nix:31`, `link-codex-shared-config` | Nixstation, Nixbook, RVBee: root oneshot wanted by `multi-user.target`, polls for synced files for up to five minutes, no explicit service timeout. | User-owned linking, bounded local attempts; re-trigger through a path/timer when files arrive. Absence of Syncthing data must not delay normal boot. Preserve prior config and auth files. |
| `hosts/nixvader/flatpak.nix:17`, `hosts/nixbook/system.nix:482` | Network installs/appstream updates in oneshots wanted by `multi-user.target`; no explicit start timeout. | Defer reconciliation through timers/application maintenance, with bounded attempts and existing retry intent. Already-installed apps and login must work offline. |
| `hosts/nixstation/ai-memory-stack.nix:67` | `ollama-models-prepull` has a **48-hour** timeout and is wanted by `multi-user.target`. | Move download/readiness work off the boot completion transaction. Keep model selection and app readiness requirements. |
| `hosts/rvbee/ai-memory-stack.nix:86,150,193` | Core/optional pulls each have **24-hour** timeouts; Cognee also directly requires core readiness and is itself wanted by `multi-user.target`. | Defer the **whole dependent application subtree**, not only the downloader. Preserve core-before-Cognee semantics; optional models must not gate unrelated apps/boot. |
| `hosts/rvbee/system.nix:1163–1256` | CamoFox clones/fetches/builds at runtime; unbounded builder/init oneshots and dependent container are in the boot path. Builder synchronously restarts its own dependent container—a re-entrant waiting risk. | Separate deferred image maintenance, explicit image readiness and consumer start. Remove synchronous producer→dependent restart coupling; preserve app functionality, volumes and existing checkout data. |
| `hosts/nixstation/qwen38-server.nix:158` and generated OCI units | Tailnet setup can wait on an app; relevant OCI consumers have `TimeoutStartSec=0` and boot target membership. | Inspect the transitive graph, retain application-only readiness, and ensure slow network/container/model preparation does not gate essential services or boot completion. |

Long transfers on slow links are not inherently errors. Their budgets should
follow the owning workflow, outside boot-critical dependencies—not be replaced
with an arbitrary 30-second download cutoff. No unrelated model, package, backend, kernel,
firewall, or container-feature upgrade is part of this refactor.

## 3. Target design

Priorities are **P0** removal of optional root activation/shell-state leakage;
**P1** bounded, failure-safe local setup and deferred network/application subtrees;
**P1 delivery prerequisite** reviewed Nixbook/RVBee staging support; and **P2**
standardized diagnostics and prevention of future regressions. No priority level
permits dropping an existing feature or bypassing a host's staging checks.

1. **Build-time assets first.** Use store-backed scripts, complete Hyprland
   composition, rendered wallpaper/lock templates and packaged desktop entries.
   Hyprland already starts from immutable `HYPRLAND_CONFIG`; preserve that route
   so a failed home-link convenience job cannot prevent compositor startup.
2. **Small shared setup primitive.** Add a Hyprvibe-owned module/helper for the
   remaining mutable local setup. Adapt the pattern in Nomad's
   `hosts/nomad/application-setup.nix`, not its host identity, paths or secrets.
   Run home work as its user, with explicit PATH, per-job start/stop deadlines,
   journal diagnostics and per-job serialization.
3. **Failure-safe publication.** Validate input and fully prepare a same-filesystem
   temporary before atomic rename. Preserve unmanaged files, existing modes and
   ownership; clean only owned temporaries. Handle broken links, read-only home,
   ENOSPC, partial previous runs and concurrent starts. A collection of per-file
   renames is not an atomic multi-file transaction: use a validated versioned
   managed tree/pointer where feasible, or documented recoverable migration.
4. **Honest readiness.** Bind success to the setup program/content version, not
   a permanent `RemainAfterExit` flag. Mark ready only after all required work;
   reject stale success after source changes or interrupted work. Do not restart
   active workflows just to refresh setup. Let only consumers of that particular
   job wait/fail closed; prefer existing working files where that is safe.
5. **No broad target gate.** Do not aggregate all local jobs into one requirement
   of SSH, login, logging, networking, the user manager or the compositor. Use
   scoped dependencies, and deferred timers/path triggers for network work.
   Moving a job to a timer is insufficient if an auto-started consumer still
   pulls the long job into the original startup transaction.
6. **Retain narrow activation only when essential.** The expected outcome is no
   root activation provisioning for these optional custom snippets. Any justified
   residual must be explicitly allowlisted, local/short/idempotent, isolated from
   the parent shell, and tested for both preserved error reporting and reaching
   the final system link. Do not use blanket `|| true` or background `&` as the fix.

Suggested local-file setup defaults are 30–60 seconds to start and 10–30 seconds
to stop, with documented per-job overrides. They are design defaults, not existing
verified limits. Inspect lock-screen/PAM dependencies and session environment
before applying filesystem sandboxing; do not blindly copy system-service
hardening flags onto desktop/FUSE jobs.

## 4. Implementation sequence

### A. Establish fleet rollout and test prerequisites

- Capture each owner's hostname, reachable pinned SSH route, clean checkout and
  branch, current/booted/profile outputs, bootloader mode/ESP or GRUB device,
  free space, retention roots and current build/stage activity. Existing checkout
  edits are not disposable. Do not guess Nixbook/RVBee owning paths from old docs.
- Add the evaluated inventory and optional-setup contract to regression checks.
- Resolve the staging enrollment gap below before treating the fleet as deliverable.

### B. Remove optional root provisioning

- Migrate Hyprland, Waybar, power helper, launcher entries and Maestral intent as
  described above; handle AccountsService as a separate privileged case.
- Preserve every host's desktop/backend distinctions, lock-before-sleep behavior,
  legacy fallback, brightness scripts and Waybar extra variants.
- Remove the old writers only once their replacement and migration tests pass;
  no period with two independent owners of the same destination.

### C. Harden and decouple setup services

- Consolidate local mutable jobs under the bounded helper, including existing
  Dux/Hokum and optional CLI/client setup; keep credentials runtime-only.
- Defer network/model/Flatpak/container preparation and the dependent consumer
  subtrees, retaining app-specific readiness and current retry intent.
- Review the **evaluated** system/user unit graphs, not only source `after` lists.

### D. Verification gates

- Evaluate all four configurations with the committed, frozen lock; require no
  failed assertions and a classified inventory diff. The only planned input-pin
  change is the reviewed shared-client enrollment revision described below; do
  not refresh unrelated inputs. Review imported snippets, not just a grep denylist.
- Extend `scripts/test-activation-resilience.py` beyond Nixstation/Waybar. Test
  parent flags/traps, error visibility and final system-link creation for any
  residual custom root fragment. Never run evaluated full activation on a real
  installed root or repair chroot as a “test”.
- Run mutable setup only against disposable homes: full/inode-exhausted and
  read-only storage, malformed JSON/KDL, permission errors, broken symlinks,
  interrupted copies, concurrent invocations and reruns. Prior usable state must
  survive; no false success marker or silent loss of user edits.
- Verify timeout/process cleanup, generation-change readiness, target/consumer
  isolation and offline behavior in disposable systemd/NixOS VM tests. Force an
  optional job to fail/hang and prove boot completion, login, journal and SSH
  remain available. Include missing synced files and unavailable model services.
- Verify generated systemd units and dependency graphs with default-dependency
  semantics intact. Preserve Dux notify readiness and Hokum's sole notification
  bus ownership; retain their existing headless integration checks.
- Build all four complete closures using their selected reviewed routes; confirm
  required scripts/config/launchers, per-host boot assets and adequate storage.
  Evaluation alone, or a Nixstation build alone, does not pass this gate.

## 5. Fleet boot-staging deliverable

### Enrollment gap that must be closed

The repository imports `modules/colony-builder-client.nix` only for Nixstation and
Nixvader. It selects boot policy only for those names. The **pinned** shared
implementation's `colony_fleet.HOSTS` lists Nomad, Nixstation and Nixvader; the
client module also restricts reviewed desktop bootloaders and installed updater
wrappers to the two desktop hosts. Therefore `all` does **not** mean all four
Hyprvibe hosts, and renaming a command cannot add safe support.

**Recommended prerequisite:** extend the existing shared guided updater's
owner-local validation/exact-output boot-staging support to Nixbook and RVBee,
with explicit verified owner metadata, systemd-boot policies, source/lock checks,
retention, receipts, admission boundaries and tests. This is a source dependency
in the shared client repository, followed by an intentional `colony-client` pin
update in Hyprvibe—not a broad `nix flake update` or unreviewed fallback.

For the first rollout, validate how a store-built candidate helper can use the
owner-local protocol without requiring a live switch/reboot just to install its
wrapper. If current root policy cannot safely bootstrap that path, resolve the
specific enrollment prerequisite first; do not bypass host checks, copy another
machine's identity, deploy Nomad incidentally, or fall back to an ad-hoc remote
`switch`. Select owner-local as the initial proposed route for the newly enrolled
hosts, not an automatic fallback from Colony.

### Required per-host procedure after the implementation gates pass

1. Freeze and publish one reviewed functional candidate **C** on `main`; keep
   each owner's required branch identity while advancing it to the approved
   source. Record each host's lock hash, full revision and toplevel derivation.
   If a source repair is necessary, invalidate only the affected receipts and
   revalidate the changed candidate before staging it.
2. Serialize large builds according to target-scoped admission. Nixstation keeps
   its owner-local route; Nixvader keeps Colony with exact retained transfer
   verification. Nixbook/RVBee use their newly reviewed explicit route. Preserve
   one exact candidate and persistent worker; never duplicate uncertain jobs.
3. Require host-specific full-build and validation receipts, retained exact output,
   clean owning source and publication. Use the corresponding guided
   `validate` → `diff` → `commit` → `push` → `boot` workflow as applicable;
   already committed C must retain its identity. **Do not run `update` or `all`**
   merely to stage this refactor, since those can select newer inputs.
4. Stage sequentially on each owner. Require the receipt's exact source/output,
   dry-activation acceptance and verified default boot entry/assets: BIOS GRUB
   on Nixstation, systemd-boot on Nixvader/Nixbook/RVBee, after confirming live
   hardware mode and mounted boot filesystem. Never replay uncertain staging.
5. Confirm selected system profile equals the staged output while running and
   booted outputs and boot ID remain unchanged; preserve prior boot entries,
   generations and retention roots. No app/service restart should occur merely
   because an output was staged. Record any pre-existing health issues separately.
6. Produce a four-row completion receipt: owner, candidate/lock, derivation,
   retained output, full-build/test results, publication, previous generation,
   staging receipt, bootloader asset verification and unchanged live generation.
   An offline/unreachable owner is **pending**, not staged; finish safe independent
   hosts and report the exact blocker without claiming fleet completion.

**Stop condition:** all four rows are `boot-staged, verified`, with no live
activation or reboot performed. Any later desktop/SSH/boot acceptance requires
actual reboot evidence, under separate reboot authorization. Nixstation's earlier
recovery reboot approval does not authorize a new fleet reboot.

## 6. Reproducing the source audit

From the Hyprvibe root, using the committed baseline rather than a dirty candidate:

```sh
nix eval --impure --json --no-update-lock-file --no-write-lock-file --expr '
  import ./scripts/audit-activation.nix {
    flake = builtins.getFlake
      "git+file:///ABSOLUTE/HYPRVIBE/PATH?rev=94d63f79e4bb83e976457948ffb5bad62672ca7e";
  }
'
```

The inspector emits names, definition files, types, dependency/timeout metadata
and derivation identities—not script bodies, service environments or secrets.
Its known-custom classification is not an automatic future allowlist: review
`activationNames` and `activationDefinitionFiles` for new definitions. Lexical
shell hints are not a parser and can match heredoc contents.

Task evidence/limits are maintained in
[`../.beads/activation-hardening-20261031.md`](../.beads/activation-hardening-20261031.md).
Beads database writes remain blocked by the existing remote schema-coordination
gate; this audit did not migrate or bootstrap the shared database.
