#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd)}"
SDK_DIR="${PROJECT_ROOT}/.flutter-sdk/flutter"
FLAKE_DIR="path:${NIX_FLAKE_DIR:-${PROJECT_ROOT}/nix}"

[ "$(uname -s)" = Darwin ] || {
    echo "iOS builds require macOS and Xcode." >&2
    exit 69
}
[ -x "${SDK_DIR}/bin/flutter" ] || {
    echo "Flutter SDK not found. Run fetch-flutter.sh first." >&2
    exit 1
}

export FLUTTER_NIX_SDK_DIR="$SDK_DIR"
export FLUTTER_NIX_PROJECT_ROOT="$PROJECT_ROOT"

nix develop "$FLAKE_DIR" --command bash -c '
set -euo pipefail
export PATH="$FLUTTER_NIX_SDK_DIR/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_NIX_SDK_DIR"
cd "$FLUTTER_NIX_PROJECT_ROOT"
flutter pub get --enforce-lockfile
flutter build ios --release --no-codesign
artifact="$FLUTTER_NIX_PROJECT_ROOT/build/ios/iphoneos/Runner.app"
[ -d "$artifact" ] || {
    echo "iOS release artifact not found: $artifact" >&2
    exit 1
}
'
