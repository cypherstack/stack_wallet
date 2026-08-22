#!/usr/bin/env bash
# Build the Flutter macOS app inside a Nix shell.
# This is a non-interactive build -- suitable for CI.
# Defaults to --pinned for reproducibility.
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
SDK_DIR="$PROJECT_ROOT/.flutter-sdk/flutter"
source "$PROJECT_ROOT/rust_version.env"
source "$PROJECT_ROOT/go_version.env"

[ "$(uname -s)" = Darwin ] || {
    echo "macOS builds require a macOS host with Xcode." >&2
    exit 69
}
if [ ! -d "$SDK_DIR" ]; then
    echo "Flutter SDK not found. Run scripts/fetch-flutter.sh first."
    exit 1
fi

FLAKE_DIR="path:${NIX_FLAKE_DIR:-$PROJECT_ROOT/nix}"

export FLUTTER_NIX_SDK_DIR="$SDK_DIR"
export FLUTTER_NIX_PROJECT_ROOT="$PROJECT_ROOT"
export STACK_NIX_RUST_VERSION="$RUST_VERSION"
export STACK_NIX_GO_VERSION="$GO_VERSION"

BUILD_CMD='
set -euo pipefail
export PATH="$FLUTTER_NIX_SDK_DIR/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_NIX_SDK_DIR"
state_dir="$FLUTTER_NIX_PROJECT_ROOT/.nix-build-state/macos"
rm -rf -- "$state_dir"
cleanup() {
  rm -rf -- "$state_dir" "$FLUTTER_NIX_PROJECT_ROOT/.dart_tool"
  rmdir "$FLUTTER_NIX_PROJECT_ROOT/.nix-build-state" 2>/dev/null || true
  rm -f -- "$FLUTTER_NIX_PROJECT_ROOT/.flutter-plugins-dependencies"
}
trap cleanup EXIT
export PUB_CACHE="$state_dir/pub"
export CARGO_HOME="$state_dir/cargo"
export GOCACHE="$state_dir/go"
export CP_HOME_DIR="$state_dir/cocoapods"
export HOME="$state_dir/home"
export TMPDIR="$state_dir/tmp"
export CARGO_ENCODED_RUSTFLAGS="--remap-path-prefix=$FLUTTER_NIX_PROJECT_ROOT=."
export RUSTUP_HOME="${FLUTTER_NIX_PROJECT_ROOT}/.rustup-nix/${STACK_NIX_RUST_VERSION}"
export STACK_NIX_REAL_RUSTUP="$(command -v rustup)"
export PATH="$FLUTTER_NIX_PROJECT_ROOT/contrib/nix/pinned-bin:$PATH"
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
mkdir -p \
  "$HOME" "$PUB_CACHE" "$CARGO_HOME" "$GOCACHE" "$CP_HOME_DIR" "$TMPDIR"
"$STACK_NIX_REAL_RUSTUP" set auto-self-update disable
"$STACK_NIX_REAL_RUSTUP" toolchain install \
  "$STACK_NIX_RUST_VERSION" --profile minimal
rustup run stable rustc --version \
  | grep -F "rustc $STACK_NIX_RUST_VERSION "
go version | grep -F "go version go$STACK_NIX_GO_VERSION "
cd "$FLUTTER_NIX_PROJECT_ROOT"

echo "--- flutter pub get ---"
flutter clean
flutter pub get --enforce-lockfile

echo "--- flutter build macos ---"
flutter build macos --release

artifact="$(find "$FLUTTER_NIX_PROJECT_ROOT/build/macos/Build/Products/Release" \
  -maxdepth 1 -type d -name \*.app -print -quit)"
[ -d "$artifact" ] || {
  echo "macOS release artifact not found." >&2
  exit 1
}
dart run contrib/nix/artifact_manifest.dart create \
  "$artifact" build/attestations/macos.manifest
echo "Build complete: $artifact"
'

if [ "${1:-}" = "--refresh" ]; then
    echo "Building with latest nixpkgs..."
    nix develop "$FLAKE_DIR" --refresh --command bash -c "$BUILD_CMD"
else
    echo "Building with pinned nixpkgs (from flake.lock)..."
    nix develop "$FLAKE_DIR" --command bash -c "$BUILD_CMD"
fi
