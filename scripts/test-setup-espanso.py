#!/usr/bin/env python3
"""Exercise setup against throwaway directories, never the live configuration."""

import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("setup_espanso", Path(__file__).with_name("setup-espanso.py"))
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.source = self.root / "checkout/files"
        (self.source / "config").mkdir(parents=True)
        (self.source / "match").mkdir()
        (self.root / "checkout/.git").mkdir()
        (self.source / "config/default.yml").write_text("auto_restart: true\n")
        self.target = self.root / "appdata/espanso"

    def test_link_utility_is_idempotent_and_preserves_edits(self):
        setup.connect(self.source, self.target)
        snippet = self.target / "match/new.yml"
        snippet.write_text("matches: []\n")
        setup.connect(self.source, self.target)
        self.assertEqual((self.source / "match/new.yml").read_text(), "matches: []\n")
        self.assertFalse(list(self.target.parent.glob("espanso.backup-*")))

    def test_previous_config_survives_in_backup(self):
        self.target.mkdir(parents=True)
        (self.target / "personal.yml").write_text("private original\n")
        setup.connect(self.source, self.target)
        backups = list(self.target.parent.glob("espanso.backup-*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / "personal.yml").read_text(), "private original\n")
        self.assertEqual(self.target.resolve(), self.source)

    def test_symlink_permission_failure_leaves_previous_config_in_place(self):
        self.target.mkdir(parents=True)
        (self.target / "old.yml").write_text("keep me")
        with patch.object(Path, "symlink_to", side_effect=PermissionError("denied")):
            with self.assertRaises(PermissionError):
                setup.connect(self.source, self.target)
        self.assertEqual((self.target / "old.yml").read_text(), "keep me")

    def test_failed_install_rolls_back_original(self):
        self.target.mkdir(parents=True)
        (self.target / "old.yml").write_text("keep me")
        rename = os.rename

        def fail_install(source, destination):
            if Path(source).name.startswith(".espanso.link-"):
                raise OSError("simulated installation failure")
            return rename(source, destination)

        with patch("os.rename", side_effect=fail_install):
            with self.assertRaises(OSError):
                setup.connect(self.source, self.target)
        self.assertEqual((self.target / "old.yml").read_text(), "keep me")
        self.assertFalse(list(self.target.parent.glob(".espanso.link-*")))

    def test_unsafe_nesting_is_refused_without_moving_checkout(self):
        with self.assertRaises(ValueError):
            setup.connect(self.source, self.root / "checkout")
        with self.assertRaises(ValueError):
            setup.connect(self.source, self.source / "nested")
        self.assertTrue((self.source / "config/default.yml").is_file())

    def test_dangling_previous_symlink_is_preserved(self):
        self.target.parent.mkdir(parents=True)
        self.target.symlink_to(self.root / "missing", target_is_directory=True)
        setup.connect(self.source, self.target)
        backups = list(self.target.parent.glob("espanso.backup-*"))
        self.assertEqual(len(backups), 1)
        self.assertTrue(backups[0].is_symlink())

    def test_editor_changes_stay_private_and_activation_preserves_them(self):
        (self.source / "match/dates.yml").write_text("matches: []\n")
        runtime = self.root / "private/runtime"
        setup.prepare_runtime(self.source, runtime)
        setup.connect(runtime, self.target)
        (self.target / "match/dates.yml").write_text("private edit\n")
        (self.target / "match/emails.yml").write_text("private addresses\n")
        setup.prepare_runtime(self.source, runtime)
        self.assertEqual((runtime / "match/dates.yml").read_text(), "private edit\n")
        self.assertEqual((self.source / "match/dates.yml").read_text(), "matches: []\n")
        self.assertFalse((self.source / "match/emails.yml").exists())
        self.assertEqual((runtime / "config/default.yml").stat().st_mode & 0o077, 0)

    def test_private_files_and_symlinks_are_never_public_seeds(self):
        (self.source / "match/private.local.yml").write_text("private\n")
        external = self.root / "outside.yml"
        external.write_text("also private\n")
        (self.source / "match/external.yml").symlink_to(external)
        runtime = self.root / "private/runtime"
        setup.prepare_runtime(self.source, runtime)
        self.assertFalse((runtime / "match/private.local.yml").exists())
        self.assertFalse((runtime / "match/external.yml").exists())

    def test_private_runtime_inside_public_repo_is_refused(self):
        with self.assertRaises(ValueError):
            setup.prepare_runtime(self.source, self.root / "checkout/private")

    def test_personal_link_survives_restore_under_another_home(self):
        runtime = setup.prepare_runtime(self.source, self.root / "first-home/private/runtime")
        personal = runtime.parent / "personal.yml"
        personal.write_text("matches: []\n")
        setup.link_personal(runtime)
        link = runtime / "match/personal.yml"
        self.assertFalse(Path(os.readlink(link)).is_absolute())
        moved = self.root / "second-home/private"
        moved.parent.mkdir()
        runtime.parent.rename(moved)
        self.assertEqual((moved / "runtime/match/personal.yml").read_text(), "matches: []\n")

    def test_stale_absolute_link_is_repaired_without_copying_personal_values(self):
        runtime = setup.prepare_runtime(self.source, self.root / "private/runtime")
        personal = runtime.parent / "personal.yml"
        personal.write_text("matches: []\n")
        link = runtime / "match/personal.yml"
        link.symlink_to(self.root / "old-home/private/personal.yml")
        setup.link_personal(runtime)
        self.assertEqual(link.resolve(), personal)
        self.assertEqual(os.readlink(link), "../../personal.yml")
        self.assertFalse((self.source / "match/personal.yml").exists())

    def test_existing_personal_file_and_custom_working_link_are_preserved(self):
        runtime = setup.prepare_runtime(self.source, self.root / "private/runtime")
        (runtime.parent / "personal.yml").write_text("canonical\n")
        link = runtime / "match/personal.yml"
        link.write_text("local edits\n")
        setup.link_personal(runtime)
        self.assertEqual(link.read_text(), "local edits\n")
        link.unlink()
        custom = self.root / "custom.yml"
        custom.write_text("custom source\n")
        link.symlink_to(custom)
        setup.link_personal(runtime)
        self.assertEqual(link.resolve(), custom)

    def test_emoji_package_installs_privately_and_preserves_local_edits(self):
        runtime = setup.prepare_runtime(self.source, self.root / "private/runtime")
        package = self.root / "emoji-package"
        package.mkdir()
        (package / "_manifest.yml").write_text("name: all-emojis\nversion: 0.1.0\n")
        (package / "package.yml").write_text("matches: []\n")
        setup.install_emoji(runtime, package)
        installed = runtime / "match/packages/all-emojis/package.yml"
        self.assertEqual(installed.read_text(), "matches: []\n")
        self.assertEqual(installed.stat().st_mode & 0o077, 0)
        installed.write_text("local edits\n")
        setup.install_emoji(runtime, package)
        self.assertEqual(installed.read_text(), "local edits\n")
        self.assertFalse((self.source / "match/packages").exists())


if __name__ == "__main__":
    unittest.main()
