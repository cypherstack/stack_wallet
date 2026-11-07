#!/usr/bin/env bash
set -euo pipefail

# Checks that a built libgrin_ffi exports the grin-ffi API and no test hooks:
# exactly 36 `grin_` symbols and none starting with `grin_test_`. A library
# built with grin_native's test_utils user-define (scripts/grin_e2e_test.sh)
# fails, which is the point: release bundles must never carry the in-process
# test chain.
#
# Usage: bash scripts/grin_symbol_gate.sh [bundle dir or library file]
# Default: build/linux/x64/release/bundle. Set NM to use another nm.
#
# Linux and Android (.so): `nm -D --defined-only`, as here. llvm-nm from the
# NDK works the same way on Android libraries.
# macOS and iOS (grin_ffi.framework/grin_ffi or .dylib): `nm -gU <file>` or
# `llvm-nm --defined-only --extern-only <file>`; Mach-O names carry a leading
# underscore (`_grin_...`), strip it before counting.
# Windows (grin_ffi.dll): `dumpbin /exports grin_ffi.dll` from a Visual
# Studio prompt, or `llvm-readobj --coff-exports grin_ffi.dll`, and count the
# export names the same way.

expected=36
target="${1:-build/linux/x64/release/bundle}"
nm_bin="${NM:-nm}"

if [[ -d "$target" ]]; then
  mapfile -t found < <(find "$target" -name 'libgrin_ffi.so*' -type f)
  if (( ${#found[@]} != 1 )); then
    printf 'Expected one libgrin_ffi.so under %s, found %d.\n' \
      "$target" "${#found[@]}" >&2
    exit 2
  fi
  lib="${found[0]}"
elif [[ -f "$target" ]]; then
  lib="$target"
else
  printf '%s does not exist.\n' "$target" >&2
  exit 2
fi

symbols="$("$nm_bin" -D --defined-only "$lib" | awk '{print $NF}')"
api=$(grep -c '^grin_' <<<"$symbols" || true)
test_hooks=$(grep -c '^grin_test_' <<<"$symbols" || true)

printf '%s: %d grin_ exports, %d grin_test_ exports\n' "$lib" "$api" "$test_hooks"
status=0
if (( test_hooks != 0 )); then
  printf 'FAIL: built with test_utils:\n' >&2
  grep '^grin_test_' <<<"$symbols" | sed 's/^/  /' >&2
  status=1
fi
if (( api != expected )); then
  printf 'FAIL: expected %d grin_ exports.\n' "$expected" >&2
  status=1
fi
if (( status == 0 )); then printf 'OK\n'; fi
exit "$status"
