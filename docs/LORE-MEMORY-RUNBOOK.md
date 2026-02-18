# Lore Memory System Runbook

This is the operator runbook for OpenClaw memory on `rvbee`.

## Architecture

- OpenClaw memory plugin: `memory-cognee`
- Cognee API: `http://127.0.0.1:8001`
- Ollama API: `http://127.0.0.1:11434`
- Indexed docs: workspace `MEMORY.md` and `memory/**/*.md`

## Live Policy (stability-first)

- `autoRecall: true`
- `autoIndex: false`
- `searchType: CHUNKS`
- `maxResults: 6`
- `maxTokens: 512`
- `maxIndexChars: 1200`
- `oversizeMode: truncate`
- Recall denied for most cron sessions and `heartbeat-agent`

## Why CPU Abuse Happened

- Auto-index stayed active during high-frequency/looped agent activity.
- Recall was being attempted in low-value cron contexts.
- Oversized memory payloads caused Ollama embedding overflow and retry churn.
- Some automation scripts previously hit Nix sudo path issues.

## What Was Changed

- Default indexing changed to manual windows (`autoIndex=false`).
- Added guarded index script with rollback:
  - `~/.openclaw/scripts/index-memory`
  - `~/.openclaw/scripts/memory_index_window.sh`
- Added strict nightly runner with failure streak auto-disable:
  - `~/.openclaw/scripts/run-memory-index-nightly.sh`
- Added index drift verifier:
  - `~/.openclaw/scripts/verify-cognee-index.sh`
- Added drift reconcile helper:
  - `~/.openclaw/scripts/rebuild-cognee-sync-index.sh`
- Enforced hard payload cap for indexing to avoid embed overflow.
- Enforced wrappers-first PATH (`/run/wrappers/bin`) for Nix sudo reliability.

## Fast Operator Checklist

1. Check services:
```bash
systemctl --user is-active openclaw-gateway
systemctl is-active podman-cognee.service podman-ollama.service
```

2. Run a bounded manual index window:
```bash
~/.openclaw/scripts/index-memory --max-minutes 15 --cpu-threshold 300
```

3. Verify index state:
```bash
~/.openclaw/scripts/verify-cognee-index.sh
cat ~/.openclaw/state/memory-index-verify.json | jq
```

4. If drift persists, reconcile local sync index:
```bash
~/.openclaw/scripts/rebuild-cognee-sync-index.sh
```

5. Check runner state:
```bash
cat ~/.openclaw/state/memory-index-window-state.json | jq
cat ~/.openclaw/state/memory-index-runner-state.json | jq
```

## Timer Operations

Enable nightly guarded indexing:
```bash
systemctl --user enable --now lore-memory-index.timer
```

Disable if system load is high or troubleshooting:
```bash
systemctl --user disable --now lore-memory-index.timer
```

Check timer/service status:
```bash
systemctl --user status lore-memory-index.timer lore-memory-index.service
```

## Troubleshooting

### Symptom: `input length exceeds context length` in Ollama logs

Cause: Index payload too large for embed model context.

Action:
- Confirm `maxIndexChars=1200` and `oversizeMode=truncate` in `~/.openclaw/openclaw.json`.
- Restart gateway after config correction.
- Re-run bounded index window.

### Symptom: `memory-cognee: failed to sync ... Unauthorized (401)`

Cause: Missing/invalid Cognee auth.

Action:
- Verify plugin `baseUrl`, `apiKey`, dataset permissions.
- Re-test with short index run.

### Symptom: `PermissionDeniedError ... [write]` from Cognee

Cause: API key lacks dataset write permissions.

Action:
- Fix Cognee token scope or dataset ownership.
- Re-run `index-memory`.

### Symptom: Nightly runner marks degraded repeatedly

Cause: Index drift, preflight failure, or runtime errors.

Action:
- Read `~/.openclaw/state/memory-index-runner-state.json`.
- Resolve root cause, then re-enable timer.

## Safe Cadence

- Trigger manual index after meaningful memory edits (for example 10+ files changed) or end-of-day.
- Prefer low-traffic windows.
- Keep cooldown between runs unless doing active remediation.

## First Steps for a Fresh Lore Session

1. Read this file.
2. Check service health and timer state.
3. Inspect latest state JSON files.
4. Run verifier before forcing reconciliation.
