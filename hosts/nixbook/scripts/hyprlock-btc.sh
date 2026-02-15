#!/usr/bin/env bash
set -euo pipefail

# Use full paths for hyprlock's minimal environment
CURL="/run/current-system/sw/bin/curl"
JQ="/run/current-system/sw/bin/jq"
CACHE_FILE="/tmp/btc-price-cache.json"
CACHE_MAX_AGE=300  # 5 minutes cache to avoid rate limiting

# Check if cache exists and is fresh
if [[ -f "$CACHE_FILE" ]]; then
  cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
  if [[ $cache_age -lt $CACHE_MAX_AGE ]]; then
    resp=$(cat "$CACHE_FILE")
  else
    # Cache expired, fetch new data
    URL="https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true"
    resp="$("$CURL" -fsS --max-time 3 "$URL" 2>/dev/null || true)"
    if [[ -n "$resp" ]]; then
      echo "$resp" > "$CACHE_FILE"
    else
      # API failed, use stale cache if available
      resp=$(cat "$CACHE_FILE" 2>/dev/null || echo "")
    fi
  fi
else
  # No cache, fetch new data
  URL="https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true"
  resp="$("$CURL" -fsS --max-time 3 "$URL" 2>/dev/null || true)"
  if [[ -n "$resp" ]]; then
    echo "$resp" > "$CACHE_FILE"
  fi
fi

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

# Format price with comma separator for readability at $100k+
if (( $(printf '%.0f' "$price") >= 100000 )); then
  price_formatted=$(printf '%'"'"'d' $(printf '%.0f' "$price"))
else
  price_formatted=$(printf '%.0f' "$price")
fi

chg_s=$(printf '%+.1f' "${chg:-0}")
echo "₿ ${price_formatted} (${chg_s}%)"

