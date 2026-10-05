#!/usr/bin/env bash
set -euo pipefail

# Temporary workaround for https://github.com/flutter/flutter/issues/135673.
# Remove this script when Flutter is updated to 3.49 or later. Then run:
#   flutter test integration_test/desktop_forgot_password -d macos
# Usage: bash scripts/test_desktop_forgot_password.sh [device] [test options]
# Set FLUTTER_BIN to use a Flutter executable other than the one on PATH.

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
reset_test_flutter="${FLUTTER_BIN:-flutter}"
reset_test_device="${1:-macos}"
if (( $# > 0 )); then shift; fi

reset_test_status=0
for reset_test_file in integration_test/desktop_forgot_password/*_test.dart; do
  if [[ ! -f "$reset_test_file" ]]; then
    printf 'No desktop forgot-password test files found.\n' >&2
    exit 2
  fi
  if "$reset_test_flutter" test -d "$reset_test_device" "$reset_test_file" "$@"; then
    continue
  else
    reset_test_exit=$?
    case "$reset_test_exit" in
      130|143) exit "$reset_test_exit" ;;
    esac
    reset_test_status=1
  fi
done
exit "$reset_test_status"
