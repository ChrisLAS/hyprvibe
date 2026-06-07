#!/usr/bin/env bash
set -euo pipefail

exec /run/current-system/sw/bin/flatpak run md.obsidian.Obsidian "$@"
