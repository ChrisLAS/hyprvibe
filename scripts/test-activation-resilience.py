#!/usr/bin/env python3
"""Test evaluated Nixstation activation snippets without activating a real host.

Usage: python3 scripts/test-activation-resilience.py [--activation FILE]
Without FILE, evaluate the pinned flake's activation text (no system build).
Only the Waybar snippet runs, with home writes redirected into a temporary
directory, ownership commands stubbed, and a synthetic failed symlink write.
"""

import argparse
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile
import unittest


ACTIVATION = ""


def snippet(name):
    start = ACTIVATION.index(f"#### Activation script snippet {name}:\n")
    end = ACTIVATION.find("#### Activation script snippet ", start + 1)
    if end == -1:
        end = ACTIVATION.index("# Make this configuration", start)
    return ACTIVATION[start:end]


class ActivationResilience(unittest.TestCase):
    def run_waybar(self, fail, hyprland_trap=False):
        temp_root = "/tmp/opencode" if Path("/tmp/opencode").is_dir() else None
        with tempfile.TemporaryDirectory(prefix="activation-test-", dir=temp_root) as directory:
            root = Path(directory)
            home = root / "home"
            (root / "scripts").mkdir()
            body = snippet("waybar").replace("/home/chrisf", str(home))
            body = re.sub(r"/nix/store/[a-z0-9]+-scripts", str(root / "scripts"), body)
            self.assertNotIn("/home/chrisf", body)
            trap = ('echo "hyprland warning"' if hyprland_trap
                    else '_status=1 _localstatus=$?')
            # Keep the failing command out of an `if`/`||` condition: Bash would
            # otherwise suppress errexit inside the snippet and hide the bug.
            program = r'''
set +e
_status=0
_localstatus=0
install() {
  local -a args=()
  while (( $# )); do
    case "$1" in
      -o|-g) shift 2 ;;
      *) args+=("$1"); shift ;;
    esac
  done
  command install "${args[@]}"
}
chown() { :; }
ln() {
  if [[ "$FAIL_WRITE" == 1 && "${@: -1}" == "$TEST_HOME/.config/waybar/config" ]]; then
    echo 'synthetic symlink write failure: No space left on device' >&2
    return 1
  fi
  command ln "$@"
}
'''
            program += f"trap {shlex.quote(trap)} ERR\n"
            if hyprland_trap:
                program += "set -u\n"
            program += 'before_flags=$-\nbefore_trap=$(trap -p ERR)\n'
            program += body
            program += r'''
[[ "$before_flags" == "$-" ]] || exit 91
[[ "$before_trap" == "$(trap -p ERR)" ]] || exit 92
command ln -s system "$TEST_ROOT/current-system"
exit "$_status"
'''
            result = subprocess.run(
                ["bash", "--noprofile", "--norc"], input=program,
                env={**os.environ, "TEST_ROOT": str(root), "TEST_HOME": str(home),
                     "FAIL_WRITE": str(int(fail)), "BASH_ENV": "/dev/null"},
                capture_output=True, text=True, timeout=20,
            )
            self.assertTrue((root / "current-system").is_symlink(), result.stdout + result.stderr)
            self.assertEqual(result.returncode, int(fail), result.stdout + result.stderr)
            if fail:
                self.assertIn("activation failed", result.stdout)

    def test_success_preserves_parent_shell(self):
        for hyprland_trap in (False, True):
            with self.subTest(hyprland_trap=hyprland_trap):
                self.run_waybar(False, hyprland_trap)

    def test_failed_write_reports_failure_but_reaches_final_link(self):
        for hyprland_trap in (False, True):
            with self.subTest(hyprland_trap=hyprland_trap):
                self.run_waybar(True, hyprland_trap)

    def test_accountsservice_uses_store_backed_sed(self):
        body = snippet("nixstationAccountsServiceSession")
        self.assertFalse(re.search(r"^\s*sed\s", body, re.MULTILINE))
        self.assertEqual(len(re.findall(r"/nix/store/[^\s]+/bin/sed -i", body)), 2)

    def test_generated_shell_syntax(self):
        result = subprocess.run(["bash", "-n"], input=ACTIVATION,
                                capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--activation", type=Path)
    args, test_args = parser.parse_known_args()
    if args.activation:
        ACTIVATION = args.activation.read_text()
    else:
        ACTIVATION = subprocess.check_output(
            ["nix", "eval", "--raw", ".#nixosConfigurations.nixstation.config.system.activationScripts.script"],
            cwd=Path(__file__).resolve().parents[1], text=True, timeout=180,
        )
    unittest.main(argv=[__file__, *test_args])
