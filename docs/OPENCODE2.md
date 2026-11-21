# OpenCode 2 clients

Nixvader's rollout source pins OpenCode 2.3.2; its installed client remains
2.0.29 until a separate Nixvader activation. The shared client module defaults
`opencode2` and the compatibility command `opencode` to Nomad's hosted backend.
V1 is no longer installed or provisioned on these V2-enabled hosts; old data is retained.

- `opencode2-nomad`: Nomad backend, existing Nomad project root.
- `opencode2-showfactory`: separate Showfactory backend and workspace.
- `opencode2-showfactory-hermes`: existing Nomad-backed Hermes project route.
- `opencode2-nomad-status`: authenticated `/api/info` probe.
- `--standalone` / explicit `--server`: deliberate connection override.

Credentials remain in the existing local secret files and never enter argv,
Git or the Nix store. The common launcher is `pkgs/opencode2-client.py`.
OpenCode 2.3.2 uses native goals. The external Goal plugin remains only as a
transitional client store closure while either live backend advertises it; the
client does not configure it as a local plugin. Preserve historical Goal state,
check for active external goals before backend cutover, and do not replay or
migrate them automatically. Native goals do not promise the old token-budget
or history behavior. Remove the unused client closure in a later coordinated
cleanup after both backends activate native goals.

Use the owning host's guided validate and boot workflow after reviewed source
integration and publication. Nixvader uses `nixvader-update` from its owning
`/home/chrisf/build/config` checkout; this isolated worktree is for source review.
Boot staging does not activate the new client until reboot. Live switching
requires a separate operator decision, and Nixstation live switching requires
Chris's explicit approval.
