#!/usr/bin/env bash
set -euo pipefail

DOCS_DIR="${MEMORY_DOCS_DIR:-/home/chrisf/code/clawdbot-local/documents}"
SYNC_INDEX="${SYNC_INDEX_PATH:-${HOME}/.openclaw/memory/cognee/sync-index.json}"
STATE_DIR="${HOME}/.openclaw/state"
OUT_JSON="${STATE_DIR}/memory-index-verify.json"

mkdir -p "$STATE_DIR"

if [[ ! -d "$DOCS_DIR" ]]; then
  echo "verify-cognee-index: docs directory not found: $DOCS_DIR" >&2
  exit 2
fi

if [[ ! -f "$SYNC_INDEX" ]]; then
  echo "verify-cognee-index: sync-index not found: $SYNC_INDEX" >&2
  exit 2
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

(
  cd "$DOCS_DIR"
  if [[ -f MEMORY.md ]]; then
    echo "MEMORY.md"
  fi
  if [[ -d memory ]]; then
    find memory -type f -name '*.md' | sort
  fi
) > "$tmpdir/expected.txt"

jq -r '.entries | keys[]' "$SYNC_INDEX" | sort > "$tmpdir/indexed.txt"

comm -23 "$tmpdir/expected.txt" "$tmpdir/indexed.txt" > "$tmpdir/missing.txt"
comm -13 "$tmpdir/expected.txt" "$tmpdir/indexed.txt" > "$tmpdir/stale.txt"

: > "$tmpdir/mismatch.txt"
while IFS= read -r rel; do
  [[ -z "$rel" ]] && continue
  file_path="$DOCS_DIR/$rel"
  [[ -f "$file_path" ]] || continue

  expected_hash="$(sha256sum "$file_path" | awk '{print $1}')"
  indexed_hash="$(jq -r --arg p "$rel" '.entries[$p].hash // ""' "$SYNC_INDEX")"

  if [[ "$expected_hash" != "$indexed_hash" ]]; then
    echo "$rel" >> "$tmpdir/mismatch.txt"
  fi
done < "$tmpdir/expected.txt"

json_array() {
  local src="$1"
  jq -R -s 'split("\n") | map(select(length>0))' < "$src"
}

expected_count="$(wc -l < "$tmpdir/expected.txt")"
indexed_count="$(wc -l < "$tmpdir/indexed.txt")"
missing_count="$(wc -l < "$tmpdir/missing.txt")"
stale_count="$(wc -l < "$tmpdir/stale.txt")"
mismatch_count="$(wc -l < "$tmpdir/mismatch.txt")"

status="ok"
if (( missing_count > 0 || stale_count > 0 || mismatch_count > 0 )); then
  status="drift"
fi

jq -n \
  --arg status "$status" \
  --arg docs_dir "$DOCS_DIR" \
  --arg sync_index "$SYNC_INDEX" \
  --arg checked_at "$(date -Is)" \
  --argjson expected_count "$expected_count" \
  --argjson indexed_count "$indexed_count" \
  --argjson missing_count "$missing_count" \
  --argjson stale_count "$stale_count" \
  --argjson mismatch_count "$mismatch_count" \
  --argjson missing_paths "$(json_array "$tmpdir/missing.txt")" \
  --argjson stale_paths "$(json_array "$tmpdir/stale.txt")" \
  --argjson hash_mismatch_paths "$(json_array "$tmpdir/mismatch.txt")" \
  '{
    checked_at: $checked_at,
    status: $status,
    docs_dir: $docs_dir,
    sync_index: $sync_index,
    expected_count: $expected_count,
    indexed_count: $indexed_count,
    missing_count: $missing_count,
    stale_count: $stale_count,
    hash_mismatch_count: $mismatch_count,
    missing_paths: $missing_paths,
    stale_paths: $stale_paths,
    hash_mismatch_paths: $hash_mismatch_paths
  }' > "$OUT_JSON"

cat "$OUT_JSON"

if [[ "$status" != "ok" ]]; then
  exit 4
fi

exit 0
