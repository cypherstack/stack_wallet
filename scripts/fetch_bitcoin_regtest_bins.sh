#!/usr/bin/env bash
set -euo pipefail

# Fetches the node programs the Bitcoin regtest integration tests use into
# REGTEST_BIN_DIR (default ~/.cache/stack_wallet_regtest), where
# scripts/test_bitcoin_regtest.sh finds them:
#   bitcoind 31.1  release archive from bitcoincore.org, checked against its
#                  SHA256SUMS
#   electrs 0.10.10  built with cargo install (needs Rust and clang); not on
#                    Windows
#   Fulcrum 1.11.1   release archive from GitHub, checked against its shasums;
#                    Linux and Windows, as there is no macOS release
# On Windows run it from Git Bash.
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
archive=tar.gz
exe=
case "$os" in MINGW*|MSYS*|CYGWIN*) os=Windows ;; esac
case "$os/$arch" in
  Linux/x86_64) bitcoin_platform=x86_64-linux-gnu; fulcrum_platform=x86_64-linux ;;
  Linux/aarch64|Linux/arm64) bitcoin_platform=aarch64-linux-gnu; fulcrum_platform=arm64-linux ;;
  Darwin/arm64) bitcoin_platform=arm64-apple-darwin; fulcrum_platform= ;;
  Darwin/x86_64) bitcoin_platform=x86_64-apple-darwin; fulcrum_platform= ;;
  Windows/x86_64) bitcoin_platform=win64; fulcrum_platform=win64; archive=zip; exe=.exe ;;
  *) printf 'Unsupported host %s/%s.\n' "$os" "$arch" >&2; exit 2 ;;
esac

extract() {
  if [[ "$1" == *.zip ]]; then
    if command -v unzip >/dev/null; then
      unzip -q -o "$1" -d "$dir"
    else
      powershell -NoProfile -Command \
        "Expand-Archive -Force -LiteralPath '$(cygpath -w "$1")' -DestinationPath '$(cygpath -w "$dir")'"
    fi
  else
    tar -xzf "$1" -C "$dir"
  fi
}

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
  local tarball="bitcoin-$bitcoin_version-$bitcoin_platform.$archive"
  local out="$dir/bitcoin-$bitcoin_version"
  if [[ -x "$out/bin/bitcoind$exe" ]]; then return; fi
  curl -fsSL --retry 3 -o "$dir/bitcoin-SHA256SUMS" "$base/SHA256SUMS"
  fetch_checked "$base/$tarball" "$dir/$tarball" "$dir/bitcoin-SHA256SUMS"
  extract "$dir/$tarball"
}

fetch_electrs() {
  local out="$dir/electrs-$electrs_version"
  if [[ "$os" == Windows ]]; then
    printf 'electrs does not support Windows; use fulcrum here.\n' >&2
    return
  fi
  if [[ -x "$out/bin/electrs" ]]; then return; fi
  if ! command -v cargo >/dev/null; then
    printf 'electrs needs cargo (https://rustup.rs); skipping it.\n' >&2
    return
  fi
  # On macOS, link against the selected Xcode's SDK. Without this, a newer
  # Command Line Tools SDK than that Xcode's linker understands is picked up
  # and the build fails with "tapi error: malformed file".
  if [[ "$os" == Darwin && -z "${SDKROOT:-}" ]]; then
    SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
    export SDKROOT
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
  local tarball="Fulcrum-$fulcrum_version-$fulcrum_platform.$archive"
  local out="$dir/Fulcrum-$fulcrum_version-$fulcrum_platform"
  if [[ -x "$out/Fulcrum$exe" ]]; then return; fi
  curl -fsSL --retry 3 -o "$dir/fulcrum-shasums.txt" \
    "$base/Fulcrum-$fulcrum_version-shasums.txt"
  fetch_checked "$base/$tarball" "$dir/$tarball" "$dir/fulcrum-shasums.txt"
  extract "$dir/$tarball"
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
for path in "$dir/bitcoin-$bitcoin_version/bin/bitcoind$exe" \
  "$dir/electrs-$electrs_version/bin/electrs" \
  "$dir/Fulcrum-$fulcrum_version-$fulcrum_platform/Fulcrum$exe"; do
  if [[ -x "$path" ]]; then printf '  %s\n' "$path"; fi
done
