# OpenClaw `nomad` Migration Runbook

Audience: Lore coordinating Data and tracking progress in beads.

Date grounded: March 12, 2026 (America/Los_Angeles).

Host model:
- Source host: `rvbee`
- Target host: `nomad`
- Remote login: `ssh chrisf@nomad`
- Privilege escalation on target: `sudo` without password

This runbook is written for execution by agents, not for human review. It uses
absolute paths and avoids relying on unstated context.

## 1. Source Of Truth

This migration report is grounded in:

- Declarative config in:
  - `/home/chrisf/build/config/flake.nix`
  - `/home/chrisf/build/config/hosts/rvbee/system.nix`
  - `/home/chrisf/build/config/hosts/rvbee/lore.nix`
  - `/home/chrisf/build/config/hosts/rvbee/ai-memory-stack.nix`
- Live runtime state in:
  - `/home/chrisf/.openclaw/`
  - `/home/chrisf/.acpx/config.json`
  - `/home/chrisf/.config/secrets/`

Limits of this report:

- It is based on files and local filesystem state.
- Live `systemctl` and `tailscaled` inspection from the current Codex sandbox was
  not available.
- Where runtime behavior depends on external services, this report marks those
  items for validation on `nomad`.

## 2. Declarative NixOS Inventory

### 2.1 Flake Input And Packages

- OpenClaw packages come from `github:openclaw/nix-openclaw` via
  `/home/chrisf/build/config/flake.nix`.
- `rvbee` imports `/home/chrisf/build/config/hosts/rvbee/lore.nix` and
  `/home/chrisf/build/config/hosts/rvbee/ai-memory-stack.nix`.
- `lore.nix` installs these OpenClaw-adjacent packages into the system profile:
  - `openclaw`
  - `acpx`
  - `codex-latest`
  - `codex-acp`
  - `opencode`
  - `mcp-proxy`
  - runtime helpers such as `python3`, `jq`, `git`, `nixos-rebuild`, `clojure`,
    `bun`, `whisper-cpp`, `gh`, `fd`, and `ripgrep`

### 2.2 Declarative Environment Variables

`/home/chrisf/build/config/hosts/rvbee/lore.nix` sets:

- `LORE_CORE=active`
- `LORE_OS=NixOS`
- `OPENCLAW_NIX_MODE=1`
- `OPENCLAW_CONFIG_DIR=/home/chrisf/.openclaw`

`openclaw-gateway` service environment adds:

- `NODE_ENV=production`
- `HOME=/home/chrisf`
- `OPENCLAW_NIX_MODE=1`
- `OPENCLAW_BIND=0.0.0.0`
- `OPENCLAW_ALLOW_INSECURE_WEBSOCKETS=1`
- `OPENCLAW_BUNDLED_SKILLS_DIR=/home/chrisf/.openclaw/skills-bundled`

### 2.3 Activation Scripts That Create Or Mutate Runtime State

`/home/chrisf/build/config/hosts/rvbee/lore.nix` uses activation scripts to
manage non-store state under `/home/chrisf`:

- `lore-bootstrap`
  - creates `/home/chrisf/.openclaw/scripts`
  - creates legacy symlink `/home/chrisf/.clawdbot -> /home/chrisf/.openclaw`
- `openclaw-token-gen`
  - creates `/home/chrisf/.openclaw/openclaw-token.txt` if missing
- `openclaw-gateway-config`
  - merges Nix-enforced settings into `/home/chrisf/.openclaw/openclaw.json`
  - injects gateway auth, Tailscale mode, trusted proxies, TTS defaults, exec
    policy, PATH, and elevated policy
- `openclaw-tailscale-serve-setup`
  - attempts to publish the gateway through Tailscale Serve
- `openclaw-loop-runner-sync`
  - copies loop scripts and unit files into:
    - `/home/chrisf/.openclaw/workspace-lore/`
    - `/home/chrisf/.openclaw/scripts/`
    - `/home/chrisf/.config/systemd/user/`
- `openclaw-sudo-shim`
  - writes `/home/chrisf/.openclaw/bin/sudo`
