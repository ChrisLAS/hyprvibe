#!/usr/bin/env bash
set -euo pipefail

# Use full paths for hyprlock's minimal environment
CURL="/run/current-system/sw/bin/curl"
JQ="/run/current-system/sw/bin/jq"

URL="https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true"
resp="$("$CURL" -fsS --max-time 3 "$URL" 2>/dev/null || true)"
if [[ -z "$resp" ]]; then
  echo "₿ ?"
  exit 0
fi
price=$("$JQ" -r '.bitcoin.usd // empty' <<<"$resp" 2>/dev/null || true)
chg=$("$JQ" -r '.bitcoin.usd_24h_change // empty' <<<"$resp" 2>/dev/null || true)
if [[ -z "$price" ]]; then
  echo "₿ ?"
  exit 0
fi
price_i=$(printf '%.0f' "$price")
chg_s=$(printf '%+.1f' "${chg:-0}")
echo "₿ ${price_i} (${chg_s}%)"

