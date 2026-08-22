#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
SDK_DIR="$PROJECT_ROOT/.flutter-sdk/flutter"
ANDROID_DIR="$PROJECT_ROOT/.android-sdk"
FLAKE_DIR="path:${NIX_FLAKE_DIR:-$PROJECT_ROOT/nix}"
source "$PROJECT_ROOT/rust_version.env"
source "$PROJECT_ROOT/go_version.env"

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
[ ! -f "$PROJECT_ROOT/android/key.properties" ] || {
    echo "Nix reproducibility builds require an unsigned Android checkout." >&2
    exit 78
}

export FLUTTER_NIX_FLUTTER_DIR="$SDK_DIR"
export FLUTTER_NIX_ANDROID_DIR="$ANDROID_DIR"
export FLUTTER_NIX_PROJECT_ROOT="$PROJECT_ROOT"
export STACK_NIX_RUST_VERSION="$RUST_VERSION"
export STACK_NIX_GO_VERSION="$GO_VERSION"

exec nix develop "$FLAKE_DIR#android" --command bash -c '
set -euo pipefail
export PATH="$FLUTTER_NIX_FLUTTER_DIR/bin:$JAVA_HOME/bin:$FLUTTER_NIX_ANDROID_DIR/platform-tools:$FLUTTER_NIX_ANDROID_DIR/cmdline-tools/latest/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_NIX_FLUTTER_DIR"
export ANDROID_HOME="$FLUTTER_NIX_ANDROID_DIR"
export ANDROID_SDK_ROOT="$FLUTTER_NIX_ANDROID_DIR"
export STACK_ALLOW_UNSIGNED_ANDROID=1
state_dir="$FLUTTER_NIX_PROJECT_ROOT/.nix-build-state/android"
rm -rf -- "$state_dir"
cleanup() {
  rm -rf -- "$state_dir" "$FLUTTER_NIX_PROJECT_ROOT/.dart_tool"
  rmdir "$FLUTTER_NIX_PROJECT_ROOT/.nix-build-state" 2>/dev/null || true
  rm -f -- "$FLUTTER_NIX_PROJECT_ROOT/.flutter-plugins-dependencies"
}
trap cleanup EXIT
export HOME="$state_dir/home"
export PUB_CACHE="$state_dir/pub"
export CARGO_HOME="$state_dir/cargo"
export GOCACHE="$state_dir/go"
export GRADLE_USER_HOME="$state_dir/gradle"
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
export GRADLE_OPTS="-Dorg.gradle.daemon=false -Dorg.gradle.caching=false"
mkdir -p \
  "$HOME" "$PUB_CACHE" "$CARGO_HOME" "$GOCACHE" "$GRADLE_USER_HOME" \
  "$TMPDIR"
"$STACK_NIX_REAL_RUSTUP" set auto-self-update disable
"$STACK_NIX_REAL_RUSTUP" toolchain install \
  "$STACK_NIX_RUST_VERSION" --profile minimal \
  --target armv7-linux-androideabi \
  --target aarch64-linux-android \
  --target x86_64-linux-android
rustup run stable rustc --version \
  | grep -F "rustc $STACK_NIX_RUST_VERSION "
go version | grep -F "go version go$STACK_NIX_GO_VERSION "
cd "$FLUTTER_NIX_PROJECT_ROOT"
flutter clean
flutter pub get --enforce-lockfile
flutter build apk --release
artifact="$FLUTTER_NIX_PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk"
[ -s "$artifact" ] || {
    echo "Android release artifact not found: $artifact" >&2
    exit 1
}
if "$FLUTTER_NIX_ANDROID_DIR/build-tools/35.0.0/apksigner" \
    verify "$artifact" >/dev/null 2>&1; then
    echo "Expected an unsigned Android artifact, but APK signing verified." >&2
    exit 1
fi
"$FLUTTER_NIX_ANDROID_DIR/cmdline-tools/latest/bin/apkanalyzer" \
  files list "$artifact" >/dev/null
dart run contrib/nix/artifact_manifest.dart create \
  "$artifact" build/attestations/android.manifest
echo "Build complete (unsigned): $artifact"
'
