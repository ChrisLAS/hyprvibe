#!/usr/bin/env bash
# Hourly Orchestration Runner (recall-enabled lane)

set -euo pipefail

WORKDIR="/home/chrisf/.openclaw/workspace-lore"
LOOP_WORKSPACE="/home/chrisf/.openclaw/workspace-loop-agent"
CANONICAL_DOCS_DIR="/home/chrisf/code/clawdbot-local/documents"
CANONICAL_LOOP_FILE="$CANONICAL_DOCS_DIR/LOOP.md"
TARGET_LOOP_FILE="$LOOP_WORKSPACE/LOOP.md"
GLOBAL_LOCK_FILE="/home/chrisf/.openclaw/state/lore-loop-global.lock"
SESSIONS_FILE="$HOME/.openclaw/agents/lore/sessions/sessions.json"
HEALTH_FILE="$WORKDIR/orchestration-health.json"
LOCK_WAIT_SECONDS=300
LOOP_AGENT_ID="loop-agent"

export PATH="/run/current-system/sw/bin:/usr/bin:/bin:$HOME/.nix-profile/bin"

log() {
    echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') [bash] $1"
    logger -t lore-orchestration "$1"
}

mkdir -p /home/chrisf/.openclaw/state

# Keep orchestration instructions synced into the loop-agent workspace.
if [ -f "$CANONICAL_LOOP_FILE" ]; then
    mkdir -p "$LOOP_WORKSPACE"
    cp -f "$CANONICAL_LOOP_FILE" "$TARGET_LOOP_FILE"
else
    log "Canonical LOOP.md not found at $CANONICAL_LOOP_FILE; orchestration may run with stale/missing instructions."
fi

if [ -d "$LOOP_WORKSPACE" ]; then
    cd "$LOOP_WORKSPACE"
fi

exec 210>"$GLOBAL_LOCK_FILE"
if ! flock -w "$LOCK_WAIT_SECONDS" 210; then
    log "Global loop lock still held after ${LOCK_WAIT_SECONDS}s; deferring orchestration run (non-failure)."
    cat > "$HEALTH_FILE" <<EOT
{
  "status": "deferred",
  "reason": "global_lock_timeout",
  "last_run": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "wait_seconds": ${LOCK_WAIT_SECONDS}
}
EOT
    exit 0
fi

# Wait up to 5 minutes for Lore main session lock to clear.
wait_for_lore_main_unlock() {
    local waited=0
    while [ "$waited" -lt "$LOCK_WAIT_SECONDS" ]; do
        local main_id=""
        local main_lock=""
        if [ -f "$SESSIONS_FILE" ] && jq empty "$SESSIONS_FILE" >/dev/null 2>&1; then
            main_id=$(jq -r '."agent:lore:main".sessionId // empty' "$SESSIONS_FILE")
        fi
        if [ -z "$main_id" ]; then
            return 0
        fi
        main_lock="$HOME/.openclaw/agents/lore/sessions/${main_id}.jsonl.lock"
        if [ ! -f "$main_lock" ]; then
            return 0
        fi
        sleep 5
        waited=$((waited + 5))
    done
    return 1
}

if ! wait_for_lore_main_unlock; then
    log "Lore main session lock remained active after ${LOCK_WAIT_SECONDS}s; deferring orchestration run (non-failure)."
    cat > "$HEALTH_FILE" <<EOT
{
  "status": "deferred",
  "reason": "lore_main_lock_timeout",
  "last_run": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "wait_seconds": ${LOCK_WAIT_SECONDS}
}
EOT
    exit 0
fi

log "Starting hourly orchestration run..."
if timeout --preserve-status 20m openclaw agent --local --agent "$LOOP_AGENT_ID" --message "Run one full orchestration cycle per LOOP.md. Delegate and persist state."; then
    log "Orchestration run completed successfully."
    cat > "$HEALTH_FILE" <<EOT
{
  "status": "healthy",
  "last_run": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "mode": "orchestration"
}
EOT
    exit 0
else
    rc=$?
    log "Orchestration run failed with exit code ${rc}."
    cat > "$HEALTH_FILE" <<EOT
{
  "status": "degraded",
  "last_run": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "mode": "orchestration",
  "exit_code": ${rc}
}
EOT
    exit "$rc"
fi
