#!/usr/bin/env python3
import json
import os
import sys
import urllib.request

API_KEY = os.environ.get("COINMARKETCAPAPIKEY", "")
SYMBOLS = os.environ.get("CMC_SYMBOLS", "BTC,ETH").split(",")
CURRENCY = os.environ.get("CMC_CURRENCY", "USD")

URL = (
    "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol="
    + ",".join([s.strip().upper() for s in SYMBOLS])
    + "&convert="
    + CURRENCY
)

def main():
    if not API_KEY:
        print(json.dumps({"text": "CRYPTO?", "tooltip": "Set COINMARKETCAPAPIKEY"}))
        return 0
    try:
        req = urllib.request.Request(URL, headers={"X-CMC_PRO_API_KEY": API_KEY})
        with urllib.request.urlopen(req, timeout=4) as resp:
            data = json.load(resp)
        parts = []
        tip = []
        for sym in [s.strip().upper() for s in SYMBOLS]:
            q = data["data"][sym]["quote"][CURRENCY]
            price = q["price"]
            change = q["percent_change_24h"]
            parts.append(f"{sym} {price:,.0f}")
            tip.append(f"{sym}: {price:,.2f} ({change:+.2f}% 24h)")
        text = " | ".join(parts)
        tooltip = "\n".join(tip)
        print(json.dumps({"text": text, "tooltip": tooltip}))
    except Exception as e:
        print(json.dumps({"text": "CRYPTO?", "tooltip": f"CMC error: {e}"}))
    return 0

if __name__ == "__main__":
    sys.exit(main())

