#!/usr/bin/env bash
set -euo pipefail

mkdir -p build
echo "$(git log -1 --pretty=format:%H) $(date)" >> build/git_commit_version.txt

VERSIONS_FILE=../../lib/git_versions.dart
EXAMPLE_VERSIONS_FILE=../../lib/git_versions_example.dart
if [ ! -f "$VERSIONS_FILE" ]; then
  cp "$EXAMPLE_VERSIONS_FILE" "$VERSIONS_FILE"
fi

COMMIT=$(git log -1 --pretty=format:%H)
OSX="OSX"
sed -i.bak "s|/\*${OSX}_VERSION\*/.*|/\*${OSX}_VERSION\*/ const ${OSX}_VERSION = \"$COMMIT\";|g" "$VERSIONS_FILE"
rm -f "${VERSIONS_FILE}.bak"

rm -rf build/rust
cp -r ../../rust build/rust
cd build/rust

mkdir -p target
unset MAKEFLAGS MFLAGS CARGO_MAKEFLAGS MAKELEVEL MAKE_TERMOUT MAKE_TERMERR
export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-11.0}"
export CARGO_TARGET_DIR="$(mktemp -d "${TMPDIR:-/tmp}/epiccash-target.XXXXXX")"
mkdir -p "${CARGO_TARGET_DIR}/aarch64-apple-darwin/release/deps"

run_cargo_build() {
  env -u MAKEFLAGS -u MFLAGS -u CARGO_MAKEFLAGS -u MAKELEVEL -u MAKE_TERMOUT -u MAKE_TERMERR \
    cargo build --release --target aarch64-apple-darwin --lib
}

if ! run_cargo_build; then
  echo "Warning: cargo build failed once; retrying after recreating target dirs..."
  mkdir -p "${CARGO_TARGET_DIR}/aarch64-apple-darwin/release/deps"
  run_cargo_build
fi

cbindgen --config cbindgen.toml --crate epic-cash-wallet --output target/epic_cash_wallet.h
cp target/epic_cash_wallet.h libepic_cash_wallet.h
mkdir -p Headers
cp target/epic_cash_wallet.h Headers/libepic_cash_wallet.h
cp target/epic_cash_wallet.h ../../../../macos/Classes/FlutterLibepiccashPlugin.h

BASE_LIB="${CARGO_TARGET_DIR}/aarch64-apple-darwin/release/libepic_cash_wallet.a"
RANDOMX_LIB=$(find "${CARGO_TARGET_DIR}/aarch64-apple-darwin/release/build" -name "librandomx.a" | head -n 1 || true)
if [ -n "${RANDOMX_LIB}" ] && [ -f "${RANDOMX_LIB}" ]; then
  echo "Found RandomX library at: ${RANDOMX_LIB}"
  COMBINED_LIB="${CARGO_TARGET_DIR}/aarch64-apple-darwin/release/libepic_cash_wallet_combined.a"
  if /usr/bin/libtool -static -o "${COMBINED_LIB}" \
      "${BASE_LIB}" \
      "${RANDOMX_LIB}" && \
     [ -f "${COMBINED_LIB}" ]; then
    /usr/bin/ranlib "${COMBINED_LIB}" || true
    if /usr/bin/ar -t "${COMBINED_LIB}" >/dev/null 2>&1; then
      MAIN_LIB="${COMBINED_LIB}"
    else
      echo "Warning: combined archive is invalid, falling back to libepic_cash_wallet.a"
      MAIN_LIB="${BASE_LIB}"
    fi
  else
    echo "Warning: failed to create combined archive, falling back to libepic_cash_wallet.a"
    MAIN_LIB="${BASE_LIB}"
  fi
else
  echo "Warning: librandomx.a not found, using libepic_cash_wallet.a only"
  MAIN_LIB="${BASE_LIB}"
fi

xcodebuild -create-xcframework \
  -library "${MAIN_LIB}" \
  -headers libepic_cash_wallet.h \
  -output ../EpicWallet.xcframework

fwk=../../../../macos/framework
rm -rf "${fwk}"
mkdir -p "${fwk}"
mv ../EpicWallet.xcframework "${fwk}"
