#!/usr/bin/env python3
"""Reproduce Dux IPC path failures with the actual pinned Go toolchain.

Only the upstream fakeServer helper is extracted for the focused executable
fixture. The patch is also applied to a full copy of the upstream test file,
and every original test function must remain byte-identical. No desktop,
external network, module downloads, mount or daemon changes are involved.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile


def helper(source):
    return "func fakeServer" + source.split("func fakeServer", 1)[1].split("\nfunc TestServerRequest", 1)[0]


def run(go, source, directory, build_root, cache):
    directory.mkdir()
    (directory / "socket_test.go").write_text('''package ipcfixture
import ("net"; "os"; "path/filepath"; "testing")
var _ = os.ErrNotExist
''' + helper(source) + '''
func TestServerRequestTimesOutWithoutGreeting(t *testing.T) { fakeServer(t, func(net.Conn) {}) }
func TestServerRequestReportsClosedConnection(t *testing.T) { fakeServer(t, func(net.Conn) {}) }
''')
    env = {**os.environ, "TMPDIR": str(build_root), "GOTMPDIR": str(build_root),
           "GOCACHE": str(cache), "GO111MODULE": "off", "GOTOOLCHAIN": "local",
           "GOENV": "off", "GOFLAGS": "-p=2", "GOMAXPROCS": "2", "CGO_ENABLED": "0"}
    return subprocess.run([str(go), "test", "-count=1", "-v"], cwd=directory,
                          env=env, text=True, capture_output=True, timeout=120)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--go", type=Path, required=True)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--patch", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args()
    args.evidence.mkdir(parents=True, exist_ok=True)
    original = (args.source / "cmd/dms/server_client_test.go").read_text()
    digest = hashlib.sha256(original.encode()).hexdigest()
    with tempfile.TemporaryDirectory(prefix="dux-ipc-", dir="/tmp/opencode") as root:
        root = Path(root)
        build_root = root / "long-builder-123456789"
        build_root.mkdir()
        # Match the observed failure geometry while retaining an executable
        # directory for Go. The short-prefix patched socket must still fit.
        assert 45 <= len(str(build_root)) <= 65, str(build_root)
        copy = root / "source"
        target = copy / "cmd/dms/server_client_test.go"
        target.parent.mkdir(parents=True)
        target.write_text(original)
        subprocess.run(["patch", "--batch", "--fuzz=0", "-p1", "-i", str(args.patch.resolve())],
                       cwd=copy, check=True)
        patched = target.read_text()
        assert original.split("\nfunc TestServerRequest", 1)[1] == patched.split("\nfunc TestServerRequest", 1)[1], "An upstream test assertion changed"
        cache = root / "go-cache"
        before = run(args.go, original, root / "before", build_root, cache)
        (args.evidence / "unpatched.log").write_text(before.stdout + before.stderr)
        assert before.returncode != 0 and "bind: invalid argument" in before.stdout + before.stderr, "Original Go failure not reproduced"
        after = run(args.go, patched, root / "after", build_root, cache)
        (args.evidence / "patched.log").write_text(after.stdout + after.stderr)
        assert after.returncode == 0, after.stdout + after.stderr
        for name in ("TestServerRequestTimesOutWithoutGreeting", "TestServerRequestReportsClosedConnection"):
            assert "--- PASS: " + name in after.stdout
        assert "SKIP" not in after.stdout
        assert hashlib.sha256((args.source / "cmd/dms/server_client_test.go").read_bytes()).hexdigest() == digest
        result = {"original_failure_reproduced": True, "patched_go_socket_tests_passed": 2,
                  "all_original_test_functions_unchanged": True, "source_unchanged": True,
                  "go": str(args.go), "build_root_length": len(str(build_root))}
        (args.evidence / "result.json").write_text(json.dumps(result, indent=2) + "\n")
        print(json.dumps(result, indent=2))
