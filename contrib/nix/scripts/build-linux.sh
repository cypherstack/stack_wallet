#!/usr/bin/env bash
# Build the Flutter Linux app inside a Nix shell.
# This is a non-interactive build -- suitable for CI.
# Defaults to --pinned for reproducibility.
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
SDK_DIR="$PROJECT_ROOT/.flutter-sdk/flutter"

[ "$(uname -s)" = Linux ] || {
    echo "Linux builds require a Linux host." >&2
    exit 69
}
if [ ! -d "$SDK_DIR" ]; then
    echo "Flutter SDK not found. Run scripts/fetch-flutter-linux.sh first."
    exit 1
fi

FLAKE_DIR="path:${NIX_FLAKE_DIR:-$PROJECT_ROOT/nix}"

export FLUTTER_NIX_SDK_DIR="$SDK_DIR"
export FLUTTER_NIX_PROJECT_ROOT="$PROJECT_ROOT"

BUILD_CMD='
set -euo pipefail
export PATH="$FLUTTER_NIX_SDK_DIR/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_NIX_SDK_DIR"
export USE_SYSTEM_SECURE_STORAGE_DEPS=1
cd "$FLUTTER_NIX_PROJECT_ROOT"

echo "--- Checking for Linux desktop support ---"
if [ ! -d linux ]; then
  echo "Creating Linux desktop project..."
  flutter create --platforms=linux .
else
  echo "Linux desktop project already exists."
fi

echo "--- flutter pub get ---"
flutter pub get --enforce-lockfile

echo "--- flutter build linux ---"
flutter build linux --release

binary_name="${STACK_NIX_APP:-stack_wallet}"
artifact="$(find build/linux -path "*/release/bundle/$binary_name" -type f -print -quit)"
[ -n "$artifact" ] && [ -x "$artifact" ] || {
  echo "Linux release artifact not found." >&2
  exit 1
}
echo "Build complete: $artifact"
'

if [ "${1:-}" = "--refresh" ]; then
    echo "Building with latest nixpkgs..."
    nix develop "$FLAKE_DIR#linux" --refresh --command bash -c "$BUILD_CMD"
else
    echo "Building with pinned nixpkgs (from flake.lock)..."
    nix develop "$FLAKE_DIR#linux" --command bash -c "$BUILD_CMD"
fi
