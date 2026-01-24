#!/usr/bin/env bash
set -euo pipefail

# OpenRouter Credits Widget for Waybar
# Reads API key from ~/.config/secrets/openrouter_api_key
# Displays remaining credit balance with brain emoji prefix

API_KEY_FILE="$HOME/.config/secrets/openrouter_api_key"

# Check if API key file exists
if [[ ! -r "$API_KEY_FILE" ]]; then
  printf '{"text":"🧠 $??.??","tooltip":"API key not found at %s"}\n' "$API_KEY_FILE"
  exit 0
fi

API_KEY=$(tr -d '\n' < "$API_KEY_FILE")

# Fetch credits from OpenRouter API
response=$(curl -fsS --max-time 5 \
  -H "Authorization: Bearer $API_KEY" \
  "https://openrouter.ai/api/v1/credits" 2>/dev/null || true)

if [[ -z "$response" ]]; then
  echo '{"text":"🧠 $??.??","tooltip":"API request failed"}'
  exit 0
fi

# Parse JSON response
total_credits=$(jq -r '.data.total_credits // empty' <<<"$response" 2>/dev/null || true)
total_usage=$(jq -r '.data.total_usage // empty' <<<"$response" 2>/dev/null || true)

if [[ -z "$total_credits" || -z "$total_usage" ]]; then
  echo '{"text":"🧠 $??.??","tooltip":"Invalid API response"}'
  exit 0
fi

# Calculate remaining balance using awk (more portable than bc)
remaining=$(awk "BEGIN {printf \"%.2f\", $total_credits - $total_usage}" 2>/dev/null || true)

if [[ -z "$remaining" ]]; then
  echo '{"text":"🧠 $??.??","tooltip":"Calculation error"}'
  exit 0
fi

# Format values for tooltip
usage_formatted=$(awk "BEGIN {printf \"%.2f\", $total_usage}" 2>/dev/null)
credits_formatted=$(awk "BEGIN {printf \"%.2f\", $total_credits}" 2>/dev/null)

text="🧠 \$$remaining"
tooltip="OpenRouter Credits: \$$remaining remaining\\nTotal: \$$credits_formatted | Used: \$$usage_formatted"

printf '{"text":"%s","tooltip":"%s"}\n' "$text" "$tooltip"
