#!/usr/bin/env bash
# Build the Flutter macOS app inside a Nix shell.
# This is a non-interactive build -- suitable for CI.
# Defaults to --pinned for reproducibility.
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
SDK_DIR="$PROJECT_ROOT/.flutter-sdk/flutter"

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

BUILD_CMD='
set -euo pipefail
export PATH="$FLUTTER_NIX_SDK_DIR/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_NIX_SDK_DIR"
cd "$FLUTTER_NIX_PROJECT_ROOT"

echo "--- flutter pub get ---"
flutter pub get --enforce-lockfile

echo "--- flutter build macos ---"
flutter build macos --release

artifact="$(find "$FLUTTER_NIX_PROJECT_ROOT/build/macos/Build/Products/Release" \
  -maxdepth 1 -type d -name \*.app -print -quit)"
[ -d "$artifact" ] || {
  echo "macOS release artifact not found." >&2
  exit 1
}
echo "Build complete: $artifact"
'

if [ "${1:-}" = "--refresh" ]; then
    echo "Building with latest nixpkgs..."
    nix develop "$FLAKE_DIR" --refresh --command bash -c "$BUILD_CMD"
else
    echo "Building with pinned nixpkgs (from flake.lock)..."
    nix develop "$FLAKE_DIR" --command bash -c "$BUILD_CMD"
fi
