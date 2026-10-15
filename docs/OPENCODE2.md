# OpenCode 2 clients

The fleet pins OpenCode 2.0.29. The shared client module defaults `opencode2`
and the compatibility command `opencode` to Nomad's hosted backend. V1 is no
longer installed or provisioned on these V2-enabled hosts; old data is retained.

- `opencode2-nomad`: Nomad backend, existing Nomad project root.
- `opencode2-showfactory`: separate Showfactory backend and workspace.
- `opencode2-showfactory-hermes`: existing Nomad-backed Hermes project route.
- `opencode2-nomad-status`: authenticated `/api/info` probe.
- `--standalone` / explicit `--server`: deliberate connection override.

Credentials remain in the existing local secret files and never enter argv,
Git or the Nix store. The common launcher is `pkgs/opencode2-client.py`.
Keep the CLI pin and Goal plugin sources synchronized with both backend repos.
`opencode-plugin-nixpkgs` pins the plugin build environment independently of
host updates: the remote TUI must have the server's exact plugin store path.
The Goal plugin keeps the resume/budget patch and isolates Effect 3 under
`effect-goal-state` for compatibility with OpenCode's Effect 4 runtime.

Use the owning host's guided validate and boot workflow. Boot staging does not
activate the new client until reboot. Nixstation live switching requires Chris's
explicit approval.
