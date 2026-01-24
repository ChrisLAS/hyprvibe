#!/usr/bin/env bash
# Run script for NixOS systems

# Check if OPENROUTER_API_KEY is set
if [ -z "$OPENROUTER_API_KEY" ]; then
    echo "Error: OPENROUTER_API_KEY environment variable is not set."
    echo "Get your API key from: https://openrouter.ai/keys"
    echo "Then run: export OPENROUTER_API_KEY='your-key-here'"
    exit 1
fi

# Run with nix-shell
exec nix-shell -p python3Packages.feedparser python3Packages.requests --run "python3 $@"
