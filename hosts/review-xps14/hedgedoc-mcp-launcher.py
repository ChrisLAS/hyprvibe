"""Launch Zed's HedgeDoc MCP without storing credentials in the Nix store."""

import os
from pathlib import Path
import sys

credential = Path.home() / ".config/secrets/hdocs"
try:
    entries = credential.read_text(encoding="utf-8").splitlines()
except (OSError, UnicodeError):
    sys.exit("HedgeDoc MCP: could not read the credential file")
if len(entries) != 2 or not all(entries) or "@" not in entries[0]:
    sys.exit("HedgeDoc MCP: expected email and password on separate lines")
env = os.environ.copy()
for key in list(env):
    if key.startswith("HEDGEDOC_"):
        del env[key]
env.update({
    "HEDGEDOC_URL": "https://h.docs.lol",
    "HEDGEDOC_EMAIL": entries[0],
    "HEDGEDOC_PASSWORD": entries[1],
})
try:
    os.execve(sys.argv[1], [sys.argv[1]], env)
except OSError:
    sys.exit("HedgeDoc MCP: cannot start the installed server")
