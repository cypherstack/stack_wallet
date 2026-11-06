#!/usr/bin/env python3
"""Prepare a finished Flutter Linux bundle before tar/AppImage/Flatpak packaging.

Requires patchelf with --clear-execstack support and readelf (binutils).
Only the known Monero-family wallet libraries are patched; any other ELF that
requests an executable stack fails validation rather than being silently changed.

It also checks the QR scanner plugin: libcamera_linux.so and libopencv_wrapper.so
must be in lib/, find each other through RUNPATH $ORIGIN, depend on nothing outside
the bundle except the baseline libraries listed below (OpenCV is linked statically
into libopencv_wrapper.so), and load with the symbols Dart looks up.

--check-only skips all patching and needs only readelf, ldd and python3, so it can
also verify an already assembled AppDir or tarball bundle.
"""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys


WALLET_LIBRARIES = {
    "monero_libwallet2_api_c.so",
    "wownero_libwallet2_api_c.so",
    "salvium_libwallet2_api_c.so",
}

CAMERA_LIBRARY = "libcamera_linux.so"
CAMERA_WRAPPER = "libopencv_wrapper.so"
# Looked up by Dart through dart:ffi in camera_linux.
CAMERA_SYMBOLS = ("startVideoCaptureInThread", "stopVideoCapture", "getLatestFrameBytes")

# What the camera libraries may need from the host. Everything else has to come
# from the bundle (the wrapper is the only bundled dependency), so a stray
# libopencv_*.so, libjpeg or libpng NEEDED entry fails here even on a build
# machine that happens to have those installed.
BASELINE_NEEDED = {
    "libc.so.6",
    "libm.so.6",
    "libdl.so.2",
    "libpthread.so.0",
    "librt.so.1",
    "libgcc_s.so.1",
    "libstdc++.so.6",
    "ld-linux-x86-64.so.2",
    "ld-linux-aarch64.so.1",
}

# Opens the library the way a loader would from a clean environment and looks up
# the symbols. Runs in a child process so a crash in a constructor is reported.
LOAD_CHECK = """
import ctypes, sys
lib = ctypes.CDLL(sys.argv[1])
for name in sys.argv[2:]:
    getattr(lib, name)
"""


def dynamic_entries(path):
    """Return (needed sonames, rpath/runpath values) of an ELF file."""
    result = subprocess.run(
        ["readelf", "--wide", "--dynamic", str(path)],
        check=True,
        capture_output=True,
        text=True,
    )
    needed, paths = [], []
    for line in result.stdout.splitlines():
        if "(NEEDED)" in line and "[" in line:
            needed.append(line.split("[", 1)[1].rsplit("]", 1)[0])
        elif ("(RUNPATH)" in line or "(RPATH)" in line) and "[" in line:
            paths.append(line.split("[", 1)[1].rsplit("]", 1)[0])
    return needed, paths


def patch_camera_rpath(lib_dir):
    """Make libcamera_linux.so and libopencv_wrapper.so find each other in lib/."""
    for name in (CAMERA_LIBRARY, CAMERA_WRAPPER):
        path = lib_dir / name
        if path.is_symlink():
            raise ValueError(f"Camera library must be a bundled copy, not a symlink: {path}")
        print(f"Setting RUNPATH to $ORIGIN: {path}", flush=True)
        subprocess.run(["patchelf", "--set-rpath", "$ORIGIN", str(path)], check=True)


