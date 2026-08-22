#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
source "$STAGEX_PROJECT_ROOT/rust_version.env"
source "$STAGEX_PROJECT_ROOT/go_version.env"

[ "$(uname -s)" = Darwin ] || {
  echo "iOS builds require a macOS host with Xcode." >&2
  exit 69
}
command -v xcodebuild >/dev/null || {
  echo "Xcode is required for iOS builds." >&2
  exit 69
}
command -v rustup >/dev/null || {
  echo "rustup is required for iOS builds." >&2
  exit 69
}
case "$(uname -m)" in
  arm64|aarch64) arch=arm64 ;;
  x86_64|amd64) arch=x64 ;;
  *) echo "Unsupported macOS architecture: $(uname -m)." >&2; exit 69 ;;
esac
require_verified_flutter macos "$arch"
go_root="$("$SCRIPT_DIR/fetch-go-apple.sh")"
safe_remove_output build/ios

state="$(mktemp -d "${TMPDIR:-/tmp}/stack-stagex-apple.XXXXXX")"
cleanup() {
  remove_transient_flutter_metadata
  rm -rf -- "$state"
}
trap cleanup EXIT
export HOME="$state/home"
export PUB_CACHE="$state/pub-cache"
export CARGO_HOME="$state/cargo"
export GOCACHE="$state/go"
export CP_HOME_DIR="$state/cocoapods"
export RUSTUP_HOME="$STAGEX_PROJECT_ROOT/.rustup-stagex/$RUST_VERSION"
STACK_STAGEX_REAL_RUSTUP="$(command -v rustup)"
export STACK_STAGEX_REAL_RUSTUP
export STACK_STAGEX_RUST_VERSION="$RUST_VERSION"
export PATH="$STAGEX_PROJECT_ROOT/contrib/stagex/pinned-bin:$go_root/bin:$PATH"
export SOURCE_DATE_EPOCH=1
export PERL_HASH_SEED=0
export PERL_PERTURB_KEYS=0
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true
export GOTOOLCHAIN=local
export GOFLAGS="-modcacherw -trimpath -buildvcs=false"
export ZERO_AR_DATE=1
export COMPILER_INDEX_STORE_ENABLE=NO
mkdir -p "$HOME" "$PUB_CACHE" "$CARGO_HOME" "$GOCACHE" "$CP_HOME_DIR"
go version | grep -F "go version go$GO_VERSION darwin/"
"$STACK_STAGEX_REAL_RUSTUP" set auto-self-update disable
"$STACK_STAGEX_REAL_RUSTUP" toolchain install "$RUST_VERSION" --profile minimal
"$STACK_STAGEX_REAL_RUSTUP" target add aarch64-apple-ios \
  --toolchain "$RUST_VERSION"
rustup run stable rustc --version | grep -F "rustc $RUST_VERSION "

cd "$STAGEX_PROJECT_ROOT"
"$STAGEX_PROJECT_ROOT/.flutter-sdk/flutter/bin/flutter" clean
"$STAGEX_PROJECT_ROOT/.flutter-sdk/flutter/bin/flutter" pub get --enforce-lockfile
"$STAGEX_PROJECT_ROOT/.flutter-sdk/flutter/bin/flutter" \
  build ios --release --no-codesign
artifact="$STAGEX_PROJECT_ROOT/build/ios/iphoneos/Runner.app"
[ -d "$artifact" ] || {
  echo "iOS release artifact not found: $artifact" >&2
  exit 1
}
"$STAGEX_PROJECT_ROOT/.flutter-sdk/flutter/bin/dart" run \
  contrib/stagex/artifact_manifest.dart create \
  "$artifact" build/attestations/ios.manifest
echo "Build complete (unsigned): $artifact"