- `openclaw-memory-cognee-plugin-sync`
  - syncs declarative `memory-cognee` plugin files into
    `/home/chrisf/.openclaw/extensions/memory-cognee/`
- `openclaw-bundled-plugins-sync`
  - manages `/home/chrisf/.openclaw/extensions-bundled/`
- `openclaw-bundled-skills-sync`
  - manages `/home/chrisf/.openclaw/skills-bundled/`
- `openclaw-memory-cognee-policy`
  - would merge recall/index policy only if `memory-cognee` is present in
    `openclaw.json`
- `openclaw-acpx-config`
  - writes `/home/chrisf/.acpx/config.json`
- `openclaw-acp-config`
  - merges ACP runtime settings into `openclaw.json`

### 2.4 Declarative Services And Timers

Declared in `/home/chrisf/build/config/hosts/rvbee/lore.nix`:

- User services:
  - `openclaw-gateway`
  - `openclaw-tailscale-serve` (documentation placeholder, actual state lives in
    Tailscale)
- System services:
  - `openclaw-bridge-dax`
  - `openclaw-morning-digest`
  - `mcp-proxy`
- System timer:
  - `openclaw-morning-digest.timer`

Copied into `/home/chrisf/.config/systemd/user/` from
`/home/chrisf/build/config/hosts/rvbee/openclaw-loop/`:

- `lore-loop.service`
- `lore-loop.timer`
- `lore-orchestration.service`
- `lore-orchestration.timer`
- `lore-memory-index.service`
- `lore-memory-index.timer`

Current schedules from the checked-in units:

- Heartbeat loop: every 15 minutes by default, with runtime cadence overrides
  written to `~/.config/systemd/user/lore-loop.timer.d/override.conf`
- Orchestration loop: every 60 minutes
- Memory index: nightly at `03:20` local time
- Morning digest: daily at `07:00`

### 2.5 OpenClaw Gateway Behavior Enforced By Nix

Runtime config in `/home/chrisf/.openclaw/openclaw.json` currently shows:

- Gateway:
  - port `18789`
  - mode `local`
  - bind `loopback`
  - auth mode `token`
  - Tailscale mode `serve`
  - trusted proxies include `127.0.0.1`, `::1`, `100.64.0.0/10`,
    and host-specific IP `100.75.168.43`
- Agents:
  - `lore`
  - `loop-agent`
  - `heartbeat-agent`
  - `number-one`
  - `data`
- Default workspace:
  - `/home/chrisf/code/clawdbot-local/documents`
- Default model:
  - `minimax/MiniMax-M2.5`
  - fallbacks include Gemini and GPT-4.1 Mini
- Channels enabled:
  - Telegram
  - Discord
- ACP runtime:
  - enabled
  - backend `acpx`
  - default ACP agent `codex`
- Plugins currently enabled in `openclaw.json`:
  - `acpx`
  - `openclaw-mcp-bridge`

Important nuance:

- `memory-cognee` exists on disk in
  `/home/chrisf/.openclaw/extensions/memory-cognee/`
- It is not currently present in `plugins.entries` in
  `/home/chrisf/.openclaw/openclaw.json`
- The Cognee-related timers, scripts, and container state still exist and should
  be preserved for parity and future re-enable

### 2.6 AI Memory Stack And Local Sidecars

`/home/chrisf/build/config/hosts/rvbee/ai-memory-stack.nix` declares:

- Podman container `ollama`
  - listens on `127.0.0.1:11434`
  - persistent state in `/var/lib/ollama`
- Podman container `cognee`
  - listens on `127.0.0.1:8001`
  - persistent state in `/var/lib/cognee`
- Model pre-pull services for:
  - `nomic-embed-text`
  - `mistral`
  - optional `neural-chat`

Also relevant from `system.nix` and `lore.nix`:

- FreshRSS MCP server:
  - URL `https://freshrss.trailertrash.io`
  - local port `3005`
  - password file `/home/chrisf/.config/secrets/freshrss-mcp`
- Clojure MCP proxy:
  - local port `3006`
