#!/usr/bin/env python3
"""Exercise evaluated Dux check hooks in disposable directories, never a desktop.

Pass --package-check-json with preCheck, postCheck, doCheck and checkPhase from
the exact Nixvader Dux package. All socket operations are local temporary Unix
sockets; no graphical session, service or network listener is started.
"""
import argparse
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import unittest


PACKAGE = {}
TEST_NAMES = ("TestServerRequestTimesOutWithoutGreeting",
              "TestServerRequestReportsClosedConnection")


class DuxCheckTempdir(unittest.TestCase):
    def test_checks_and_full_go_test_loop_remain_enabled(self):
        self.assertIs(PACKAGE["doCheck"], True)
        self.assertIn('buildGoDir test "$pkg"', PACKAGE["checkPhase"])
        self.assertNotIn("-run", PACKAGE["preCheck"])

    def test_long_builder_path_reproduces_the_socket_failure(self):
        with tempfile.TemporaryDirectory(prefix="dux-long-", dir="/tmp/opencode") as directory:
            for name in TEST_NAMES:
                with self.subTest(name=name):
                    path = Path(directory) / "nix-3972986-788049123" / (name + "1811651387") / "001" / "danklinux.sock"
                    path.parent.mkdir(parents=True)
                    self.assertGreaterEqual(len(os.fsencode(path)), 108)
                    with socket.socket(socket.AF_UNIX) as sock:
                        with self.assertRaises(OSError):
                            sock.bind(str(path))

    def test_evaluated_hooks_allow_sockets_and_restore_build_environment(self):
        self.run_evaluated_hooks(None)

    def test_existing_go_tempdir_is_preserved_and_restored(self):
        self.run_evaluated_hooks("custom")

    def test_explicitly_empty_go_tempdir_is_restored_as_empty(self):
        self.run_evaluated_hooks("")

    def run_evaluated_hooks(self, go_tmpdir):
        with tempfile.TemporaryDirectory(prefix="dux-long-", dir="/tmp/opencode") as directory:
            original = str(Path(directory) / "nix-3972986-788049123")
            Path(original).mkdir()
            environment = {**os.environ, "TMPDIR": original, "ORIGINAL_TMPDIR": original}
            environment.pop("GOTMPDIR", None)
            if go_tmpdir == "custom":
                go_tmpdir = str(Path(directory) / "go-executable-area")
                Path(go_tmpdir).mkdir()
            if go_tmpdir is not None:
                environment["GOTMPDIR"] = go_tmpdir
            environment["EXPECTED_GO_TMPDIR"] = go_tmpdir or original
            # Reproduce Go's t.TempDir test-name/random/001 layout, including
            # both exact failing test names and the actual socket basename.
            body = PACKAGE["preCheck"] + "\n" + r'''
test "$TMPDIR" != "$ORIGINAL_TMPDIR"
test "${#TMPDIR}" -le 24
test "$(stat -c %a "$TMPDIR")" = 700
short_tmpdir="$TMPDIR"
test "$GOTMPDIR" = "$EXPECTED_GO_TMPDIR"
test "$GOTMPDIR" != "$TMPDIR"
exec_smoke="$GOTMPDIR/dux-executable-smoke"
printf '#!/bin/sh\nexit 0\n' > "$exec_smoke"
chmod 700 "$exec_smoke"
"$exec_smoke"
rm -- "$exec_smoke"
python3 - <<'PY'
import os, socket, tempfile
from pathlib import Path
for name in ('TestServerRequestTimesOutWithoutGreeting',
             'TestServerRequestReportsClosedConnection'):
    with tempfile.TemporaryDirectory(prefix=name + '1811651387', dir=os.environ['TMPDIR']) as directory:
        path = Path(directory) / '001' / 'danklinux.sock'
        path.parent.mkdir()
        assert len(os.fsencode(path)) < 108, str(path)
        with socket.socket(socket.AF_UNIX) as sock:
            sock.bind(str(path))
PY
'''
            body += PACKAGE["postCheck"] + "\n"
            body += 'test "$TMPDIR" = "$ORIGINAL_TMPDIR"\ntest ! -e "$short_tmpdir"\n'
            if go_tmpdir is None:
                body += 'test -z "${GOTMPDIR+x}"\n'
            else:
                environment["ORIGINAL_GO_TMPDIR"] = go_tmpdir
                body += 'test "${GOTMPDIR+x}" = x\ntest "$GOTMPDIR" = "$ORIGINAL_GO_TMPDIR"\n'
            result = subprocess.run(["bash", "-euc", body], text=True, capture_output=True,
                                    env=environment, timeout=20)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package-check-json", required=True, type=Path)
    args, remaining = parser.parse_known_args()
    PACKAGE = json.loads(args.package_check_json.read_text())
    unittest.main(argv=[__file__, *remaining])
