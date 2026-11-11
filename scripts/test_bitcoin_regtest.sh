#!/usr/bin/env bash
set -euo pipefail

# Runs integration_test/bitcoin_regtest against a private regtest chain:
# bitcoind plus an Electrum server, fresh for every test file.
# Usage: bash scripts/test_bitcoin_regtest.sh [device] [flutter test options]
# Works with macOS's bash 3.2.
#
# device is a flutter device id; it defaults to the host (linux, macos or
# windows). For an iOS simulator or Android emulator id, set REGTEST_TARGET to
# ios or android.
# INDEXER is electrs (default; fulcrum on Windows), fulcrum, or all to run
# every file against both. On Windows run it from Git Bash.
# BITCOIND, ELECTRS and FULCRUM name the binaries; otherwise they come from
# PATH (bitcoind, electrs, Fulcrum) or from scripts/fetch_bitcoin_regtest_bins.sh.
# Only the selected indexers are needed.
# Set FLUTTER_BIN to use a Flutter executable other than the one on PATH.
#
# On Linux and Windows the test starts the nodes itself. The macOS app is
# sandboxed and mobile targets cannot start host programs, so for those the
# nodes run on this host (scripts/bitcoin_regtest_nodes.dart) and the test
# connects to them. REGTEST_HOST_NODES=1 does the same on Linux and Windows.

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
flutter_bin="${FLUTTER_BIN:-flutter}"
dart_bin="$(dirname -- "$(command -v "$flutter_bin")")/dart"
[[ -x "$dart_bin" ]] || dart_bin=dart
# Where scripts/fetch_bitcoin_regtest_bins.sh puts them.
bins="${REGTEST_BIN_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/stack_wallet_regtest}"
first_executable() {
  local path
  for path in "$@"; do
    if [[ -n "$path" && -x "$path" ]]; then printf '%s' "$path"; return; fi
  done
}
bitcoind="${BITCOIND:-$(first_executable "$(command -v bitcoind || true)" "$bins"/bitcoin-*/bin/bitcoind "$bins"/bitcoin-*/bin/bitcoind.exe)}"
electrs="${ELECTRS:-$(first_executable "$(command -v electrs || true)" "$bins"/electrs-*/bin/electrs)}"
fulcrum="${FULCRUM:-$(first_executable "$(command -v Fulcrum || true)" "$bins"/Fulcrum-*/Fulcrum "$bins"/Fulcrum-*/Fulcrum.exe)}"
host_os="$(uname -s | tr '[:upper:]' '[:lower:]' | sed -E 's/darwin/macos/; s/^(mingw|msys|cygwin).*/windows/')"
device="${1:-$host_os}"
if (( $# > 0 )); then shift; fi

case "$device" in
  linux|macos|windows) target="$device" ;;
  *) target="${REGTEST_TARGET:-}" ;;
esac
case "$target" in
  linux|windows) host_nodes=0; node_host=127.0.0.1 ;;
  macos|ios) host_nodes=1; node_host=127.0.0.1 ;;
  # The Android emulator reaches the host's loopback as 10.0.2.2.
  android) host_nodes=1; node_host=10.0.2.2 ;;
  *) printf 'Set REGTEST_TARGET to ios or android for device %s.\n' "$device" >&2; exit 2 ;;
esac
# REGTEST_HOST_NODES=1 runs the nodes on the host for desktop targets too.
[[ "${REGTEST_HOST_NODES:-0}" == 1 ]] && host_nodes=1

# electrs has no Windows build, so Windows defaults to Fulcrum.
default_indexer=electrs
[[ "$target" == windows ]] && default_indexer=fulcrum
case "${INDEXER:-$default_indexer}" in
  electrs) indexers=(electrs) ;;
  fulcrum) indexers=(fulcrum) ;;
  all) indexers=(electrs fulcrum) ;;
  *) printf 'INDEXER must be electrs, fulcrum or all.\n' >&2; exit 2 ;;
esac

for name in bitcoind "${indexers[@]}"; do
  path="${!name}"
  if [[ -z "$path" || ! -x "$path" ]]; then
    printf 'No %s found. Run scripts/fetch_bitcoin_regtest_bins.sh or set %s.\n' \
      "$name" "$(tr '[:lower:]' '[:upper:]' <<<"$name")" >&2
    exit 2
  fi
done

