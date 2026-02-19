#!/usr/bin/env bash
# Heartbeat Loop Runner (lightweight, no-recall lane)

set -euo pipefail

WORKDIR="/home/chrisf/.openclaw/workspace-lore"
HEARTBEAT_WORKSPACE="/home/chrisf/.openclaw/workspace-heartbeat-agent"
CANONICAL_DOCS_DIR="/home/chrisf/code/clawdbot-local/documents"
CANONICAL_HEARTBEAT_FILE="$CANONICAL_DOCS_DIR/HEARTBEAT.md"
TARGET_HEARTBEAT_FILE="$HEARTBEAT_WORKSPACE/HEARTBEAT.md"
STATE_FILE="/home/chrisf/.openclaw/state/lore-loop.json"
HEALTH_FILE="$WORKDIR/health.json"
LOCK_FILE="$WORKDIR/lore-loop.lock"
GLOBAL_LOCK_FILE="/home/chrisf/.openclaw/state/lore-loop-global.lock"
FORCE_FILE="$WORKDIR/force-run"
SESSIONS_FILE="$HOME/.openclaw/agents/lore/sessions/sessions.json"
TIMER_OVERRIDE_DIR="$HOME/.config/systemd/user/lore-loop.timer.d"
TIMER_OVERRIDE_FILE="$TIMER_OVERRIDE_DIR/override.conf"
LOOP_AGENT_ID="heartbeat-agent"

export PATH="/run/wrappers/bin:/run/current-system/sw/bin:/usr/bin:/bin:$HOME/.nix-profile/bin"

log() {
    echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') [bash] $1"
    logger -t lore-loop "$1"
}

mkdir -p /home/chrisf/.openclaw/state

# Keep heartbeat instructions synced into the heartbeat-agent workspace.
if [ -f "$CANONICAL_HEARTBEAT_FILE" ]; then
    mkdir -p "$HEARTBEAT_WORKSPACE"
    cp -f "$CANONICAL_HEARTBEAT_FILE" "$TARGET_HEARTBEAT_FILE"
fi

# Local overlap protection
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    log "Another heartbeat instance is already running. Exiting."
    exit 0
fi

# Shared lane protection against orchestration overlap
exec 201>"$GLOBAL_LOCK_FILE"
if ! flock -n 201; then
    log "Global loop lock held (likely orchestration). Skipping heartbeat run."
    exit 0
fi

FORCED=false
if [ -f "$FORCE_FILE" ]; then
    log "Force-run file detected. Proceeding."
    rm "$FORCE_FILE"
    FORCED=true
fi

DEFAULT_CADENCE=15
CADENCE=$DEFAULT_CADENCE

if [ -f "$STATE_FILE" ] && jq empty "$STATE_FILE" >/dev/null 2>&1; then
    CADENCE=$(jq -r '.recommended_next_run_minutes // 15' "$STATE_FILE")
    if [ "$CADENCE" -lt 5 ]; then CADENCE=5; fi
    if [ "$CADENCE" -gt 120 ]; then CADENCE=120; fi
fi

log "Starting heartbeat loop..."
EXIT_CODE=0

MAIN_SESSION_ID=""
MAIN_SESSION_LOCK=""
if [ -f "$SESSIONS_FILE" ] && jq empty "$SESSIONS_FILE" >/dev/null 2>&1; then
    MAIN_SESSION_ID=$(jq -r '."agent:lore:main".sessionId // empty' "$SESSIONS_FILE")
fi
if [ -n "$MAIN_SESSION_ID" ]; then
    MAIN_SESSION_LOCK="$HOME/.openclaw/agents/lore/sessions/${MAIN_SESSION_ID}.jsonl.lock"
    if [ -f "$MAIN_SESSION_LOCK" ]; then
        log "Main Lore session lock active (${MAIN_SESSION_LOCK}); skipping HEARTBEAT run."
        EXIT_CODE=0
    fi
fi

if [ "$EXIT_CODE" -eq 0 ] && [ ! -f "${MAIN_SESSION_LOCK:-/nonexistent}" ]; then
    if ! timeout --preserve-status 8m openclaw agent --local --agent "$LOOP_AGENT_ID" --message "HEARTBEAT"; then
        EXIT_CODE=$?
        log "Heartbeat loop failed with exit code $EXIT_CODE. Setting retry cadence to 5m."
        CADENCE=5
    else
        log "Heartbeat loop completed successfully."
    fi
fi

mkdir -p "$TIMER_OVERRIDE_DIR"
CURRENT_OVERRIDE=""
if [ -f "$TIMER_OVERRIDE_FILE" ]; then
   CURRENT_OVERRIDE=$(grep "OnUnitActiveSec" "$TIMER_OVERRIDE_FILE" | cut -d'=' -f2 | sed 's/min//')
fi

if [ "$CADENCE" != "$CURRENT_OVERRIDE" ]; then
    log "Updating heartbeat timer cadence to ${CADENCE}m"
    cat > "$TIMER_OVERRIDE_FILE" <<EOT
[Timer]
OnUnitActiveSec=${CADENCE}min
EOT
    systemctl --user daemon-reload
fi

NEXT_RUN=$(date -u -d "+$CADENCE minutes" +'%Y-%m-%dT%H:%M:%SZ')
cat > "$HEALTH_FILE" <<EOT
{
  "status": "$([ $EXIT_CODE -eq 0 ] && echo "healthy" || echo "degraded")",
  "last_run": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "next_expected": "$NEXT_RUN",
  "cadence_minutes": $CADENCE,
  "mode": "heartbeat",
  "checks": {
    "loop_running_on_schedule": true
  }
}
EOT

exit $EXIT_CODE
