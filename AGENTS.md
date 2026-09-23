# Agent Instructions

This project uses **bd** (beads) for issue tracking. In a fresh clone, run
`chmod 700 .beads && bd bootstrap` before `bd onboard`.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd dolt pull          # Pull shared issue history
bd dolt push          # Push shared issue history
```

## Nixstation Runtime Safety

- Never run `nixos-rebuild switch` or `nixos-rebuild test` on `nixstation`
  without Chris's explicit permission.
- This is critical when working on Wayland, Hyprland, display manager,
  graphics, monitor, DPMS, lock-screen, or user-session configuration.
- Prefer `nix flake check`, targeted builds, and `nixos-rebuild boot` for
  staged changes unless Chris asks for a live activation.

## Colony Remote Builder Safety

- Chris approved `nixvader-update` and `nixstation-update` as the default guided
  build/update workflows, using the supervised Colony coordinator. Prefer the
  owning host's wrapper; ordinary `nix build` and `nixos-rebuild` remain local.
- `build --local` is an explicit override, never an automatic fallback. Rerun
  the same wrapper to resume the same committed candidate; do not create a new
  job to evade failure/recovery limits. See `docs/GUIDED_UPDATES.md`.
- Colony runs production Matrix. Admission must establish fleet idleness before
  dispatch; never compete with or interrupt an existing build for a smoke test.
- Reviewed kernel-compatibility exceptions may realize only the selected
  derivation on this owning host in a bounded coordinator-controlled worker.
  Dependencies remain on Colony. Unknown failures never authorize local retry.
- `validate`, `commit`, `push`, then `boot` select the exact verified candidate
  and boot-stage it. The wrappers never live-switch or reboot implicitly.
- Preserve the pinned host keys, SSH jump route, and ordinary-Nix local behavior
  in `modules/colony-builder-client.nix`. Read
  `docs/COLONY_REMOTE_BUILDER.md` before changing or operating it.

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   bd dolt pull
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
