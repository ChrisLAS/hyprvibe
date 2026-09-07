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

- Colony runs production Matrix. Its containerized Nix builder is an opt-in
  accelerator, never Nixvader's automatic or mandatory builder.
- Use `colony-build` only for an explicitly selected heavyweight build. Before
  starting one, check for active coordinated builds on Nixvader, Nomad, Nixobs,
  or Colony; never compete with or interrupt an existing build for a smoke test.
- Preserve the pinned host keys, SSH jump route, and explicit-only behavior in
  `modules/colony-builder-client.nix`. Read
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
