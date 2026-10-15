#!/usr/bin/env python3
"""Attach Nix-managed OpenCode clients to a named hosted backend by default."""
import json
import os
from pathlib import Path
import subprocess
import sys

SERVER_COMMANDS = {
    'acp', 'api', 'auth', 'console', 'debug', 'export', 'import', 'mcp',
    'mini', 'models', 'pair', 'plugin', 'reload', 'run', 'session', 'stats',
}


def read_credential(path, key):
    try:
        text = Path(path).read_text()
    except PermissionError:
        # Showfactory's pairing credential belongs to its service account.
        result = subprocess.run(
            ['/run/wrappers/bin/sudo', '-n', '-u', 'hermes', '--',
             sys.executable, '-c',
             'from pathlib import Path; import sys; print(Path(sys.argv[1]).read_text(), end="")',
             path], check=True, capture_output=True, text=True,
        )
        text = result.stdout
    if path.endswith('.json'):
        value = json.loads(text)[key]
    else:
        entries = [line.split('=', 1)[1].strip() for line in text.splitlines()
                   if line.startswith(key + '=')]
        if len(entries) != 1:
            raise ValueError(f'expected exactly one {key} entry in {path}')
        value = entries[0]
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
    if not isinstance(value, str) or not value or '\n' in value or '\r' in value:
        raise ValueError(f'empty or invalid credential in {path}')
    return value


def launch(binary, server, credential, key, directory, arguments):
    env = os.environ.copy()
    explicit = any(arg == '--standalone' or arg == '--server' or arg.startswith('--server=')
                   for arg in arguments)
    informational = arguments and arguments[0] in {'--help', '-h', '--version', '-v'}
    paths = arguments[:2] == ['debug', 'paths']
    if explicit or informational or paths:
        os.execvpe(binary, [binary, *arguments], env)
        return
    if arguments and arguments[0] in {'upgrade', 'update', 'uninstall'}:
        raise ValueError('OpenCode is Nix-managed; update its pinned package in the host configuration')
    if arguments and arguments[0] in {'service', 'serve'}:
        raise ValueError('the hosted backend is systemd-managed; use --standalone for an intentional private server')
    password = read_credential(credential, key)
    env['OPENCODE_SERVER_USERNAME'] = 'opencode'
    env['OPENCODE_SERVER_PASSWORD'] = password
    # Nomad's existing server and older V2 clients also use this name.
    env['OPENCODE_PASSWORD'] = password
    if directory:
        os.chdir(directory)
    if arguments and arguments[0] in SERVER_COMMANDS:
        argv = [binary, arguments[0], '--server', server, *arguments[1:]]
    else:
        argv = [binary, '--server', server, *arguments]
    os.execvpe(binary, argv, env)


def main():
    if len(sys.argv) < 6:
        raise ValueError('launcher requires binary, server, credential path, key, and project directory')
    launch(*sys.argv[1:6], sys.argv[6:])


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        # Never include captured stdout: the privileged reader carries secrets.
        print(f'OpenCode launcher: {type(error).__name__}: connection setup failed; check the configured credential and project paths', file=sys.stderr)
        sys.exit(1)
