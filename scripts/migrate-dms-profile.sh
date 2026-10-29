#!/usr/bin/env bash
# Dux 2 renamed its XDG directories. Copy only into absent destinations;
# preserve both the legacy profile and any already-created current profile.
set -euo pipefail

if [[ $# != 1 || "$1" != /* || "$1" == / ]]; then
  echo "Usage: migrate-dms-profile.sh /absolute/user/home" >&2
  exit 64
fi

staging=""
cleanup() {
  if [[ -n "$staging" ]]; then
    rm -rf -- "$staging"
  fi
}
trap cleanup EXIT

for base in "$1/.config" "$1/.local/state"; do
  legacy="$base/DankMaterialShell"
  current="$base/dms"
  if [[ ! -e "$current" && -d "$legacy" ]]; then
    # ENOSPC must not leave a partial profile that looks already migrated.
    staging="$(mktemp -d "$base/.dms-migration.XXXXXX")"
    cp -a "$legacy/." "$staging/"
    mv -T --no-clobber "$staging" "$current"
    cleanup
    staging=""
  fi
done