- OpenClaw MCP bridge runtime points at:
  - Cloudflare MCP over HTTPS
  - FreshRSS on `127.0.0.1:3005`
  - Clojure proxy on `127.0.0.1:3006/mcp`

## 3. Mutable Runtime State Outside Nix

Everything in this section will be missing if only the Nix config is moved.

### 3.1 Core OpenClaw Runtime

Must copy:

- `/home/chrisf/.openclaw/openclaw.json`
- `/home/chrisf/.openclaw/openclaw-token.txt`
- `/home/chrisf/.acpx/config.json`

Important details:

- `openclaw.json` contains inline secrets today, including:
  - gateway token
  - Telegram bot tokens
  - Discord tokens
  - `ELEVENLABS_API_KEY`
  - `PINBOARD_API_TOKEN`
  - Cloudflare MCP token for `openclaw-mcp-bridge`
- Losing this file means losing active gateway/channel/plugin/runtime policy, not
  just defaults

### 3.2 Credentials And Auth Material

Must copy:

- `/home/chrisf/.openclaw/credentials/`
- `/home/chrisf/.openclaw/identity/`
- `/home/chrisf/.openclaw/devices/`
- `/home/chrisf/.config/secrets/`

Observed credential files under `~/.openclaw/credentials/`:

- `alby/config.json`
- `cloudflare/config.json`
- `crypto/lore_wallet.json`
- `discord/token.txt`
- `elevenlabs/config.json`
- `google/calendar_ics_url.txt`
- `google/client_secret.json`
- `grafana/config.json`
- `jellyfin/config.json`
- `mattermost/config.json`
- `mealie/config.json`
- `nvidia/config.json`
- `openrouter/config.json`
- `sabnzbd/config.json`
- `sonarr/config.json`
- `voyage/config.json`
- `xai/config.json`
- `telegram-pairing.json`
- `matrix-pairing.json`
- Telegram allowlists:
  - `telegram-allowFrom.json`
  - `telegram-default-allowFrom.json`
  - `telegram-lore-allowFrom.json`
  - `telegram-number-one-allowFrom.json`

Observed `~/.config/secrets/` files referenced by the OpenClaw stack:

- `freshrss-mcp`
- `github_token`
- `homeassistant_password`
- `homeassistant_token`
- `load_restic_env.sh`
- `minimax`
- `obsidian_mcp_key`
- `openrouter_api_key`
- `pinboard_api_key`
- `r2_backup_access_key`
- `r2_backup_endpoint`
- `r2_backup_secret_key`
- `restic_password`
- `todoist_token`
- `tomtom_api_key`
- plus additional secret helpers and env fragments in the same directory

Observed device state:

- `/home/chrisf/.openclaw/identity/device.json`
  - contains device keypair material
- `/home/chrisf/.openclaw/identity/device-auth.json`
  - contains device auth tokens
- `/home/chrisf/.openclaw/devices/paired.json`
  - currently contains 3 paired devices
- `/home/chrisf/.openclaw/devices/pending.json`
  - currently empty

### 3.3 Cron Store And Run History

Must copy:

- `/home/chrisf/.openclaw/cron/`

Current observed state:

- `jobs.json` currently contains 28 jobs
- `cron/runs/` currently contains 963 recorded run files

These jobs include work that depends on:

- OpenClaw agents and sessions
- `/home/chrisf/.openclaw/scripts/`
- `/home/chrisf/code/clawdbot-local/documents/`
- `/home/chrisf/.config/secrets/`
- `/home/chrisf/.config/moltbook/credentials.json`

### 3.4 Agent Sessions, Workspaces, Prompts, And Skills

Must copy:

- `/home/chrisf/.openclaw/agents/`
- `/home/chrisf/.openclaw/workspace-*`
- `/home/chrisf/.openclaw/skills/`
- `/home/chrisf/.openclaw/beads/`
- `/home/chrisf/.openclaw/state/`
- `/home/chrisf/.openclaw/scripts/`

Current observed session archive counts:

