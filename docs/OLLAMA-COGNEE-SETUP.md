# Declarative Ollama + Cognee (rvbee)

This repo now manages a CPU-only Ollama + Cognee stack declaratively on `rvbee` via NixOS Podman containers.

## What this config provides

- `ollama` on `127.0.0.1:11434`
- `cognee` on `127.0.0.1:8001`
- Persistent model/data directories:
  - `/var/lib/ollama`
  - `/var/lib/cognee`
- Core models pre-pulled (blocking for readiness):
  - `mistral`
  - `nomic-embed-text`
- Optional model pre-pulled (non-blocking):
  - `neural-chat`

## LTE-safe behavior

Model pulls are handled by systemd oneshot services with:
- Long timeout (`24h`)
- Retry + backoff loops
- Per-model marker files in `/var/lib/ollama/.prefetch`

This means slow or unstable LTE links are tolerated and downloads resume safely across retries/restarts.

## Apply configuration

```bash
cd /home/chrisf/build/config
sudo nixos-rebuild dry-build --flake .#rvbee
sudo nixos-rebuild switch --flake .#rvbee
```

## Service management

```bash
# container units
systemctl status podman-ollama.service
systemctl status podman-cognee.service

# model preload units
systemctl status ollama-models-core-prepull.service
systemctl status ollama-models-optional-prepull.service

# restart stack
sudo systemctl restart podman-ollama.service
sudo systemctl restart ollama-models-core-prepull.service
sudo systemctl restart podman-cognee.service
```

## Verify models and APIs

```bash
# Ollama API and model list
curl -sS http://127.0.0.1:11434/api/tags | jq
podman exec ollama ollama list

# Generate test
curl -sS http://127.0.0.1:11434/api/generate \
  -d '{"model":"mistral","prompt":"Respond with: ok","stream":false}' | jq

# Embeddings test
curl -sS http://127.0.0.1:11434/api/embeddings \
  -d '{"model":"nomic-embed-text","prompt":"hello world"}' | jq

# Cognee health (if health endpoint is exposed by image version)
curl -sS http://127.0.0.1:8001/api/health
```

## OpenClaw + Cognee integration

Your OpenClaw Cognee memory plugin should point to local Cognee:

- `plugins.entries.memory-cognee.config.baseUrl = "http://localhost:8001"`
- `plugins.slots.memory = "memory-cognee"`

Useful commands:

```bash
openclaw config set plugins.entries.memory-cognee.config.baseUrl "http://localhost:8001"
openclaw config set plugins.slots.memory memory-cognee
openclaw doctor --fix
systemctl --user restart openclaw-gateway.service
```

If your OpenClaw build supports Cognee subcommands:

```bash
openclaw cognee index
openclaw cognee status
```

If not, verify via gateway logs:

```bash
journalctl --user -u openclaw-gateway.service -n 200 | rg -i 'memory-cognee|cognee'
```

## Manual indexing workflow (recommended)

To keep memory useful without sustained CPU runaway, keep:

- `plugins.entries.memory-cognee.config.autoRecall = true`
- `plugins.entries.memory-cognee.config.autoIndex = false`
- `plugins.entries.memory-cognee.config.searchType = "CHUNKS"`
- `plugins.entries.memory-cognee.config.recallSessionDenyPatterns = ["^agent:[^:]+:cron:"]`

This policy keeps recall enabled for interactive Lore/sub-agent sessions and skips recall for cron sessions.

Then run bounded manual index windows with:

```bash
~/.openclaw/scripts/memory_index_window.sh
```

Convenience wrapper (same behavior):

```bash
~/.openclaw/scripts/index-memory
```

Optional flags:

```bash
~/.openclaw/scripts/memory_index_window.sh --max-minutes 15
~/.openclaw/scripts/memory_index_window.sh --cpu-threshold 300
~/.openclaw/scripts/memory_index_window.sh --cooldown-minutes 120
~/.openclaw/scripts/memory_index_window.sh --force

# wrapper form
~/.openclaw/scripts/index-memory --max-minutes 15
```

What the script does:

- Verifies gateway + `podman-cognee` + `podman-ollama` are active
- Temporarily enables `autoIndex=true`
- Restarts gateway and monitors per-minute CPU + Cognee sync errors
- Automatically rolls back to `autoIndex=false` if guardrails trip
- Always restores `autoIndex=false` before exit
- Emits JSON run summary to `~/.openclaw/state/memory-index-window-state.json`

Recommended trigger policy for Lore:

- Run after significant memory edits (about 10+ changed memory files), or end-of-day
- Run during low traffic periods
- Max 1 run every 2 hours unless manually forced

## Declarative policy patch on rvbee

`hosts/rvbee/lore.nix` now declaratively syncs a patched `memory-cognee` plugin and policy defaults:

- Plugin sync target: `~/.openclaw/extensions/memory-cognee/`
- Recall policy:
  - interactive sessions: recall enabled
  - cron sessions: recall skipped by session-key regex
- Index policy:
  - default `autoIndex=false`
  - run bounded manual windows via `index-memory`

## Split loop lanes (heartbeat vs orchestration)

To reduce lock contention and CPU spikes while keeping memory utility:

- `heartbeat-agent` lane (timer-driven): lightweight health checks only, recall denied
- `loop-agent` lane (hourly): full orchestration per `LOOP.md`, recall allowed
- Before each run, runner scripts sync canonical docs:
  - `HEARTBEAT.md` from `/home/chrisf/code/clawdbot-local/documents/HEARTBEAT.md` into `~/.openclaw/workspace-heartbeat-agent/`
  - `LOOP.md` from `/home/chrisf/code/clawdbot-local/documents/LOOP.md` into `~/.openclaw/workspace-loop-agent/`

Session-key recall deny patterns include:

- `^agent:[^:]+:cron:`
- `^agent:heartbeat-agent:main$`

User timers/services:

```bash
systemctl --user status lore-loop.timer lore-orchestration.timer
systemctl --user status lore-loop.service lore-orchestration.service
```

Manual triggers:

```bash
systemctl --user start lore-loop.service
systemctl --user start lore-orchestration.service
```

Rollback conditions in the script:

- `ollama runner` CPU above threshold for 3 consecutive samples
- Memory-cognee error count exceeds cap during the index window

## Resource limits

Configured container limits for this host (Ryzen 5700U, 30GB RAM):

- Ollama: `--cpus=6`, `--memory=16g`
- Cognee: `--cpus=4`, `--memory=8g`

These are conservative defaults for CPU-only operation and can be tuned in `hosts/rvbee/ai-memory-stack.nix`.
