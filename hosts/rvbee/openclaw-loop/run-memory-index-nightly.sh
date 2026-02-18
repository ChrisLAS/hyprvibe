#!/usr/bin/env bash
set -euo pipefail

PATH="/run/current-system/sw/bin:/usr/bin:/bin:${HOME}/.nix-profile/bin"

STATE_DIR="${HOME}/.openclaw/state"
WINDOW_STATE="${STATE_DIR}/memory-index-window-state.json"
VERIFY_STATE="${STATE_DIR}/memory-index-verify.json"
RUNNER_STATE="${STATE_DIR}/memory-index-runner-state.json"
LOCK_FILE="${STATE_DIR}/memory-index-nightly.lock"

MAX_MINUTES="${INDEX_MAX_MINUTES:-15}"
CPU_THRESHOLD="${INDEX_CPU_THRESHOLD:-300}"
COOLDOWN_MINUTES="${INDEX_COOLDOWN_MINUTES:-720}"
MAX_FAILURE_STREAK="${INDEX_MAX_FAILURE_STREAK:-2}"

BEADS_REPO="/home/chrisf/build/config"
BEADS_ISSUE="config-kkm"

log() {
  echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') [memory-index-nightly] $*"
  logger -t lore-memory-index "$*"
}

beads_note() {
  local msg="$1"
  if command -v bd >/dev/null 2>&1 && [[ -d "$BEADS_REPO/.beads" ]]; then
    (cd "$BEADS_REPO" && bd update "$BEADS_ISSUE" --notes "$msg") >/dev/null 2>&1 || true
  fi
}

mkdir -p "$STATE_DIR"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  log "Another nightly index run is active; skipping."
  exit 0
fi

started_at="$(date -Is)"
log "Starting guarded nightly memory index (max=${MAX_MINUTES}m, cpu=${CPU_THRESHOLD}, cooldown=${COOLDOWN_MINUTES}m)."

index_rc=0
if ! "${HOME}/.openclaw/scripts/index-memory" \
  --max-minutes "$MAX_MINUTES" \
  --cpu-threshold "$CPU_THRESHOLD" \
  --cooldown-minutes "$COOLDOWN_MINUTES"; then
  index_rc=$?
fi

verify_rc=0
if ! "${HOME}/.openclaw/scripts/verify-cognee-index.sh"; then
  verify_rc=$?
fi

window_status="unknown"
window_reason="unknown"
if [[ -f "$WINDOW_STATE" ]]; then
  window_status="$(jq -r '.status // "unknown"' "$WINDOW_STATE" 2>/dev/null || echo unknown)"
  window_reason="$(jq -r '.reason // "unknown"' "$WINDOW_STATE" 2>/dev/null || echo unknown)"
fi

verify_status="unknown"
if [[ -f "$VERIFY_STATE" ]]; then
  verify_status="$(jq -r '.status // "unknown"' "$VERIFY_STATE" 2>/dev/null || echo unknown)"
fi

healthy=true
failure_reason=""
if (( index_rc != 0 )); then
  healthy=false
  failure_reason="index_rc_${index_rc}:${window_reason}"
fi
if (( verify_rc != 0 )); then
  healthy=false
  if [[ -n "$failure_reason" ]]; then
    failure_reason+=";"
  fi
  failure_reason+="verify_rc_${verify_rc}:${verify_status}"
fi

previous_streak=0
if [[ -f "$RUNNER_STATE" ]]; then
  previous_streak="$(jq -r '.failure_streak // 0' "$RUNNER_STATE" 2>/dev/null || echo 0)"
fi

failure_streak=0
if [[ "$healthy" == true ]]; then
  failure_streak=0
else
  failure_streak=$((previous_streak + 1))
fi

now="$(date -Is)"
jq -n \
  --arg started_at "$started_at" \
  --arg ended_at "$now" \
  --arg window_state "$WINDOW_STATE" \
  --arg verify_state "$VERIFY_STATE" \
  --arg window_status "$window_status" \
  --arg verify_status "$verify_status" \
  --arg failure_reason "$failure_reason" \
  --argjson index_rc "$index_rc" \
  --argjson verify_rc "$verify_rc" \
  --argjson failure_streak "$failure_streak" \
  '{
    started_at: $started_at,
    ended_at: $ended_at,
    index_rc: $index_rc,
    verify_rc: $verify_rc,
    window_status: $window_status,
    verify_status: $verify_status,
    failure_reason: $failure_reason,
    failure_streak: $failure_streak,
    window_state: $window_state,
    verify_state: $verify_state
  }' > "$RUNNER_STATE"

if [[ "$healthy" == true ]]; then
  log "Nightly memory index healthy (window=${window_status}, verify=${verify_status})."
  beads_note "[memory-index] healthy run at ${now}; window=${window_status}; verify=${verify_status}; failure_streak reset to 0"
  exit 0
fi

log "Nightly memory index degraded (reason=${failure_reason}; streak=${failure_streak})."
beads_note "[memory-index] degraded run at ${now}; reason=${failure_reason}; window=${window_status}; verify=${verify_status}; failure_streak=${failure_streak}"

if (( failure_streak >= MAX_FAILURE_STREAK )); then
  log "Failure streak ${failure_streak} reached threshold ${MAX_FAILURE_STREAK}; disabling lore-memory-index.timer."
  systemctl --user disable --now lore-memory-index.timer >/dev/null 2>&1 || true
  beads_note "[memory-index] timer auto-disabled after consecutive failures; run 'systemctl --user enable --now lore-memory-index.timer' after remediation"
fi

exit 3
