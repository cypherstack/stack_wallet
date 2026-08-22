#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

[ "$(uname -s):$(uname -m)" = Linux:x86_64 ] || {
  echo "Android StageX builds require a Linux x86_64 host." >&2
  exit 69
}
require_docker
require_verified_flutter linux x64
[ ! -f "$STAGEX_PROJECT_ROOT/android/key.properties" ] || {
  echo "StageX Android builds require an unsigned checkout; remove android/key.properties." >&2
  exit 78
}
build_image stack-wallet-stagex-android \
  "$STAGEX_PROJECT_ROOT/containerfiles/android/Containerfile"
docker run --rm --entrypoint cat stack-wallet-stagex-android \
  /usr/local/share/stack-stagex-android-packages.lock \
  | cmp - "$STAGEX_PROJECT_ROOT/contrib/stagex/android-packages.lock" || {
  echo "Android package closure differs from the reviewed lock." >&2
  exit 78
}

mkdir -p "$STAGEX_PROJECT_ROOT/.android-sdk"
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --volume "$STAGEX_PROJECT_ROOT:/workspace" \
  --volume "$STAGEX_PROJECT_ROOT/.android-sdk:/android-sdk" \
  --env HOME=/tmp/stack-stagex-home \
  --env ANDROID_HOME=/android-sdk \
  --env ANDROID_SDK_ROOT=/android-sdk \
  --entrypoint /bin/bash \
  stack-wallet-stagex-android -c '
    set -euo pipefail
    mkdir -p "$HOME"
    PROJECT_ROOT=/workspace /workspace/contrib/stagex/scripts/fetch-android-sdk.sh
  '

prepare_flutter_state
trap remove_flutter_state EXIT
safe_remove_output build
safe_remove_output android/.gradle

docker run --rm \
  --user "$(id -u):$(id -g)" \
  --volume "$STAGEX_PROJECT_ROOT:/workspace" \
  --volume "$STAGEX_PROJECT_ROOT/.flutter-sdk/flutter:/flutter:ro" \
  --volume "$STAGEX_FLUTTER_CACHE:/flutter/bin/cache" \
  --volume "$STAGEX_FLUTTER_TOOLS:/flutter/packages/flutter_tools" \
  --volume "$STAGEX_PROJECT_ROOT/.android-sdk:/android-sdk" \
  --env SOURCE_DATE_EPOCH=1 \
  --env PERL_HASH_SEED=0 \
  --env PERL_PERTURB_KEYS=0 \
  --env STACK_ALLOW_UNSIGNED_ANDROID=1 \
  --env CI=true \
  --env FLUTTER_SUPPRESS_ANALYTICS=true \
  --env DART_SUPPRESS_ANALYTICS=true \
  --env HOME=/tmp/stack-stagex-home \
  --env GRADLE_USER_HOME=/tmp/stack-stagex-gradle \
  --env PUB_CACHE=/tmp/stack-stagex-pub \
  --env CARGO_HOME=/tmp/stack-stagex-cargo \
  --env GOCACHE=/tmp/stack-stagex-go \
  --env GOTOOLCHAIN=local \
  --env "GOFLAGS=-modcacherw -trimpath -buildvcs=false" \
  --entrypoint /bin/bash \
  stack-wallet-stagex-android -c '
    set -euo pipefail
    mkdir -p "$HOME" "$GRADLE_USER_HOME" "$PUB_CACHE" "$CARGO_HOME" "$GOCACHE"
    cd /workspace
    flutter clean
    flutter pub get --enforce-lockfile
    flutter build apk --release
    artifact=/workspace/build/app/outputs/flutter-apk/app-release.apk
    [ -s "$artifact" ] || {
      echo "Android release artifact not found: $artifact" >&2
      exit 1
    }
    if /android-sdk/build-tools/35.0.0/apksigner verify "$artifact" \
      >/dev/null 2>&1; then
      echo "Expected an unsigned Android artifact, but APK signing verified." >&2
      exit 1
    fi
    dart run contrib/stagex/artifact_manifest.dart create \
      "$artifact" build/attestations/android.manifest
  '

artifact="$STAGEX_PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk"
unzip -tq "$artifact" >/dev/null
echo "Build complete (unsigned): $artifact"
