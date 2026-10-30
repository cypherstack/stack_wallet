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

WRAPPER_SOURCE = """
#include <stdint.h>
void startVideoCaptureInThread(void) {}
void stopVideoCapture(void) {}
uint8_t *getLatestFrameBytes(int *length) { *length = 0; return 0; }
"""
# Like camera_linux.c: calls nothing in the wrapper.
CAMERA_SOURCE = "int camera_linux_fixture(void) { return 1; }\n"


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
        cls.build_camera_fixtures()

    @classmethod
    def compile_library(cls, name, source, *flags):
        path = Path(cls.fixtures.name) / name
        subprocess.run(
            ["cc", "-shared", "-fPIC", "-Wl,-z,noexecstack", "-x", "c", "-",
             "-o", str(path), *flags],
            input=source, text=True, check=True, capture_output=True,
        )
        return path

    @classmethod
    def build_camera_fixtures(cls):
        d = cls.fixtures.name
        wrapper = cls.compile_library(
            "libopencv_wrapper.so", WRAPPER_SOURCE, "-Wl,-soname,libopencv_wrapper.so")
        link = ["-Wl,--no-as-needed", f"-L{d}", "-lopencv_wrapper",
                "-Wl,-rpath,/nonexistent/build/dir"]
        camera = cls.compile_library("libcamera_linux.so", CAMERA_SOURCE, *link)
        cls.camera = camera
        cls.wrapper = wrapper
        # Not a baseline library, and not in the bundle.
        cls.camera_needs_zlib = cls.compile_library(
            "zlib_libcamera_linux.so", CAMERA_SOURCE, *link, "-lz")
        # Wrapper without one of the symbols Dart looks up.
        cls.wrapper_missing_symbol = cls.compile_library(
            "missing_libopencv_wrapper.so",
            WRAPPER_SOURCE.replace("void stopVideoCapture(void) {}", ""),
            "-Wl,-soname,libopencv_wrapper.so")
        # Linked without --no-as-needed: the dependency on the wrapper is dropped.
        cls.camera_as_needed = cls.compile_library(
            "asneeded_libcamera_linux.so", CAMERA_SOURCE,
            "-Wl,--as-needed", f"-L{d}", "-lopencv_wrapper")

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="linux bundle 'quoted' ")
        self.addCleanup(self.temp.cleanup)
        self.bundle = Path(self.temp.name) / "bundle"
        (self.bundle / "lib").mkdir(parents=True)
        self.install_camera()

    def install_camera(self, camera=None, wrapper=None):
        lib = self.bundle / "lib"
        if camera is not False:
            shutil.copy2(camera or self.camera, lib / "libcamera_linux.so")
        if wrapper is not False:
            shutil.copy2(wrapper or self.wrapper, lib / "libopencv_wrapper.so")

    def run_script(self, *args, expected=0):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), *args, str(self.bundle)],
            text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        return result

    def runpaths(self, name):
        out = subprocess.check_output(
            ["readelf", "--wide", "--dynamic", str(self.bundle / "lib" / name)], text=True)
        return [line.split("[", 1)[1].rstrip("]\n") for line in out.splitlines()
                if "RUNPATH" in line or "RPATH" in line]

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
        for path in (self.bundle / "lib").glob("*_libwallet2_api_c.so"):
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

    def test_camera_libraries_get_origin_runpath_and_load(self):
        self.assertEqual(self.runpaths("libcamera_linux.so"), ["/nonexistent/build/dir"])
        result = self.run_prepare()
        self.assertIn("Camera libraries load", result.stdout)
        self.assertEqual(self.runpaths("libcamera_linux.so"), ["$ORIGIN"])
        self.assertEqual(self.runpaths("libopencv_wrapper.so"), ["$ORIGIN"])

    def test_missing_wrapper_is_rejected(self):
        (self.bundle / "lib" / "libopencv_wrapper.so").unlink()
        result = self.run_prepare(expected=1)
        self.assertIn("libopencv_wrapper.so is missing", result.stderr)

    def test_missing_camera_library_is_rejected(self):
        (self.bundle / "lib" / "libcamera_linux.so").unlink()
        result = self.run_prepare(expected=1)
        self.assertIn("libcamera_linux.so is missing", result.stderr)

    def test_dependency_outside_bundle_and_baseline_is_rejected(self):
        self.install_camera(camera=self.camera_needs_zlib)
        result = self.run_prepare(expected=1)
        self.assertIn("libz.so", result.stderr)
        self.assertIn("neither bundled nor a baseline", result.stderr)

    def test_missing_symbol_is_rejected(self):
        self.install_camera(wrapper=self.wrapper_missing_symbol)
        result = self.run_prepare(expected=1)
        self.assertIn("stopVideoCapture", result.stderr)

    def test_dropped_wrapper_dependency_is_rejected(self):
        self.install_camera(camera=self.camera_as_needed)
        result = self.run_prepare(expected=1)
        self.assertIn("does not list libopencv_wrapper.so as NEEDED", result.stderr)

    def test_check_only_changes_nothing(self):
        before = {p.name: p.read_bytes() for p in (self.bundle / "lib").iterdir()}
        result = self.run_script("--check-only", expected=1)
        self.assertIn("RUNPATH/RPATH", result.stderr)
        self.run_prepare()
        prepared = {p.name: p.read_bytes() for p in (self.bundle / "lib").iterdir()}
        self.assertNotEqual(before, prepared)
        result = self.run_script("--check-only")
        self.assertIn("Camera libraries load", result.stdout)
        self.assertEqual(prepared, {p.name: p.read_bytes() for p in (self.bundle / "lib").iterdir()})


if __name__ == "__main__":
    unittest.main()
