#!/usr/bin/env bash
set -euo pipefail

URL="https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true"
resp="$(curl -fsS --max-time 3 "$URL" 2>/dev/null || true)"
if [[ -z "$resp" ]]; then
  echo "₿ ?"
  exit 0
fi
price=$(jq -r '.bitcoin.usd // empty' <<<"$resp" 2>/dev/null || true)
chg=$(jq -r '.bitcoin.usd_24h_change // empty' <<<"$resp" 2>/dev/null || true)
if [[ -z "$price" ]]; then
  echo "₿ ?"
  exit 0
fi
price_i=$(printf '%.0f' "$price")
chg_s=$(printf '%+.1f' "${chg:-0}")
echo "₿ ${price_i} (${chg_s}%)"

