"""Core ELF regression tests; no Flutter, pub cache, network or wallet data.

Run: python3 -m unittest discover -s scripts/linux/tests -p 'test_*.py' -v
Requires a C compiler, binutils/readelf and patchelf with --clear-execstack.
"""

import ctypes
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "prepare_release_bundle.py"


class PrepareReleaseBundleTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fixtures = tempfile.TemporaryDirectory(prefix="linux-elf-fixtures-")
        cls.addClassCleanup(cls.fixtures.cleanup)
        cls.exec_so = Path(cls.fixtures.name) / "exec.so"
        cls.safe_so = Path(cls.fixtures.name) / "safe.so"
        for path, stack in ((cls.exec_so, "execstack"), (cls.safe_so, "noexecstack")):
            subprocess.run(
                ["cc", "-shared", "-fPIC", f"-Wl,-z,{stack}",
                 "-x", "c", "-", "-o", str(path)],
                input="int fixture_value(void) { return 42; }\n",
                text=True,
                check=True,
                capture_output=True,
            )

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="linux bundle 'quoted' ")
        self.addCleanup(self.temp.cleanup)
        self.bundle = Path(self.temp.name) / "bundle"
        (self.bundle / "lib").mkdir(parents=True)

    def run_prepare(self, *, expected=0, env=None):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), str(self.bundle)],
            text=True,
            capture_output=True,
            env=env,
        )
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def copy_library(self, name, *, executable=True):
        path = self.bundle / "lib" / name
        shutil.copy2(self.exec_so if executable else self.safe_so, path)
        return path

    def tool_environment(self, patchelf_body):
        tools = Path(self.temp.name) / "tools"
        tools.mkdir()
        patcher = tools / "patchelf"
        patcher.write_text("#!/bin/sh\n" + patchelf_body + "\n")
        patcher.chmod(0o755)
        return {**os.environ, "PATH": str(tools) + os.pathsep + os.environ["PATH"]}

    def test_all_wallets_are_nonexec_and_loadable(self):
        for wallet in ("monero", "wownero", "salvium"):
            self.copy_library(f"{wallet}_libwallet2_api_c.so")
        self.run_prepare()
        for path in (self.bundle / "lib").iterdir():
            with self.subTest(library=path.name):
                flags = subprocess.check_output(
                    ["patchelf", "--print-execstack", str(path)], text=True,
                )
                self.assertEqual(flags.strip(), "execstack: -")
                self.assertEqual(ctypes.CDLL(str(path)).fixture_value(), 42)

    def test_no_wallets_and_unrelated_files_are_unchanged(self):
        library = self.copy_library("libunrelated.so", executable=False)
        asset = self.bundle / "data.txt"
        asset.write_text("not an ELF\n")
        original = {path: path.read_bytes() for path in (library, asset)}
        self.run_prepare()
        for path, content in original.items():
            self.assertEqual(path.read_bytes(), content)

    def test_unexpected_executable_stack_is_rejected_not_patched(self):
        for relative in ("lib/libunexpected.so", "stack_wallet",
                         "lib/native_assets/nested.so"):
            with self.subTest(path=relative):
                path = self.bundle / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(self.exec_so, path)
                before = path.read_bytes()
                result = self.run_prepare(expected=1)
                self.assertIn("Executable stack still requested", result.stderr)
                self.assertIn(str(path), result.stderr)
                self.assertEqual(path.read_bytes(), before)
                path.unlink()

    def test_patchelf_failure_aborts(self):
        self.copy_library("monero_libwallet2_api_c.so")
        result = self.run_prepare(expected=1, env=self.tool_environment("exit 23"))
        self.assertIn("23", result.stderr)

    def test_successful_noop_patchelf_cannot_bypass_validation(self):
        self.copy_library("monero_libwallet2_api_c.so")
        result = self.run_prepare(expected=1, env=self.tool_environment("exit 0"))
        self.assertIn("Executable stack still requested", result.stderr)


if __name__ == "__main__":
    unittest.main()
