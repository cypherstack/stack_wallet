#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
SDK_DIR="$PROJECT_ROOT/.flutter-sdk/flutter"
ANDROID_DIR="$PROJECT_ROOT/.android-sdk"
FLAKE_DIR="path:${NIX_FLAKE_DIR:-$PROJECT_ROOT/nix}"

case "$(uname -s)" in
    Darwin|Linux) ;;
    *) echo "Unsupported OS: $(uname -s)" >&2; exit 69 ;;
esac

[ -x "$SDK_DIR/bin/flutter" ] || {
    echo "Pinned Flutter SDK not found." >&2
    exit 1
}
[ -x "$ANDROID_DIR/cmdline-tools/latest/bin/sdkmanager" ] || {
    echo "Pinned Android SDK not found." >&2
    exit 1
}

export FLUTTER_NIX_FLUTTER_DIR="$SDK_DIR"
export FLUTTER_NIX_ANDROID_DIR="$ANDROID_DIR"
export FLUTTER_NIX_PROJECT_ROOT="$PROJECT_ROOT"

exec nix develop "$FLAKE_DIR#android" --command bash -c '
set -euo pipefail
export PATH="$FLUTTER_NIX_FLUTTER_DIR/bin:$JAVA_HOME/bin:$FLUTTER_NIX_ANDROID_DIR/platform-tools:$FLUTTER_NIX_ANDROID_DIR/cmdline-tools/latest/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_NIX_FLUTTER_DIR"
export ANDROID_HOME="$FLUTTER_NIX_ANDROID_DIR"
export ANDROID_SDK_ROOT="$FLUTTER_NIX_ANDROID_DIR"
export STACK_ALLOW_UNSIGNED_ANDROID=1
cd "$FLUTTER_NIX_PROJECT_ROOT"
flutter pub get --enforce-lockfile
flutter build apk --release
artifact="$FLUTTER_NIX_PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk"
[ -s "$artifact" ] || {
    echo "Android release artifact not found: $artifact" >&2
    exit 1
}
'
