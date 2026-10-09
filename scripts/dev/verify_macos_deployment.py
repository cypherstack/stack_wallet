#!/usr/bin/env python3
"""Check a built app's advertised macOS floor against every embedded Mach-O slice.

Usage: python3 scripts/dev/verify_macos_deployment.py path/to/Wallet.app
Read-only. Exit 0 means declared deployment targets fit, 1 means a mismatch, and 2 means
verification could not complete. Requires the Xcode command-line tools.
"""

import argparse
import plistlib
import re
import subprocess
import sys
from pathlib import Path

MACHO_MAGIC = {
    bytes.fromhex(value)
    for value in (
        "feedface", "cefaedfe", "feedfacf", "cffaedfe",
        "cafebabe", "bebafeca", "cafebabf", "bfbafeca",
    )
}


def version(value):
    if not isinstance(value, str) or not re.fullmatch(r"\d+(?:\.\d+){0,2}", value):
        raise ValueError(f"Invalid macOS version: {value!r}")
    parts = tuple(map(int, value.split(".")))
    return parts + (0,) * (3 - len(parts))


def run_tool(*args):
    result = subprocess.run(
        ["xcrun", *args], check=True, capture_output=True, text=True, timeout=30,
    )
    return result.stdout


def minimum_version(binary, architecture):
    output = run_tool("vtool", "-arch", architecture, "-show-build", str(binary))
    command = None
    platform = None
    found = []
    for line in output.splitlines():
        fields = line.split()
        if len(fields) != 2:
            continue
        key, value = fields
        if key == "cmd":
            command, platform = value, None
        elif key == "platform":
            platform = value
        elif command == "LC_BUILD_VERSION" and key == "minos":
            if platform not in ("MACOS", "1"):
                raise ValueError(f"{binary} [{architecture}] targets {platform}, not macOS")
            found.append(value)
        elif command == "LC_VERSION_MIN_MACOSX" and key == "version":
            found.append(value)
    if len(found) != 1:
        raise ValueError(f"{binary} [{architecture}]: expected one macOS deployment load command")
    return found[0]


def verify(app):
    contents = app / "Contents"
    with (contents / "Info.plist").open("rb") as stream:
        advertised = plistlib.load(stream).get("LSMinimumSystemVersion")
    floor = version(advertised)
    seen = set()
    slices = 0
    failures = []
    for entry in sorted(contents.rglob("*")):
        if not entry.is_file():
            continue
        resolved = entry.resolve()
        if resolved in seen:
            continue
        seen.add(resolved)
        with entry.open("rb") as stream:
            if stream.read(4) not in MACHO_MAGIC:
                continue
        architectures = run_tool("lipo", "-archs", str(entry)).split()
        if not architectures:
            raise ValueError(f"No Mach-O architectures found: {entry}")
        for architecture in architectures:
            minimum = minimum_version(entry, architecture)
            slices += 1
            if version(minimum) > floor:
                failures.append(
                    f"{entry.relative_to(contents)} [{architecture}] requires macOS {minimum}"
                )
    if not slices:
        raise ValueError("No embedded Mach-O slices found; cannot verify this app")
    print(f"App advertises macOS {advertised}; inspected {slices} Mach-O slices.")
    for failure in failures:
        print(f"FAIL: {failure}")
    if failures:
        print(f"Deployment mismatch: {len(failures)} slices require a newer OS.")
        return 1
    print("PASS: embedded Mach-O deployment targets do not exceed the advertised minimum.")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    args = parser.parse_args()
    try:
        return verify(args.app)
    except (OSError, ValueError, plistlib.InvalidFileException, subprocess.SubprocessError) as error:
        print(f"Verification incomplete: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