- `agents/lore/sessions`: 365 files
- `agents/main/sessions`: 145 files
- `agents/data/sessions`: 96 files
- `agents/number-one/sessions`: 38 files
- `agents/loop-agent/sessions`: 13 files
- `agents/heartbeat-agent/sessions`: 12 files
- `agents/dax/sessions`: 7 files
- `agents/uhura/sessions`: 5 files
- `agents/lore-loop/sessions`: 2 files

Current observed workspace prompt files:

- `/home/chrisf/.openclaw/workspace-data/HEARTBEAT.md`
- `/home/chrisf/.openclaw/workspace-dax/HEARTBEAT.md`
- `/home/chrisf/.openclaw/workspace-heartbeat-agent/HEARTBEAT.md`
- `/home/chrisf/.openclaw/workspace-loop-agent/HEARTBEAT.md`
- `/home/chrisf/.openclaw/workspace-loop-agent/LOOP.md`
- `/home/chrisf/.openclaw/workspace-lore-loop/HEARTBEAT.md`
- `/home/chrisf/.openclaw/workspace-lore/HEARTBEAT.md`
- `/home/chrisf/.openclaw/workspace-lore/codex-morning-report-prompt.md`
- `/home/chrisf/.openclaw/workspace-main/HEARTBEAT.md`
- `/home/chrisf/.openclaw/workspace-number-one/HEARTBEAT.md`
- `/home/chrisf/.openclaw/workspace-uhura/HEARTBEAT.md`

### 3.5 Memory, Media, Delivery, And Misc State

Must copy:

- `/home/chrisf/.openclaw/memory/`
- `/home/chrisf/.openclaw/media/`
- `/home/chrisf/.openclaw/delivery-queue/`
- `/home/chrisf/.openclaw/telegram/`
- `/home/chrisf/.openclaw/exec-approvals.json`
- `/home/chrisf/.openclaw/dns/`

Current observed counts:

- delivery queue pending: 3 files
- delivery queue failed: 6 files
- inbound media: 33 files
- outbound media: 7 files
- top-level SQLite memory files: 7

### 3.6 Custom Extensions

Must copy:

- `/home/chrisf/.openclaw/extensions/`

Current observed local extensions:

- `memory-cognee`
- `openclaw-mcp-bridge`

`openclaw-mcp-bridge` is especially important because its runtime config in
`openclaw.json` points at external and local MCP servers.

## 4. Host-Specific Paths And External Dependencies

These items are tied to `rvbee`, `/home/chrisf`, or external services.

### 4.1 Host-Specific Paths

Hard-coded paths observed in scripts and config:

- `/home/chrisf/.openclaw/...`
- `/home/chrisf/.acpx/config.json`
- `/home/chrisf/.config/secrets/...`
- `/home/chrisf/build/config`
- `/home/chrisf/code/clawdbot-local/documents`
- `/home/chrisf/Dropbox/Chris Fisher/...`
- `/home/chrisf/.config/moltbook/credentials.json`

Implication:

- The migration is safest if `nomad` also uses user `chrisf` with home
  `/home/chrisf`.
- If not, multiple scripts, timer payloads, and JSON config values must be
  rewritten before the host is usable.

### 4.2 Host Identity And Network-Specific Data

Host-bound items:

- hostname `rvbee`
- Tailscale Serve publication:
  - intended public tailnet URL is `https://rvbee.coin-noodlefish.ts.net/`
- trusted proxy IP `100.75.168.43` in `openclaw.json`

Implication:

- A copied config on `nomad` will still describe `rvbee` until corrected.
- Tailscale Serve and any tailnet naming will need validation or re-publish.

### 4.3 External Services And APIs To Re-Wire Or Validate

Must validate from `nomad` after restore:

- Tailscale login and Serve
- Telegram bot accounts
- Discord accounts
- Cloudflare MCP endpoint token
- FreshRSS credentials and local bridge on port `3005`
- local Clojure MCP proxy on port `3006`
- OpenRouter access
- ElevenLabs access
- Google calendar ICS URL and OAuth client secret
- xAI access for Dax/Uhura scripts
- Mealie, Mattermost, Sonarr, SABnzbd, Jellyfin, Grafana, NVIDIA, Alby, Voyage
- R2/restic backup credentials
- Todoist, Obsidian, and TomTom secrets used by MCP helpers

