#!/usr/bin/env bash
set -euo pipefail

MAX_MINUTES=20
CPU_THRESHOLD=300
COOLDOWN_MINUTES=120
FORCE=0

OPENCLAW_CONFIG="${HOME}/.openclaw/openclaw.json"
STATE_DIR="${HOME}/.openclaw/state"
LOCK_FILE="${STATE_DIR}/memory-index-window.lock"
STATE_FILE="${STATE_DIR}/memory-index-window-state.json"
META_FILE="${STATE_DIR}/memory-index-window-meta.json"

usage() {
  cat <<'EOF'
Usage: memory_index_window.sh [--max-minutes N] [--cpu-threshold N] [--cooldown-minutes N] [--force]

Runs a bounded Cognee indexing window by temporarily enabling:
  plugins.entries.memory-cognee.config.autoIndex = true

Guardrails:
  - lockfile to avoid concurrent runs
  - cooldown between successful runs
  - rollback if ollama runner CPU is high for 3 consecutive samples
  - rollback if memory-cognee error count exceeds threshold
  - always restores autoIndex=false on exit
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-minutes)
      MAX_MINUTES="${2:-}"
      shift 2
      ;;
    --cpu-threshold)
      CPU_THRESHOLD="${2:-}"
      shift 2
      ;;
    --cooldown-minutes)
      COOLDOWN_MINUTES="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

for v in "$MAX_MINUTES" "$CPU_THRESHOLD" "$COOLDOWN_MINUTES"; do
  if ! [[ "$v" =~ ^[0-9]+$ ]]; then
    echo "Numeric arguments must be integers." >&2
    exit 2
  fi
done

PATH="/run/wrappers/bin:/run/current-system/sw/bin:/usr/bin:/bin:${HOME}/.nix-profile/bin"

mkdir -p "$STATE_DIR"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "Another memory index window is already running." >&2
  exit 2
fi

started_at="$(date -Is)"
start_human="$(date '+%Y-%m-%d %H:%M:%S')"
rollback_reason=""
enabled_autoindex=0

log() {
  echo "[$(date '+%H:%M:%S')] $*"
}

write_state_and_exit() {
  local status="$1"
  local reason="$2"
  local rc="$3"
  local now
  now="$(date -Is)"
  jq -n \
    --arg started_at "$started_at" \
    --arg ended_at "$now" \
    --arg status "$status" \
    --arg reason "$reason" \
    --arg autoIndex_now "$(jq -r '.plugins.entries["memory-cognee"].config.autoIndex // "unknown"' "$OPENCLAW_CONFIG" 2>/dev/null || echo unknown)" \
    '{
      started_at: $started_at,
      ended_at: $ended_at,
      status: $status,
      reason: $reason,
      autoIndex_now: $autoIndex_now
    }' > "$STATE_FILE"
  cat "$STATE_FILE"
  exit "$rc"
}

json_summary() {
  local status="$1"
  local reason="$2"
  local duration_s="$3"
  local max_runner_cpu="$4"
  local errors="$5"
  local sync_events="$6"
  local autoindex_now="$7"
  jq -n \
    --arg started_at "$started_at" \
    --arg ended_at "$(date -Is)" \
    --arg status "$status" \
    --arg reason "$reason" \
    --argjson duration_s "$duration_s" \
    --argjson max_runner_cpu "$max_runner_cpu" \
    --argjson errors "$errors" \
    --argjson sync_events "$sync_events" \
    --arg autoindex_now "$autoindex_now" \
    '{
      started_at: $started_at,
      ended_at: $ended_at,
      status: $status,
      reason: $reason,
      duration_s: $duration_s,
      max_runner_cpu: $max_runner_cpu,
      errors: $errors,
      sync_events: $sync_events,
      autoIndex_now: $autoindex_now
    }'
}

set_autoindex_and_restart() {
  local value="$1"
  jq ".plugins.entries[\"memory-cognee\"].config.autoIndex=${value}" "$OPENCLAW_CONFIG" > "${OPENCLAW_CONFIG}.tmp"
  mv "${OPENCLAW_CONFIG}.tmp" "$OPENCLAW_CONFIG"
  systemctl --user restart openclaw-gateway
}

count_matches() {
  local pattern="$1"
  local n
  n="$(journalctl --user -u openclaw-gateway --since "$start_human" --no-pager | rg -c "$pattern" || true)"
  if [[ -z "$n" ]]; then
    n=0
  fi
  echo "$n"
}

