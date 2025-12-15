#!/usr/bin/env bash
set -euo pipefail

# Try multiple providers to get public IP
get_ip() {
  curl -fsS --max-time 2 https://api.ipify.org && return 0
  curl -fsS --max-time 2 https://ifconfig.me && return 0
  curl -fsS --max-time 2 https://icanhazip.com && return 0
  return 1
}

ip="$(get_ip 2>/dev/null || true)"
if [[ -z "${ip:-}" ]];
then
  echo '{"text":"IP: ?","tooltip":"Public IP unavailable"}'
else
  ip_trimmed="${ip//$'\n'/}"
  echo "{\"text\": \"IP: ${ip_trimmed}\", \"tooltip\": \"Public IP: ${ip_trimmed}\"}"
fi