Also validate local repositories and content:

- `/home/chrisf/build/config`
- `/home/chrisf/code/clawdbot-local/documents`

## 5. What Breaks If Only The Nix Config Moves

### 5.1 Rebuilt By Nix

These will be created or installed again by a rebuild:

- OpenClaw package from flake input
- `openclaw-gateway` unit definition
- `openclaw-bridge-dax`
- `openclaw-morning-digest`
- `mcp-proxy`
- Podman unit definitions for Ollama and Cognee
- activation scripts themselves
- user/system package set

### 5.2 Must Copy

These are not recreated with usable prior state:

- `/home/chrisf/.openclaw/`
- `/home/chrisf/.acpx/config.json`
- `/home/chrisf/.config/secrets/`
- `/home/chrisf/code/clawdbot-local/documents/`
- `/home/chrisf/build/config/`

### 5.3 Must Recreate Or Rebuild In Place

These are generated by activation, but still need restore context:

- `/home/chrisf/.clawdbot` symlink
- `/home/chrisf/.openclaw/bin/sudo`
- copied loop scripts in `workspace-lore` and `~/.openclaw/scripts`
- copied user units in `~/.config/systemd/user`

Note:

- These can be recreated by Nix after the repos and base state exist on `nomad`.
- They still depend on the target path layout being identical.

### 5.4 Must Re-Authorize Or Re-Register

These should be assumed to need explicit verification after copy:

- Tailscale node identity and Serve publication
- any device pairing that is host-bound
- any bot or channel auth that fails after host move
- any integration that uses externally registered redirect URIs, hostnames, or
  node identity

Specific re-authorization candidates:

- Tailscale Serve
- Telegram pairing state if inbound control stops working
- Matrix pairing if used later
- Google OAuth client flow if client restrictions are host-bound

## 6. Ordered Migration Checklist

Use beads throughout. Do not batch work without recording status.

### 6.1 Tracking And Preflight

1. `[Lore]` Create or claim parent bead: `nomad OpenClaw migration`.
2. `[Lore]` Create child beads:
   - `nomad preflight`
   - `nomad state copy`
   - `nomad rebuild`
   - `nomad auth and external validation`
   - `nomad final verification`
3. `[Data]` Verify SSH:

   ```bash
   ssh chrisf@nomad 'hostname && whoami'
   ```

4. `[Data]` Verify passwordless sudo:

   ```bash
   ssh chrisf@nomad 'sudo -n true && echo sudo-ok'
   ```

5. `[Data]` Verify target path assumptions:

   ```bash
   ssh chrisf@nomad 'test "$HOME" = /home/chrisf && mkdir -p /home/chrisf'
   ```

6. `[Data]` Verify disk space before copying state:

   ```bash
   ssh chrisf@nomad 'df -h / /home/chrisf'
   ```

### 6.2 Stage Repositories On `nomad`

7. `[Data]` Ensure base directories exist:

   ```bash
   ssh chrisf@nomad 'mkdir -p /home/chrisf/build /home/chrisf/code'
   ```

8. `[Data]` Copy the config repo:

   ```bash
   rsync -a /home/chrisf/build/config/ chrisf@nomad:/home/chrisf/build/config/
   ```

9. `[Data]` Copy the documents repo:

   ```bash
   rsync -a /home/chrisf/code/clawdbot-local/documents/ \
     chrisf@nomad:/home/chrisf/code/clawdbot-local/documents/
   ```

10. `[Data]` If the documents repo has a real Git remote on the source host,
    preserve `.git/` as part of the copy. Do not strip it.

### 6.3 Copy Runtime State

11. `[Data]` Copy OpenClaw runtime state:

   ```bash
   rsync -a /home/chrisf/.openclaw/ chrisf@nomad:/home/chrisf/.openclaw/
   ```

12. `[Data]` Copy ACP runtime config:

   ```bash
   rsync -a /home/chrisf/.acpx/ chrisf@nomad:/home/chrisf/.acpx/
   ```

