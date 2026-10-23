import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("audit", Path(__file__).with_name("audit-temporary-paths.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class TemporaryPathAuditTests(unittest.TestCase):
    def test_rejects_build_paths_in_scripts_and_elf_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            script = root / "wrapper with spaces"
            script.write_bytes(b"#!/bin/sh\nexec /build/job-123/bin/tool\n")
            elf = root / "binary"
            elf.write_bytes(b"\x7fELF\x00/build/job-123/lib\x00")
            self.assertCountEqual(module.audit(root, "/build/job-123/"), [script, elf])

    def test_allows_store_paths_data_files_and_neighboring_build_names(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "wrapper").write_bytes(b"#!/bin/sh\nexec /nix/store/safe/bin/tool\n")
            (root / "neighbor").write_bytes(b"#!/bin/sh\nexec /build/job-1234/bin/tool\n")
            (root / "debug-data").write_text("/build/job-123/debug-info")
            (root / "alias").symlink_to(root / "wrapper")
            self.assertEqual(module.audit(root, "/build/job-123"), [])


if __name__ == "__main__":
    unittest.main()
