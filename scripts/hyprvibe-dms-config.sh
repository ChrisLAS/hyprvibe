#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: hyprvibe-dms-config {diff|export} [--repo PATH] [--bar-id ID]" >&2
  exit 2
}

action="${1:-}"
case "$action" in
  diff|export) shift ;;
  *) usage ;;
esac

repo=""
bar_id="${HYPRVIBE_DMS_EXPORT_BAR_ID:-default}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      [ "$#" -ge 2 ] || usage
      repo="$2"
      shift 2
      ;;
    --bar-id)
      [ "$#" -ge 2 ] || usage
      bar_id="$2"
      shift 2
      ;;
    *) usage ;;
  esac
done

if [ -z "$repo" ]; then
  repo="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -n "$repo" ] && [ -d "$repo/.git" ] || {
  echo "Run inside the hyprvibe repository or pass --repo PATH." >&2
  exit 1
}

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell"
settings="$config_dir/settings.json"
plugins="$config_dir/plugin_settings.json"
portable="$repo/configs/dms/portable-settings.json"
bar_template="$repo/configs/dms/bar-template.json"
plugin_profile="$repo/configs/dms/plugin-settings.json"

for file in "$settings" "$plugins" "$portable" "$bar_template" "$plugin_profile"; do
  [ -f "$file" ] || { echo "Missing required file: $file" >&2; exit 1; }
  jq -e . "$file" >/dev/null
done

tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "$tmp_dir"' EXIT

jq --slurpfile profile "$portable" \
  'with_entries(select(.key as $key | $profile[0] | has($key)))' \
  "$settings" > "$tmp_dir/portable-settings.json"

jq --arg id "$bar_id" '
  [.barConfigs[] | select(.id == $id)] as $matches
  | if ($matches | length) != 1 then
      error("expected exactly one bar with id=" + $id)
    else
      $matches[0] | del(.id, .name, .screenPreferences, .showOnLastDisplay)
    end
' "$settings" > "$tmp_dir/bar-template.json"

jq --slurpfile profile "$plugin_profile" \
  'with_entries(select(.key as $key | $profile[0] | has($key)))' \
  "$plugins" > "$tmp_dir/plugin-settings.json"

if [ "$action" = diff ]; then
  for name in portable-settings.json bar-template.json plugin-settings.json; do
    diff -u "$repo/configs/dms/$name" "$tmp_dir/$name" || true
  done
  exit 0
fi

for name in portable-settings.json bar-template.json plugin-settings.json; do
  install -m0644 "$tmp_dir/$name" "$repo/configs/dms/$name"
done

git -C "$repo" diff -- configs/dms