13. `[Data]` Copy secret files:

   ```bash
   rsync -a /home/chrisf/.config/secrets/ \
     chrisf@nomad:/home/chrisf/.config/secrets/
   ```

14. `[Data]` If `/home/chrisf/.config/moltbook/credentials.json` exists on the
    source host, copy that path too.

15. `[Data]` Restore ownership and permissions on `nomad`:

   ```bash
   ssh chrisf@nomad '
     chown -R chrisf:users /home/chrisf/.openclaw /home/chrisf/.acpx /home/chrisf/.config/secrets \
       /home/chrisf/build/config /home/chrisf/code/clawdbot-local &&
     chmod 700 /home/chrisf/.config/secrets &&
     find /home/chrisf/.config/secrets -type f -exec chmod 600 {} +
   '
   ```

### 6.4 Rebuild The Host

16. `[Data]` Rebuild from the staged config repo on `nomad`:

   ```bash
   ssh chrisf@nomad '
     cd /home/chrisf/build/config &&
     sudo nixos-rebuild switch --flake .#nomad
   '
   ```

17. `[Lore]` If the flake does not yet define `nixosConfigurations.nomad`, stop,
    create a bead for the host definition, and do not continue pretending the
    migration is complete.

18. `[Data]` After rebuild, confirm activation recreated expected derived files:

   ```bash
   ssh chrisf@nomad '
     test -L /home/chrisf/.clawdbot &&
     test -f /home/chrisf/.openclaw/bin/sudo &&
     test -f /home/chrisf/.openclaw/workspace-lore/run-loop.sh &&
     test -f /home/chrisf/.config/systemd/user/lore-loop.timer &&
     test -f /home/chrisf/.acpx/config.json
   '
   ```

### 6.5 Restore Host-Bound Network Identity

19. `[Data]` Log `nomad` into Tailscale if it is not already joined:

   ```bash
   ssh chrisf@nomad 'sudo tailscale status || true'
   ```

20. `[Data]` If not authenticated, run the appropriate `tailscale up` flow on
    `nomad`.

21. `[Data]` Revalidate Tailscale Serve after login:

   ```bash
   ssh chrisf@nomad 'tailscale serve status || true'
   ```

22. `[Data]` If Serve is missing, re-publish the gateway:

   ```bash
   ssh chrisf@nomad 'tailscale serve --bg --https 443 http://127.0.0.1:18789'
   ```

23. `[Lore]` Record the actual `nomad` tailnet URL if it differs from the old
    `rvbee.coin-noodlefish.ts.net` endpoint.

### 6.6 Bring Up And Validate Services

24. `[Data]` Reload user units and enable the loop timers:

   ```bash
   ssh chrisf@nomad '
     systemctl --user daemon-reload &&
     systemctl --user enable --now openclaw-gateway lore-loop.timer lore-orchestration.timer lore-memory-index.timer
   '
   ```

25. `[Data]` Validate user services:

   ```bash
   ssh chrisf@nomad '
     systemctl --user --no-pager --full status openclaw-gateway lore-loop.timer lore-orchestration.timer lore-memory-index.timer
   '
   ```

26. `[Data]` Validate system services:

   ```bash
   ssh chrisf@nomad '
     sudo systemctl --no-pager --full status openclaw-bridge-dax openclaw-morning-digest.timer mcp-proxy podman-ollama podman-cognee
   '
   ```

27. `[Data]` Validate local listeners:

   ```bash
   ssh chrisf@nomad '
     ss -ltn | rg "127.0.0.1:18789|127.0.0.1:11434|127.0.0.1:8001|127.0.0.1:3005|127.0.0.1:3006"
   '
   ```

28. `[Lore]` Inspect gateway logs for schema, auth, plugin, or channel failures:

   ```bash
   ssh chrisf@nomad '
     journalctl --user -u openclaw-gateway -n 200 --no-pager
   '
   ```

### 6.7 Validate Runtime State Parity

