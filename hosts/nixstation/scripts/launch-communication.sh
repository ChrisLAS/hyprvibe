#!/usr/bin/env bash
set -euo pipefail

# Simple launcher for Slack and Telegram
# Launch Telegram first, wait 1 second, then launch Slack

Telegram &
sleep 1
slack &
