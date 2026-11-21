#!/usr/bin/env bash
set -euo pipefail

# Runs the Grin end-to-end suite (integration_test/grin) against the real
# grin-ffi library on its in-process test chain.
#
# That chain exists only in a library built with grin_native's test_utils
# user-define. This script adds the define to the generated pubspec.yaml,
# runs the suite, and puts pubspec.yaml and pubspec.lock back however the run
# ends. The define never goes into the committed template, and release builds
# must not have it (scripts/grin_symbol_gate.sh checks).
#
# The first run compiles the library a second time with the feature on; the
# build hook keeps both builds under .dart_tool, so later runs and normal
# builds reuse them. The run leaves the test library in the app bundle under
# build/, so the script removes every Grin library from build/ when it ends.
# The next normal build puts the release library back; a bundle packaged
# without building again fails to load Grin instead of shipping the test
# chain.
#
# A run that is killed outright (SIGKILL, power loss) cannot clean up. Then
# pubspec.yaml still has the define and build/ still has the test library:
# configure the app again (scripts/build_app.sh) and delete build/ before
# building anything that will be distributed.
#
# Usage: bash scripts/grin_e2e_test.sh [device] [flutter test options]
# The device defaults to the host desktop. Set FLUTTER_BIN to use a Flutter
# executable other than the one on PATH.

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

flutter_bin="${FLUTTER_BIN:-flutter}"
case "$(uname -s)" in
  Linux*) default_device=linux ;;
  Darwin*) default_device=macos ;;
  *) default_device=windows ;;
esac
device="${1:-$default_device}"
if (( $# > 0 )); then shift; fi

if [[ ! -f pubspec.yaml ]]; then
  printf 'pubspec.yaml not found. Configure the app first (scripts/build_app.sh).\n' >&2
  exit 1
fi
if ! grep -q '^  grin_native:' pubspec.yaml; then
  printf 'grin_native is not a dependency. Configure an app with GRIN enabled.\n' >&2
  exit 1
fi
if grep -q 'test_utils' pubspec.yaml; then
  printf 'pubspec.yaml already mentions test_utils. Remove it and run again.\n' >&2
  exit 1
fi

backup_dir="$(mktemp -d "${TMPDIR:-/tmp}/grin_e2e.XXXXXX")"
cp pubspec.yaml "$backup_dir/pubspec.yaml"
if [[ -f pubspec.lock ]]; then cp pubspec.lock "$backup_dir/pubspec.lock"; fi

restore() {
  cp "$backup_dir/pubspec.yaml" pubspec.yaml
  if [[ -f "$backup_dir/pubspec.lock" ]]; then
    cp "$backup_dir/pubspec.lock" pubspec.lock
  else
    rm -f -- pubspec.lock
  fi
  rm -rf -- "$backup_dir"
  remove_test_libraries
}

# Deletes the Grin libraries the run left under build/. They were built with
# the test chain and must not be packaged.
remove_test_libraries() {
  [[ -d build ]] || return 0
  find build -depth \( -name 'libgrin_ffi.so' -o -name 'libgrin_ffi.dylib' \
    -o -name 'grin_ffi.dll' -o -name 'grin_ffi.framework' \
    -o -name 'grin_ffi.framework.dSYM' \) -exec rm -rf -- {} + || true
}
trap restore EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Adds hooks.user_defines.grin_native.test_utils: true, inside an existing
# hooks block (the native prebuilts one) or as a new block at the end.
python3 - pubspec.yaml <<'PY'
import sys

path = sys.argv[1]
with open(path) as f:
    lines = f.read().split("\n")

entry = ["    grin_native:", "      test_utils: true"]
try:
    hooks = lines.index("hooks:")
except ValueError:
    hooks = None

if hooks is None:
    while lines and lines[-1] == "":
        lines.pop()
    lines += ["", "hooks:", "  user_defines:"] + entry + [""]
else:
    end = hooks + 1
    while end < len(lines) and (lines[end].startswith(" ") or lines[end] == ""):
        end += 1
    block = lines[hooks + 1:end]
    if "  user_defines:" in block:
        at = hooks + 1 + block.index("  user_defines:") + 1
        lines[at:at] = entry
    else:
        lines[hooks + 1:hooks + 1] = ["  user_defines:"] + entry

with open(path, "w") as f:
    f.write("\n".join(lines))
PY

"$flutter_bin" test integration_test/grin/grin_test_chain_test.dart \
  -d "$device" "$@"
