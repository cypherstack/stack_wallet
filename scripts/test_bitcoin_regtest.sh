#!/usr/bin/env bash
set -euo pipefail

# Runs integration_test/bitcoin_regtest against a private regtest chain that
# each test file starts itself: bitcoind plus an Electrum server on free ports.
# Usage: bash scripts/test_bitcoin_regtest.sh [device] [flutter test options]
# INDEXER is electrs (default), fulcrum, or all to run every file against both.
# BITCOIND, ELECTRS and FULCRUM name the binaries; otherwise they come from
# PATH (bitcoind, electrs, Fulcrum). Only the selected indexers are needed.
# Set FLUTTER_BIN to use a Flutter executable other than the one on PATH.

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
flutter_bin="${FLUTTER_BIN:-flutter}"
bitcoind="${BITCOIND:-$(command -v bitcoind || true)}"
electrs="${ELECTRS:-$(command -v electrs || true)}"
fulcrum="${FULCRUM:-$(command -v Fulcrum || true)}"
device="${1:-$(uname -s | tr '[:upper:]' '[:lower:]' | sed 's/darwin/macos/')}"
if (( $# > 0 )); then shift; fi

case "${INDEXER:-electrs}" in
  electrs) indexers=(electrs) ;;
  fulcrum) indexers=(fulcrum) ;;
  all) indexers=(electrs fulcrum) ;;
  *) printf 'INDEXER must be electrs, fulcrum or all.\n' >&2; exit 2 ;;
esac

for name in bitcoind "${indexers[@]}"; do
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
for indexer in "${indexers[@]}"; do
  for test_file in integration_test/bitcoin_regtest/*_test.dart; do
    printf '== %s with %s\n' "$test_file" "$indexer"
    if "${runner[@]}" "$flutter_bin" test -d "$device" "$test_file" \
      --dart-define=STACK_BITCOIN_REGTEST=true \
      --dart-define=INDEXER="$indexer" \
      --dart-define=BITCOIND="$bitcoind" \
      --dart-define=ELECTRS="$electrs" \
      --dart-define=FULCRUM="$fulcrum" \
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
done
exit "$status"
