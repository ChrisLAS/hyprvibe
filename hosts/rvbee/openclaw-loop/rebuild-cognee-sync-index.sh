#!/usr/bin/env bash
set -euo pipefail

PATH="/run/wrappers/bin:/run/current-system/sw/bin:/usr/bin:/bin:${HOME}/.nix-profile/bin"

DOCS_DIR="${MEMORY_DOCS_DIR:-/home/chrisf/code/clawdbot-local/documents}"
SYNC_DIR="${HOME}/.openclaw/memory/cognee"
SYNC_INDEX="${SYNC_DIR}/sync-index.json"
BACKUP_DIR="${SYNC_DIR}/backups"
STATE_DIR="${HOME}/.openclaw/state"
VERIFY_SCRIPT="${HOME}/.openclaw/scripts/verify-cognee-index.sh"

mkdir -p "$BACKUP_DIR" "$STATE_DIR"

ts="$(date +%Y%m%d-%H%M%S)"
backup_path="${BACKUP_DIR}/sync-index.reconcile-${ts}.json"

if [[ -f "$SYNC_INDEX" ]]; then
  cp -f "$SYNC_INDEX" "$backup_path"
else
  echo "Warning: sync-index missing, creating fresh index."
fi

cat > "$SYNC_INDEX" <<'JSON'
{
  "entries": {}
}
JSON

echo "Rebuilt local sync-index baseline at: $SYNC_INDEX"
echo "Backup stored at: $backup_path"

if ! systemctl --user is-active --quiet openclaw-gateway; then
  echo "openclaw-gateway is inactive; starting it."
  systemctl --user start openclaw-gateway
fi

systemctl --user restart openclaw-gateway

for _ in $(seq 1 60); do
  if rg -q 'memory-cognee: (auto-sync complete|added|updated)' /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log 2>/dev/null; then
    break
  fi
  sleep 2
done

"$VERIFY_SCRIPT" || true
cat "${STATE_DIR}/memory-index-verify.json"