29. `[Data]` Confirm the copied state is present:

   ```bash
   ssh chrisf@nomad '
     test -f /home/chrisf/.openclaw/openclaw.json &&
     test -f /home/chrisf/.openclaw/cron/jobs.json &&
     test -d /home/chrisf/.openclaw/agents/lore/sessions &&
     test -d /home/chrisf/.openclaw/workspace-lore &&
     test -d /home/chrisf/.openclaw/memory &&
     test -d /home/chrisf/.openclaw/extensions/openclaw-mcp-bridge
   '
   ```

30. `[Lore]` Verify prompt files and workspaces:

   ```bash
   ssh chrisf@nomad '
     ls /home/chrisf/.openclaw/workspace-lore/HEARTBEAT.md \
        /home/chrisf/.openclaw/workspace-loop-agent/LOOP.md \
        /home/chrisf/.openclaw/workspace-lore/codex-morning-report-prompt.md
   '
   ```

31. `[Lore]` Verify cron payload survived:

   ```bash
   ssh chrisf@nomad '
     jq ".jobs | length" /home/chrisf/.openclaw/cron/jobs.json
   '
   ```

32. `[Lore]` Verify device and pairing state survived:

   ```bash
   ssh chrisf@nomad '
     jq "keys | length" /home/chrisf/.openclaw/devices/paired.json &&
     jq ".requests | length" /home/chrisf/.openclaw/credentials/telegram-pairing.json
   '
   ```

### 6.8 Validate External Integrations

33. `[Lore]` Validate OpenClaw config shape without printing secrets:

   ```bash
   ssh chrisf@nomad '
     jq "{plugins: (.plugins.entries | keys), channels: (.channels | keys), agents: [.agents.list[].id]}" \
       /home/chrisf/.openclaw/openclaw.json
   '
   ```

34. `[Lore]` Validate OpenClaw MCP bridge targets are reachable:

   ```bash
   ssh chrisf@nomad '
     curl -fsS http://127.0.0.1:3005 >/dev/null &&
     curl -fsS http://127.0.0.1:3006 >/dev/null
   '
   ```

35. `[Lore]` Validate one OpenClaw gateway health path or equivalent smoke test
    that does not expose secrets.

36. `[Lore]` Validate one Telegram inbound/outbound path and one Discord path.
    If they fail after copy, treat that as re-authorization work, not as a
    reason to edit random JSON by hand.

37. `[Lore]` Validate backup dependencies if backups must keep working on `nomad`:
   - `load_restic_env.sh`
   - R2 keys and endpoint
   - restic password

38. `[Lore]` Validate scripts that depend on external repos or secret files:
   - morning digest
   - Dax listener
   - TWIB and launch pipelines
   - NixOS maintenance script

### 6.9 Finish

39. `[Lore]` Open follow-up beads for every failed validation.
40. `[Lore]` Do not close the migration bead until:
   - gateway works
   - timers are running
   - critical secrets are present
   - Tailscale access is restored
   - at least one real channel test succeeds

## 7. Expected Post-Migration Failure Modes

If anything fails on `nomad`, check these in order:

1. User/path mismatch:
   - target user is not `chrisf`
   - home is not `/home/chrisf`
2. Flake mismatch:
   - `nomad` host config does not exist yet
3. Missing repo content:
   - `/home/chrisf/code/clawdbot-local/documents` missing
4. Missing secrets:
   - `~/.config/secrets` incomplete
5. Tailscale not authenticated:
   - Serve and tailnet access unavailable
6. Channel auth drift:
   - copied Telegram or Discord state not accepted on the new host
7. Local sidecars not listening:
   - FreshRSS MCP, Clojure MCP proxy, Ollama, or Cognee not reachable

## 8. Do Not Do

- Do not migrate only `/home/chrisf/build/config` and assume Nix will restore
  OpenClaw state.
- Do not print or paste secret values into beads, chat, or logs.
- Do not hand-edit secret-bearing JSON on `nomad` unless there is a specific,
  documented reason.
- Do not assume Tailscale Serve automatically points at the same tailnet URL
  after a host move.
- Do not declare the migration done until a real channel round-trip succeeds.
