#!/usr/bin/env bash
set -euo pipefail

# Fetches the node programs the Bitcoin regtest integration tests use into
# REGTEST_BIN_DIR (default ~/.cache/stack_wallet_regtest), where
# scripts/test_bitcoin_regtest.sh finds them:
#   bitcoind 31.1  release tarball from bitcoincore.org, checked against its
#                  SHA256SUMS
#   electrs 0.10.10  built with cargo install (needs Rust and clang)
#   Fulcrum 1.11.1   release tarball from GitHub, checked against its shasums;
#                    Linux only, as there is no macOS release
# Usage: bash scripts/fetch_bitcoin_regtest_bins.sh [bitcoind] [electrs] [fulcrum]
# With no arguments it fetches all that apply to this host. Works with macOS's
# bash 3.2.

bitcoin_version=31.1
electrs_version=0.10.10
fulcrum_version=1.11.1
dir="${REGTEST_BIN_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/stack_wallet_regtest}"
mkdir -p "$dir"

os="$(uname -s)"
arch="$(uname -m)"
case "$os/$arch" in
  Linux/x86_64) bitcoin_platform=x86_64-linux-gnu; fulcrum_platform=x86_64-linux ;;
  Linux/aarch64|Linux/arm64) bitcoin_platform=aarch64-linux-gnu; fulcrum_platform=arm64-linux ;;
  Darwin/arm64) bitcoin_platform=arm64-apple-darwin; fulcrum_platform= ;;
  Darwin/x86_64) bitcoin_platform=x86_64-apple-darwin; fulcrum_platform= ;;
  *) printf 'Unsupported host %s/%s.\n' "$os" "$arch" >&2; exit 2 ;;
esac

sha256() {
  if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

# Downloads $1 to $2 unless present, then checks it against the sums file $3.
fetch_checked() {
  local url="$1" file="$2" sums="$3" name expected actual
  name="$(basename "$file")"
  if [[ ! -f "$file" ]]; then
    curl -fL --retry 3 -o "$file.part" "$url"
    mv "$file.part" "$file"
  fi
  expected="$(grep -E " [*]?$name\$" "$sums" | cut -d' ' -f1 | head -1)"
  actual="$(sha256 "$file")"
  if [[ -z "$expected" || "$expected" != "$actual" ]]; then
    rm -f "$file"
    printf '%s does not match its published checksum.\n' "$name" >&2
    exit 1
  fi
}

fetch_bitcoind() {
  local base="https://bitcoincore.org/bin/bitcoin-core-$bitcoin_version"
  local tarball="bitcoin-$bitcoin_version-$bitcoin_platform.tar.gz"
  local out="$dir/bitcoin-$bitcoin_version"
  if [[ -x "$out/bin/bitcoind" ]]; then return; fi
  curl -fsSL --retry 3 -o "$dir/bitcoin-SHA256SUMS" "$base/SHA256SUMS"
  fetch_checked "$base/$tarball" "$dir/$tarball" "$dir/bitcoin-SHA256SUMS"
  tar -xzf "$dir/$tarball" -C "$dir"
}

fetch_electrs() {
  local out="$dir/electrs-$electrs_version"
  if [[ -x "$out/bin/electrs" ]]; then return; fi
  if ! command -v cargo >/dev/null; then
    printf 'electrs needs cargo (https://rustup.rs); skipping it.\n' >&2
    return
  fi
  # librocksdb-sys compiles RocksDB, which takes several minutes.
  cargo install --locked electrs --version "$electrs_version" --root "$out"
}

fetch_fulcrum() {
  if [[ -z "$fulcrum_platform" ]]; then
    printf 'Fulcrum has no release for %s; use electrs here.\n' "$os" >&2
    return
  fi
  local base="https://github.com/cculianu/Fulcrum/releases/download/v$fulcrum_version"
  local tarball="Fulcrum-$fulcrum_version-$fulcrum_platform.tar.gz"
  local out="$dir/Fulcrum-$fulcrum_version-$fulcrum_platform"
  if [[ -x "$out/Fulcrum" ]]; then return; fi
  curl -fsSL --retry 3 -o "$dir/fulcrum-shasums.txt" \
    "$base/Fulcrum-$fulcrum_version-shasums.txt"
  fetch_checked "$base/$tarball" "$dir/$tarball" "$dir/fulcrum-shasums.txt"
  tar -xzf "$dir/$tarball" -C "$dir"
}

wanted=("$@")
if (( ${#wanted[@]} == 0 )); then wanted=(bitcoind electrs fulcrum); fi
for program in "${wanted[@]}"; do
  case "$program" in
    bitcoind) fetch_bitcoind ;;
    electrs) fetch_electrs ;;
    fulcrum) fetch_fulcrum ;;
    *) printf 'Unknown program %s.\n' "$program" >&2; exit 2 ;;
  esac
done

printf '\nInstalled in %s. scripts/test_bitcoin_regtest.sh looks there.\n' "$dir"
for path in "$dir/bitcoin-$bitcoin_version/bin/bitcoind" \
  "$dir/electrs-$electrs_version/bin/electrs" \
  "$dir/Fulcrum-$fulcrum_version-$fulcrum_platform/Fulcrum"; do
  [[ -x "$path" ]] && printf '  %s\n' "$path"
done