def check_camera_libraries(bundle):
    lib_dir = bundle / "lib"
    camera, wrapper = lib_dir / CAMERA_LIBRARY, lib_dir / CAMERA_WRAPPER
    for path in (camera, wrapper):
        if path.is_symlink():
            raise ValueError(
                f"Camera library must be a bundled copy, not a symlink: {path}"
            )
    if not camera.is_file():
        raise ValueError(f"{CAMERA_LIBRARY} is missing from {lib_dir}; QR scanning would not work")
    if not wrapper.is_file():
        raise ValueError(
            f"{CAMERA_WRAPPER} is missing from {lib_dir}; {CAMERA_LIBRARY} cannot be loaded without it"
        )

    problems = []
    for path in (camera, wrapper):
        needed, rpaths = dynamic_entries(path)
        if rpaths != ["$ORIGIN"]:
            problems.append(f"{path.name}: RUNPATH/RPATH is {rpaths}, expected ['$ORIGIN']")
        for soname in needed:
            if soname == CAMERA_WRAPPER and path == camera:
                continue
            if soname in BASELINE_NEEDED:
                continue
            problems.append(f"{path.name}: needs {soname}, which is neither bundled nor a baseline library")
        if path == camera and CAMERA_WRAPPER not in needed:
            problems.append(f"{path.name}: does not list {CAMERA_WRAPPER} as NEEDED (--as-needed dropped it?)")
    if problems:
        raise ValueError("Camera libraries are not self-contained:\n" + "\n".join(problems))

    # Resolve dependencies with nothing but the libraries' own RUNPATH.
    clean_env = {k: v for k, v in os.environ.items() if k not in ("LD_LIBRARY_PATH", "LD_PRELOAD")}
    if shutil.which("ldd") is None:
        raise ValueError("Required tool not found: ldd")
    for path in (camera, wrapper):
        result = subprocess.run(
            ["ldd", str(path)], capture_output=True, text=True, env=clean_env
        )
        missing = [line.strip() for line in result.stdout.splitlines() if "not found" in line]
        if missing:
            raise ValueError(f"{path.name} has unresolved dependencies:\n" + "\n".join(missing))

    result = subprocess.run(
        [sys.executable, "-I", "-c", LOAD_CHECK, str(camera), *CAMERA_SYMBOLS],
        capture_output=True,
        text=True,
        env=clean_env,
    )
    if result.returncode != 0:
        raise ValueError(
            f"{CAMERA_LIBRARY} does not load or lacks {', '.join(CAMERA_SYMBOLS)}:\n"
            + (result.stdout + result.stderr).strip()
        )
    print(f"Camera libraries load with all symbols from {lib_dir}")


def prepare_bundle(bundle, check_only=False):
    if not bundle.is_dir() or not (bundle / "lib").is_dir():
        raise ValueError(f"Not a Flutter Linux bundle (missing lib directory): {bundle}")

    for tool in ("readelf",) if check_only else ("patchelf", "readelf"):
        if shutil.which(tool) is None:
            raise ValueError(f"Required tool not found: {tool}")

    if check_only:
        check_camera_libraries(bundle)
        return

    # Fail before patching anything if the plugin libraries are not both there.
    for name in (CAMERA_LIBRARY, CAMERA_WRAPPER):
        if not (bundle / "lib" / name).is_file():
            raise ValueError(f"{name} is missing from {bundle / 'lib'}; the QR scanner would not load")

    files = sorted(path for path in bundle.rglob("*") if path.is_file())
    for path in files:
        if path.parent == bundle / "lib" and path.name in WALLET_LIBRARIES:
            # Never patch a link into the pub cache or another source tree.
            if path.is_symlink():
                raise ValueError(f"Wallet library must be a bundled copy, not a symlink: {path}")
            print(f"Clearing executable-stack flag: {path}", flush=True)
            subprocess.run(["patchelf", "--clear-execstack", str(path)], check=True)

    # Check the executable and all bundled libraries, including native assets.
    # A library without PT_GNU_STACK has no explicit executable-stack request;
    # do not require that header on unrelated artifacts generated by Dart.
    executable_stacks = []
    for path in files:
        with path.open("rb") as source:
            if source.read(4) != b"\x7fELF":
                continue
        result = subprocess.run(
            ["readelf", "--wide", "--program-headers", str(path)],
            check=True,
            capture_output=True,
            text=True,
        )
        for line in result.stdout.splitlines():
            fields = line.split()
            # readelf can print flags as either RWE or separate R / E fields.
            if fields and fields[0] == "GNU_STACK" and "E" in "".join(fields[6:-1]):
                executable_stacks.append(str(path))

    if executable_stacks:
        raise ValueError("Executable stack still requested by:\n" + "\n".join(executable_stacks))
    print(f"Linux bundle executable-stack validation passed: {bundle}")

    patch_camera_rpath(bundle / "lib")
    check_camera_libraries(bundle)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("bundle", type=Path, help="Finished Flutter Linux bundle directory")
    parser.add_argument(
        "--check-only",
        action="store_true",
        help="only verify that the camera libraries are self-contained and load; change nothing",
    )
    args = parser.parse_args()
    try:
        prepare_bundle(args.bundle.resolve(), check_only=args.check_only)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Linux bundle preparation failed: {error}\n")


if __name__ == "__main__":
    main()
