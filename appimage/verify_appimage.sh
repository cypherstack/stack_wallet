#!/usr/bin/env bash
# Verify the runtime boundary and the executable entry point of an AppImage.
# Usage: appimage/verify_appimage.sh <image.AppImage> <runtime>
set -euo pipefail

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=appimage/lib.sh
source "$script_dir/lib.sh"

if [ $# -ne 2 ]; then
  echo "usage: $0 <image.AppImage> <runtime>" >&2
  exit 1
fi

require_tools cmp dirname mkdir mktemp realpath rm unsquashfs wc

image=$1
runtime=$2
if [ ! -f "$image" ] || [ ! -x "$image" ]; then
  echo "AppImage must be an executable regular file: $image" >&2
  exit 1
fi
if [ ! -f "$runtime" ] || [ -L "$runtime" ]; then
  echo "runtime must be a regular file, not a symbolic link: $runtime" >&2
  exit 1
fi
image=$(realpath -e -- "$image")
runtime=$(realpath -e -- "$runtime")
expected_offset=$(wc -c < "$runtime")

if ! cmp --silent --bytes="$expected_offset" "$runtime" "$image"; then
  echo "AppImage runtime prefix does not match the verified runtime" >&2
  exit 1
fi

workdir=$(mktemp -d "${TMPDIR:-/tmp}/appimage-verify.XXXXXX")
cleanup() {
  rm -rf -- "$workdir"
}
trap cleanup EXIT
(
  cd "$workdir"
  unsquashfs -s -o "$expected_offset" "$image" >/dev/null
  unsquashfs -q -no-progress -o "$expected_offset" \
    -d squashfs-root "$image" AppRun
)
if [ -L "$workdir/squashfs-root/AppRun" ] ||
   [ ! -f "$workdir/squashfs-root/AppRun" ] ||
   [ ! -x "$workdir/squashfs-root/AppRun" ]; then
  echo "AppImage does not contain an executable, non-symbolic AppRun" >&2
  exit 1
fi

# Exercise the hash-verified runtime itself without executing bytes from the
# image. TARGET_APPIMAGE makes the trusted runtime inspect the candidate.
if [ ! -x "$runtime" ]; then
  echo "runtime must be executable: $runtime" >&2
  exit 1
fi
actual_offset=$(TARGET_APPIMAGE="$image" "$runtime" --appimage-offset)
if [ "$actual_offset" != "$expected_offset" ]; then
  echo "AppImage runtime offset is $actual_offset, expected $expected_offset" >&2
  exit 1
fi
runtime_extract="$workdir/runtime-extract"
mkdir "$runtime_extract"
(
  cd "$runtime_extract"
  TARGET_APPIMAGE="$image" "$runtime" --appimage-extract AppRun >/dev/null
)
if [ -L "$runtime_extract/squashfs-root/AppRun" ] ||
   [ ! -f "$runtime_extract/squashfs-root/AppRun" ] ||
   [ ! -x "$runtime_extract/squashfs-root/AppRun" ]; then
  echo "AppImage runtime did not extract an executable, non-symbolic AppRun" >&2
  exit 1
fi