runner=()
if [[ "$target" == linux && -z "${DISPLAY:-}" ]] && command -v xvfb-run >/dev/null; then
  runner=(xvfb-run -a)
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/stack_btc_regtest_run.XXXXXX")"
nodes_pid=""
nodes_stop_file=""
stop_nodes() {
  if [[ -n "$nodes_pid" ]]; then
    if [[ -n "$nodes_stop_file" ]]; then
      touch "$nodes_stop_file"
    else
      kill -TERM "$nodes_pid" 2>/dev/null || true
    fi
    for _ in $(seq 60); do
      kill -0 "$nodes_pid" 2>/dev/null || break
      sleep 0.5
    done
    kill -KILL "$nodes_pid" 2>/dev/null || true
    wait "$nodes_pid" 2>/dev/null || true
    nodes_pid=""
    nodes_stop_file=""
  fi
}
cleanup() { stop_nodes; rm -rf -- "$work"; }
trap cleanup EXIT

if (( host_nodes )); then
  nodes_bin="$work/bitcoin_regtest_nodes"
  "$dart_bin" compile exe scripts/bitcoin_regtest_nodes.dart -o "$nodes_bin" >/dev/null
fi

# Starts the nodes for one test file and sets node_defines.
start_nodes() {
  local indexer="$1" path="$2" log="$work/nodes.log"
  local stop_args=(--until-signal)
  if [[ "$host_os" == windows ]]; then
    nodes_stop_file="$work/stop-nodes"
    rm -f "$nodes_stop_file"
    # Native Dart cannot observe POSIX Git Bash paths directly.
    stop_args=(--stop-file "$(cygpath -w "$nodes_stop_file")")
  fi
  rm -f "$log"
  "$nodes_bin" --bitcoind "$bitcoind" --indexer "$indexer" --indexer-path "$path" \
    "${stop_args[@]}" < /dev/null > "$log" 2>&1 &
  nodes_pid=$!
  for _ in $(seq 360); do
    grep -q '^REGTEST_READY ' "$log" 2>/dev/null && break
    if ! kill -0 "$nodes_pid" 2>/dev/null; then
      cat "$log" >&2; nodes_pid=""; return 1
    fi
    sleep 0.5
  done
  local ready
  ready="$(grep -m1 '^REGTEST_READY ' "$log" || true)"
  if [[ -z "$ready" ]]; then
    printf 'The regtest nodes did not start:\n' >&2; cat "$log" >&2; return 1
  fi
  field() { sed -E "s/.*\"$1\":\"?([^\",}]*)\"?.*/\\1/" <<<"$ready"; }
  node_defines=(
    --dart-define=REGTEST_RPC_HOST="$node_host"
    --dart-define=REGTEST_RPC_PORT="$(field rpcPort)"
    --dart-define=REGTEST_RPC_USER="$(field rpcUser)"
    --dart-define=REGTEST_RPC_PASSWORD="$(field rpcPassword)"
    --dart-define=REGTEST_ELECTRUM_HOST="$node_host"
    --dart-define=REGTEST_ELECTRUM_PORT="$(field electrumPort)"
  )
}

# One file per flutter test run: https://github.com/flutter/flutter/issues/135673
status=0
for indexer in "${indexers[@]}"; do
  indexer_path="$electrs"
  [[ "$indexer" == fulcrum ]] && indexer_path="$fulcrum"
  for test_file in integration_test/bitcoin_regtest/*_test.dart; do
    if [[ "$test_file" == */desktop_* && ( "$target" == ios || "$target" == android ) ]]; then
      continue
    fi
    printf '== %s with %s\n' "$test_file" "$indexer"
    node_defines=(
      --dart-define=BITCOIND="$bitcoind"
      --dart-define=ELECTRS="$electrs"
      --dart-define=FULCRUM="$fulcrum"
    )
    if (( host_nodes )) && ! start_nodes "$indexer" "$indexer_path"; then
      status=1
      continue
    fi
    # ${a[@]+...} keeps bash 3.2 (macOS) from calling an empty array unbound.
    if ${runner[@]+"${runner[@]}"} "$flutter_bin" test -d "$device" "$test_file" \
      --dart-define=STACK_BITCOIN_REGTEST=true \
      --dart-define=INDEXER="$indexer" \
      "${node_defines[@]}" \
      "$@"; then
      code=0
    else
      code=$?
    fi
    # flutter test can leave the macOS app running after the test ends. Only
    # this checkout's own debug build is stopped.
    if [[ "$target" == macos ]]; then
      pkill -f "$PWD/build/macos/Build/Products/Debug/" 2>/dev/null || true
    fi
    stop_nodes
    if (( code != 0 && host_nodes )) && [[ -f "$work/nodes.log" ]]; then
      printf -- '--- regtest node log\n' >&2
      tail -n 60 "$work/nodes.log" >&2
    fi
    case "$code" in
      0) ;;
      130|143) exit "$code" ;;
      *) status=1 ;;
    esac
  done
done
exit "$status"
