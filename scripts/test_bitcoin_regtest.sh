#!/usr/bin/env bash
set -euo pipefail

# Runs integration_test/bitcoin_regtest against a private regtest chain that
# each test file starts itself (bitcoind plus electrs 0.10 on free ports).
# Usage: bash scripts/test_bitcoin_regtest.sh [device] [flutter test options]
# BITCOIND and ELECTRS name the binaries; otherwise they are taken from PATH.
# Set FLUTTER_BIN to use a Flutter executable other than the one on PATH.

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
flutter_bin="${FLUTTER_BIN:-flutter}"
bitcoind="${BITCOIND:-$(command -v bitcoind || true)}"
electrs="${ELECTRS:-$(command -v electrs || true)}"
device="${1:-$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/macos/')}"
if (( $# > 0 )); then shift; fi

for name in bitcoind electrs; do
  path="${!name}"
  if [[ -z "$path" || ! -x "$path" ]]; then
    printf 'Set %s to a %s executable.\n' "${name^^}" "$name" >&2
    exit 2
  fi
done

runner=()
if [[ "$device" == linux && -z "${DISPLAY:-}" ]] && command -v xvfb-run >/dev/null; then
  runner=(xvfb-run -a)
fi

# One file per flutter test run: https://github.com/flutter/flutter/issues/135673
status=0
for test_file in integration_test/bitcoin_regtest/*_test.dart; do
  if "${runner[@]}" "$flutter_bin" test -d "$device" "$test_file" \
    --dart-define=STACK_BITCOIN_REGTEST=true \
    --dart-define=BITCOIND="$bitcoind" \
    --dart-define=ELECTRS="$electrs" \
    "$@"; then
    continue
  else
    code=$?
    case "$code" in
      130|143) exit "$code" ;;
    esac
    status=1
  fi
done
exit "$status"
