#!/usr/bin/env bash
set -euo pipefail

# Get geolocation by IP and then weather in Fahrenheit
# Providers kept simple and low-frequency to avoid rate limits.

geo_json=$(curl -fsS --max-time 2 https://ipapi.co/json/ 2>/dev/null || true)
if [[ -z "${geo_json}" ]]; then
  echo '{"text":"󰖐 ?°F","tooltip":"Weather unavailable"}'
  exit 0
fi

city=$(jq -r '.city // empty' <<<"${geo_json}" 2>/dev/null || true)
lat=$(jq -r '.latitude // empty' <<<"${geo_json}" 2>/dev/null || true)
lon=$(jq -r '.longitude // empty' <<<"${geo_json}" 2>/dev/null || true)

if [[ -z "${lat}" || -z "${lon}" ]]; then
  echo '{"text":"󰖐 ?°F","tooltip":"Weather location unavailable"}'
  exit 0
fi

# Use open-meteo free API (no key). Request Fahrenheit units.
weather_json=$(curl -fsS --max-time 3 "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,apparent_temperature,precipitation,weather_code&hourly=temperature_2m&temperature_unit=fahrenheit&timezone=auto" 2>/dev/null || true)

if [[ -z "${weather_json}" ]]; then
  echo '{"text":"󰖐 ?°F","tooltip":"Weather request failed"}'
  exit 0
fi

temp=$(jq -r '.current.temperature_2m // empty' <<<"${weather_json}" 2>/dev/null || true)
appt=$(jq -r '.current.apparent_temperature // empty' <<<"${weather_json}" 2>/dev/null || true)
code=$(jq -r '.current.weather_code // empty' <<<"${weather_json}" 2>/dev/null || true)

icon="󰖐"
case "${code}" in
  0) icon="󰖙" ;;
  1|2|3) icon="󰖐" ;;
  45|48) icon="󰖑" ;;
  51|53|55) icon="󰖐" ;;
  61|63|65) icon="󰖗" ;;
  71|73|75) icon="󰖘" ;;
  80|81|82) icon="󰖗" ;;
  95|96|99) icon="󰖓" ;;
esac

text="${icon} ${temp:-?}°F"
tooltip="${city:-Weather}: ${temp:-?}°F (feels ${appt:-?}°F)"

printf '{"text":"%s","tooltip":"%s"}\n' "$text" "$tooltip"

