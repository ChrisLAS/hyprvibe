#!/usr/bin/env python3
"""Test the extracted helper without touching real power services or sysfs."""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/power-profile.sh"
BASH = shutil.which("bash")
# Canonical body of the old activation heredoc at published baseline 94d63f7.
# This only relocates that implementation; power-policy changes are separate.
LEGACY_SHA256 = "47706f71deb88a22a416e511342704cdae435b136d8e3d670677c13734bb1353"
MODULE_EVALUATION = None


class PowerProfile(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="power-profile-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.home.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "commands.log"
        self.env = {"PATH": str(self.bin), "HOME": str(self.home),
                    "TEST_LOG": str(self.log), "BASH_ENV": "/dev/null"}
        for name in ("cat", "awk", "sed", "grep", "head", "readlink"):
            target = shutil.which(name)
            self.assertIsNotNone(target, name)
            (self.bin / name).symlink_to(target)

        self.stub("powerprofilesctl", '''
printf 'powerprofilesctl %s\\n' "$*" >> "$TEST_LOG"
if [ "${1:-}" = get ]; then echo balanced; fi
[ "${FAKE_POWER_FAIL:-0}" != 1 ]
''')
        self.stub("ip", 'printf "2: wlan0: <BROADCAST,UP>\\n"\n')
        self.stub("iw", "exit 0\n")
        self.stub("upower", '''
case "${1:-}" in
  -e) echo /battery/test ;;
  -i) printf 'state: fully-charged\\npercentage: 77%%\\n' ;;
esac
''')
        # Never delegate to a real privileged command, tee, or system service.
        self.stub("sudo", '''
input="$(cat)"
printf 'sudo %s input=%s\\n' "$*" "$input" >> "$TEST_LOG"
''')

    def stub(self, name, body):
        path = self.bin / name
        path.write_text(f"#!{BASH}\nset -eu\n" + body)
        path.chmod(0o755)

    def run_helper(self, *args, home=None, fail=False):
        # Read/write fixtures replace ALL literal sysfs paths before executing.
        # The actual shipped source is separately checked for byte equivalence.
        source = SCRIPT.read_text()
        sysfs = self.root / "fake-sysfs"
        sysfs.mkdir(exist_ok=True)
        for relative in ("block/sda/power", "devices/system/cpu/cpu0/cpufreq",
                         "class/drm/card0/device", "bus/pci/drivers/amdgpu"):
            (sysfs / relative).mkdir(parents=True, exist_ok=True)
        driver = sysfs / "class/drm/card0/device/driver"
        if not driver.is_symlink():
            driver.symlink_to(sysfs / "bus/pci/drivers/amdgpu")
        (sysfs / "class/drm/card0/device/power_dpm_force_performance_level").touch()
        program = self.root / "power-profile-under-test.sh"
        program.write_text(source.replace("/sys/", str(sysfs) + "/"))
        self.assertFalse("/sys/" in program.read_text(), "unredirected real sysfs path")
        env = {**self.env, "FAKE_POWER_FAIL": str(int(fail))}
        if home is not None:
            env["HOME"] = str(home)
        return subprocess.run([BASH, "--noprofile", "--norc", str(program), *args],
                              env=env, stdin=subprocess.DEVNULL,
                              capture_output=True, text=True, timeout=10)

    def commands(self):
        return self.log.read_text() if self.log.exists() else ""

    def test_source_is_packaged_not_activated(self):
        module = (ROOT / "modules/shared/power.nix").read_text()
        self.assertFalse("system.activationScripts.installPowerProfileScript" in module,
                         "power helper must not be provisioned by root activation")
        self.assertIn('writeShellScriptBin "power-profile"', module)
        self.assertIn("builtins.readFile ../../scripts/power-profile.sh", module)
        self.assertIn("exec power-profile", module)
        self.assertNotIn(".local/bin/power-profile", module)

    def test_extraction_preserves_runtime_body(self):
        canonical = "\n".join(line.rstrip() for line in SCRIPT.read_text().splitlines()) + "\n"
        self.assertEqual(hashlib.sha256(canonical.encode()).hexdigest(), LEGACY_SHA256)

    def test_shell_syntax(self):
        result = subprocess.run([BASH, "-n", str(SCRIPT)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_all_profiles_keep_daemon_wifi_and_gpu_operations(self):
        for profile, wifi, gpu in (("performance", "off", "high"),
                                   ("balanced", "on", "auto"),
                                   ("power-saver", "on", "low")):
            with self.subTest(profile=profile):
                self.log.unlink(missing_ok=True)
                result = self.run_helper(profile)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                commands = self.commands()
                self.assertIn(f"powerprofilesctl set {profile}", commands)
                self.assertIn(f"sudo iw dev wlan0 set power_save {wifi}", commands)
                self.assertIn("power_dpm_force_performance_level input=" + gpu, commands)
                self.assertIn("Power profile set to: " + profile, result.stdout)

    def test_failed_daemon_keeps_cpu_fallback(self):
        for profile, governor in (("performance", "performance"),
                                  ("balanced", "schedutil"),
                                  ("power-saver", "powersave")):
            with self.subTest(profile=profile):
                result = self.run_helper(profile, fail=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("scaling_governor input=" + governor, self.commands())

    def test_status_and_errors_do_not_switch_power(self):
        result = self.run_helper("status")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Current profile: balanced", result.stdout)
        self.assertNotIn("sudo ", self.commands())
        for args in ((), ("invalid",)):
            self.log.unlink(missing_ok=True)
            result = self.run_helper(*args)
            self.assertEqual(result.returncode, 1)
            self.assertEqual(self.commands(), "")

    def test_missing_dependency_reports_failure_without_privileged_commands(self):
        (self.bin / "powerprofilesctl").unlink()
        result = self.run_helper("performance")
        self.assertEqual(result.returncode, 1)
        self.assertIn("powerprofilesctl not found", result.stdout)
        self.assertEqual(self.commands(), "")

    def test_unavailable_home_and_existing_user_edits_are_irrelevant(self):
        legacy = self.home / ".local/bin/power-profile"
        legacy.parent.mkdir(parents=True)
        legacy.write_text("user-customized executable\n")
        before = legacy.read_bytes()
        blocked = self.root / "not-a-directory"
        blocked.write_text("unavailable home")
        result = self.run_helper("status", home=blocked)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(legacy.read_bytes(), before)
        self.assertEqual(list(self.home.rglob("*")),
                         [self.home / ".local", self.home / ".local/bin", legacy])

    def test_menu_works_without_a_home_executable_and_preserves_path_override(self):
        if MODULE_EVALUATION is None:
            self.skipTest("pass --module-evaluation for isolated Nix menu tests")
        evaluated = json.loads(MODULE_EVALUATION.read_text())
        self.assertEqual(len(evaluated["checks"]), 6)
        self.stub("power-profile", 'printf "profile=%s\\n" "$*"\n')
        self.stub("vicinae", 'cat >/dev/null\nprintf "%s\\n" balanced\n')
        menu = self.root / "menu.sh"
        source = evaluated["menuScript"].replace(
            "/fixture/coreutils/bin/printf", shutil.which("printf")).replace(
            "/fixture/vicinae/bin/vicinae", str(self.bin / "vicinae"))
        self.assertNotIn("/fixture/", source)
        menu.write_text(source)
        result = subprocess.run([BASH, str(menu)], env=self.env, stdin=subprocess.DEVNULL,
                                capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "profile=balanced\n")
        self.assertEqual(list(self.home.iterdir()), [])

        # A user override earlier in PATH remains authoritative, without edits.
        local_bin = self.home / ".local/bin"
        local_bin.mkdir(parents=True)
        override = local_bin / "power-profile"
        override.write_text(f'#!{BASH}\nprintf "user=%s\\n" "$*"\n')
        override.chmod(0o755)
        before = override.read_bytes()
        result = subprocess.run([BASH, str(menu)],
                                env={**self.env, "PATH": f"{local_bin}:{self.bin}"},
                                stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "user=balanced\n")
        self.assertEqual(override.read_bytes(), before)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--module-evaluation", type=Path)
    args, test_args = parser.parse_known_args()
    MODULE_EVALUATION = args.module_evaluation
    unittest.main(argv=[__file__, *test_args])
