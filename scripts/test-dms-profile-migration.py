#!/usr/bin/env python3
"""Exercise the copy-only Dux profile migration in disposable homes."""

from pathlib import Path
import os
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().with_name("migrate-dms-profile.sh")


class ProfileMigration(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(
            prefix="dms-migration-", dir="/tmp/opencode" if Path("/tmp/opencode").is_dir() else None)
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)

    def migrate(self):
        subprocess.run(["bash", str(SCRIPT), str(self.home)], check=True, timeout=10)

    def test_copies_legacy_without_changing_it(self):
        for base in (".config", ".local/state"):
            legacy = self.home / base / "DankMaterialShell"
            legacy.mkdir(parents=True)
            (legacy / "profile.json").write_text('{"custom":true}')
            (legacy / "profile.json").chmod(0o600)
        self.migrate()
        for base in (".config", ".local/state"):
            for name in ("DankMaterialShell", "dms"):
                path = self.home / base / name / "profile.json"
                self.assertEqual(path.read_text(), '{"custom":true}')
                self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_existing_new_profile_and_second_run_are_untouched(self):
        legacy = self.home / ".config/DankMaterialShell"
        legacy.mkdir(parents=True)
        (legacy / "settings.json").write_text("legacy")
        self.migrate()
        current = self.home / ".config/dms/settings.json"
        current.write_text("current")
        self.migrate()
        self.assertEqual(current.read_text(), "current")
        self.assertEqual((legacy / "settings.json").read_text(), "legacy")

    def test_fresh_home_does_not_fabricate_a_profile(self):
        self.migrate()
        self.assertFalse((self.home / ".config/dms").exists())
        self.assertFalse((self.home / ".local/state/dms").exists())

    def test_failed_copy_leaves_legacy_intact_and_no_partial_destination(self):
        legacy = self.home / ".config/DankMaterialShell"
        legacy.mkdir(parents=True)
        (legacy / "settings.json").write_text("legacy")
        fake_bin = self.home / "bin"
        fake_bin.mkdir()
        fake_cp = fake_bin / "cp"
        fake_cp.write_text("#!/bin/sh\necho 'synthetic ENOSPC' >&2\nexit 1\n")
        fake_cp.chmod(0o755)
        result = subprocess.run(["bash", str(SCRIPT), str(self.home)],
                                env={**os.environ, "PATH": str(fake_bin) + ":" + os.environ["PATH"]},
                                capture_output=True, text=True, timeout=10)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home / ".config/dms").exists())
        self.assertEqual((legacy / "settings.json").read_text(), "legacy")
        self.assertEqual(list((self.home / ".config").glob(".dms-migration.*")), [])


if __name__ == "__main__":
    unittest.main()
