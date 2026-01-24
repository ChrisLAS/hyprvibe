#!/usr/bin/env bash
# Test OpenRouter API using nix-shell on NixOS

# Check if OPENROUTER_API_KEY is set
if [ -z "$OPENROUTER_API_KEY" ]; then
    echo "Error: OPENROUTER_API_KEY environment variable is not set."
    echo "Get your API key from: https://openrouter.ai/keys"
    echo "Then run: export OPENROUTER_API_KEY='your-key-here'"
    exit 1
fi

# Run test with nix-shell
exec nix-shell -p python3Packages.requests --run "python3 test_openrouter.py"
