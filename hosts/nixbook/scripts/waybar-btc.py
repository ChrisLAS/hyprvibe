#!/usr/bin/env python3
import json
import sys
import urllib.request

# Fetch BTC price (USD) from CoinDesk (no API key)
URL = "https://api.coindesk.com/v1/bpi/currentprice/BTC.json"

def main():
    try:
        with urllib.request.urlopen(URL, timeout=3) as resp:
            data = json.load(resp)
        rate = data["bpi"]["USD"]["rate_float"]
        text = f"₿ {rate:,.0f}"
        out = {"text": text, "tooltip": f"BTC/USD: {rate:,.2f}"}
        print(json.dumps(out))
    except Exception as e:
        print(json.dumps({"text": "₿ ?", "tooltip": f"BTC error: {e}"}))

if __name__ == "__main__":
    sys.exit(main())