check_root_service_active() {
  local service="$1"
  if systemctl is-active --quiet "$service"; then
    return 0
  fi
  if command -v sudo >/dev/null 2>&1 && sudo -n systemctl is-active --quiet "$service" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

cleanup() {
  if [[ "$enabled_autoindex" -eq 1 ]]; then
    log "Ensuring autoIndex=false and restarting gateway."
    set +e
    set_autoindex_and_restart false >/dev/null 2>&1
    set -e
    enabled_autoindex=0
  fi
}
trap cleanup EXIT INT TERM

if [[ ! -f "$OPENCLAW_CONFIG" ]]; then
  echo "Config not found: $OPENCLAW_CONFIG" >&2
  exit 2
fi

if ! systemctl --user is-active --quiet openclaw-gateway; then
  write_state_and_exit "preflight_failed" "openclaw_gateway_inactive" 2
fi

if ! check_root_service_active "podman-cognee.service"; then
  write_state_and_exit "preflight_failed" "podman_cognee_inactive_or_inaccessible" 2
fi

if ! check_root_service_active "podman-ollama.service"; then
  write_state_and_exit "preflight_failed" "podman_ollama_inactive_or_inaccessible" 2
fi

plugin_enabled="$(jq -r '.plugins.entries["memory-cognee"].enabled // false' "$OPENCLAW_CONFIG")"
if [[ "$plugin_enabled" != "true" ]]; then
  write_state_and_exit "preflight_failed" "memory_cognee_plugin_disabled" 2
fi

autoindex_now="$(jq -r '.plugins.entries["memory-cognee"].config.autoIndex // false' "$OPENCLAW_CONFIG")"
if [[ "$autoindex_now" != "false" ]]; then
  write_state_and_exit "preflight_failed" "autoindex_already_true" 2
fi

if [[ "$FORCE" -eq 0 && -f "$META_FILE" ]]; then
  last_success="$(jq -r '.last_success_epoch // 0' "$META_FILE" 2>/dev/null || echo 0)"
  now_epoch="$(date +%s)"
  min_gap="$((COOLDOWN_MINUTES * 60))"
  elapsed="$((now_epoch - last_success))"
  if [[ "$elapsed" -lt "$min_gap" ]]; then
    write_state_and_exit "preflight_failed" "cooldown_active" 2
  fi
fi

log "Starting manual index window (max=${MAX_MINUTES}m, cpu-threshold=${CPU_THRESHOLD}%)."
set_autoindex_and_restart true
enabled_autoindex=1

max_runner_cpu=0
high_streak=0
error_cap=8
final_errors=0
final_sync=0

for minute in $(seq 1 "$MAX_MINUTES"); do
  runner_cpu="$(ps -eo pcpu,cmd | awk '/ollama runner/ && !/awk/ {sum+=$1} END {if(sum=="") sum=0; printf "%.1f", sum}')"
  gw_cpu="$(ps -eo pcpu,cmd | awk '/openclaw-gateway/ && !/awk/ {sum+=$1} END {if(sum=="") sum=0; printf "%.1f", sum}')"
  final_errors="$(count_matches 'memory-cognee: (failed to sync|recall failed|cognify failed|auto-sync failed|post-agent sync failed)')"
  final_sync="$(count_matches 'memory-cognee: (detected .* changed file|auto-sync complete|post-agent sync|added )')"

  cpu_int="${runner_cpu%.*}"
  if (( cpu_int >= CPU_THRESHOLD )); then
    high_streak=$((high_streak + 1))
  else
    high_streak=0
  fi

  if awk -v a="$runner_cpu" -v b="$max_runner_cpu" 'BEGIN{exit !(a>b)}'; then
    max_runner_cpu="$runner_cpu"
  fi

  log "minute=${minute} runner_cpu=${runner_cpu} gateway_cpu=${gw_cpu} errors=${final_errors} sync_events=${final_sync} high_streak=${high_streak}"

  if (( high_streak >= 3 )); then
    rollback_reason="sustained_runner_cpu"
    break
  fi

  if (( final_errors >= error_cap )); then
    rollback_reason="error_cap_exceeded"
    break
  fi

  sleep 60
done

set_autoindex_and_restart false
enabled_autoindex=0

end_epoch="$(date +%s)"
start_epoch="$(date --date="$started_at" +%s)"
duration_s="$((end_epoch - start_epoch))"
autoindex_final="$(jq -r '.plugins.entries["memory-cognee"].config.autoIndex // false' "$OPENCLAW_CONFIG")"

if [[ -n "$rollback_reason" ]]; then
  summary="$(json_summary "rolled_back" "$rollback_reason" "$duration_s" "$max_runner_cpu" "$final_errors" "$final_sync" "$autoindex_final")"
  echo "$summary" | tee "$STATE_FILE"
  exit 3
fi

summary="$(json_summary "ok" "window_completed" "$duration_s" "$max_runner_cpu" "$final_errors" "$final_sync" "$autoindex_final")"
echo "$summary" | tee "$STATE_FILE"

now_epoch="$(date +%s)"
jq -n \
  --argjson last_success_epoch "$now_epoch" \
  --argjson last_run_epoch "$now_epoch" \
  --argjson max_runner_cpu "$max_runner_cpu" \
  --argjson errors "$final_errors" \
  --argjson sync_events "$final_sync" \
  '{last_success_epoch:$last_success_epoch,last_run_epoch:$last_run_epoch,max_runner_cpu:$max_runner_cpu,errors:$errors,sync_events:$sync_events}' \
  > "$META_FILE"

exit 0
