# Hyprvibe activation audit and hardening plan

## Objective and scope
- User requested an audit of remaining custom activation snippets and a plan to
  harden **all four hosts**: nixstation, nixvader, nixbook, rvbee.
- Planned implementation must finish with validated, published exact outputs
  staged for boot on every host; no live switch or automatic reboot.
- This phase authorizes inspection/evaluation and audit/plan documentation only.
  No functional configuration edits, input refresh, builds, staging, service
  restarts, reboots, secret changes, or tracker migration.
- Source baseline: origin/main `94d63f79e4bb83e976457948ffb5bad62672ca7e`.
  Isolated branch/worktree: audit/activation-hardening-20261031.
  Existing worktrees, user data, stashes, deployed generations remain untouched.

## State
- Read AGENTS.md, docs/README.md, guided-update/build-policy documentation.
- Source search found shared and Nixstation root snippets, duplicated user setup,
  and additional legacy RVBee Lore snippets whose import reachability must be
  established before treating them as active.
- Beads read-only `bd ready --json` is blocked: remote schema v32 vs CLI v66,
  missing is_blocked column. No migration/bootstrap/schema change performed.
  Following existing repo practice, this `.beads/*.md` ledger tracks the task.
- Pinned evaluation complete: 6 distinct active custom root definitions across
  13 host instances (station5, vader3, book3, rvbee2); 25 hyprvibe-setup-* user
  oneshots all lack explicit startup timeouts. User-icon snippet inactive on all
  four; RVBee Lore's13 legacy definitions are not imported/evaluated.
- All four assertion sets empty and toplevel derivation evaluations pass. This
  realized one SOURCE-ONLY patched-nixpkgs derivation via IFD and fetched pinned
  substitutes; no host closure build, remote host operation or input update.
- Network boot-path risks confirmed in evaluated metadata: Nixstation model
  prepull48h; RVBee core/optional24h plus dependent Cognee/container graph;
  Flatpak and synced-config oneshots lack explicit timeout. CamoFox has runtime
  build/preparation and re-entrant dependent-container restart risk (source
  evidence, NOT a reproduced runtime deadlock).
- Avoided a false positive: After=default.target plus WantedBy=default.target is
  not itself a proven cycle. Disposable systemd user verification passes after
  supplying a private XDG_RUNTIME_DIR; systemd262 source explicitly skips the
  contradictory automatic target edge. Consumer races still need actual graph tests.
- Pinned colony-client HOSTS/policy covers Nomad/station/vader only. Plan includes
  explicit reviewed owner-local enrollment/bootstrap for book/rvbee, not fake
  wrapper names or fallback. Preserve station-local/vader-Colony routing.
- Drafted docs/ACTIVATION_HARDENING.md, linked from docs/README.md, and added
  read-only scripts/audit-activation.nix for reproducibility (no secret/env output).
  Repo inspector re-evaluation EXIT0 and metadata equality with the scratch audit
  verified. Matrix assertions check all4 hosts,13 active roots,25 timeout gaps
  and absent legacy definitions. Nix syntax, document links/scope/completion
  contract and git diff --check PASS.
- All custom audited root snippets default supportsDryActivation=false; staging
  dry activation alone cannot exercise their home writes. Plan requires sandbox
  failure injection and disposable-boot tests before production staging.

## Checks / next action
- No full builds, host service changes, staging or reboots issued.
- Initial scratch inspector wrongly assumed every activation value was an attrset;
  corrected to normalize Nix's string-or-submodule union. No production change.
- Audit/plan complete; no production configuration changes made.
  Implementation and actual fleet staging remain future execution, not claimed.

## Build-lane coordination (2026-10-31)
- Chad relayed Chris-authorized coordination at13:16:50UTC. Reported separate
  Nomad Quark PR58 validation21796a14 completed full build/verified transfer at
  13:13:46UTC and released its Colony lane around13:14; this session has not
  independently audited that external work and does not assume ownership of it.
- Subsequent13:18UTC update supersedes only the external approval status: Chris
  approved PR58 merge, merged validation, conditional Nomad deployment and bounded
  pilot; the SEPARATE Nomad coordinator owns execution and fresh admission. This
  grants no additional Hyprvibe authority and requests no forced pause/interrupt.
- This Hyprvibe audit session submitted NO Colony build/queue/staging request,
  acquired no lane, and has nothing to release/cancel. All evaluation workers
  finished; the only realization was local source-only patched-nixpkgs via IFD.
- No build is planned before stopping. Future authorized implementation/builds
  must obtain fresh target-scoped admission and preserve existing routing/guards.
  Coordination grants no implementation, merge, staging, deploy or retry authority.
- Publication is restricted to this audit/plan branch; no merge to main or live
  host operation. Nomad and DataFishDeck are not targets of this audit rollout.
