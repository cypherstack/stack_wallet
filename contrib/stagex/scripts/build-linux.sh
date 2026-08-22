#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

[ "$(uname -s):$(uname -m)" = Linux:x86_64 ] || {
  echo "Linux StageX builds require a Linux x86_64 host." >&2
  exit 69
}
require_docker
require_verified_flutter linux x64

build_image stack-wallet-stagex-linux \
  "$STAGEX_PROJECT_ROOT/containerfiles/linux/Containerfile"
docker run --rm --entrypoint cat stack-wallet-stagex-linux \
  /usr/local/share/stack-stagex-linux-packages.lock \
  | cmp - "$STAGEX_PROJECT_ROOT/contrib/stagex/linux-packages.lock" || {
  echo "Linux package closure differs from the reviewed lock." >&2
  exit 78
}
prepare_flutter_state
trap remove_flutter_state EXIT
safe_remove_output build/linux

docker run --rm \
  --user "$(id -u):$(id -g)" \
  --volume "$STAGEX_PROJECT_ROOT:/workspace" \
  --volume "$STAGEX_PROJECT_ROOT/.flutter-sdk/flutter:/flutter:ro" \
  --volume "$STAGEX_FLUTTER_CACHE:/flutter/bin/cache" \
  --volume "$STAGEX_FLUTTER_TOOLS:/flutter/packages/flutter_tools" \
  --env "STACK_STAGEX_APP=${STACK_STAGEX_APP:-stack_wallet}" \
  --env SOURCE_DATE_EPOCH=1 \
  --env PERL_HASH_SEED=0 \
  --env PERL_PERTURB_KEYS=0 \
  --env CI=true \
  --env FLUTTER_SUPPRESS_ANALYTICS=true \
  --env DART_SUPPRESS_ANALYTICS=true \
  --env CFLAGS="-Wdate-time -ffile-prefix-map=/workspace=." \
  --env CXXFLAGS="-Wdate-time -ffile-prefix-map=/workspace=." \
  --env LDFLAGS="-Wl,--build-id=sha1" \
  --entrypoint /bin/bash \
  stack-wallet-stagex-linux -c '
    set -euo pipefail
    export HOME=/tmp/stack-stagex-home
    export PUB_CACHE=/tmp/stack-stagex-pub
    export CARGO_HOME=/tmp/stack-stagex-cargo
    export GOCACHE=/tmp/stack-stagex-go
    export GOTOOLCHAIN=local
    export GOFLAGS="-modcacherw -trimpath -buildvcs=false"
    mkdir -p "$HOME" "$PUB_CACHE" "$CARGO_HOME" "$GOCACHE"
    cd /workspace/scripts/linux
    USE_SYSTEM_SECURE_STORAGE_DEPS=0 ./build_secure_storage_deps.sh
    cd /workspace
    flutter clean
    flutter pub get --enforce-lockfile
    flutter build linux --release
    artifact="$(find build/linux -path "*/release/bundle/$STACK_STAGEX_APP" -type f -print -quit)"
    [ -n "$artifact" ] && [ -x "$artifact" ] || {
      echo "Linux release artifact not found." >&2
      exit 1
    }
    bundle="$(dirname "$artifact")"
    while IFS= read -r candidate; do
      readelf -h "$candidate" >/dev/null 2>&1 || continue
      if LD_LIBRARY_PATH="$bundle/lib" ldd "$candidate" | grep -q "not found"; then
        echo "Unresolved Linux bundle dependency: $candidate" >&2
        exit 1
      fi
    done < <(find "$bundle" -type f -print)
    camera_dependencies="$(
      LD_LIBRARY_PATH="$bundle/lib" ldd "$bundle/lib/libcamera_linux.so"
    )"
    for library in \
      libopencv_wrapper.so \
      libopencv_core.so.406 \
      libopencv_imgproc.so.406 \
      libopencv_imgcodecs.so.406 \
      libopencv_videoio.so.406; do
      grep -Fq "$bundle/lib/$library" <<< "$camera_dependencies" || {
        echo "Camera dependency is not bundled: $library" >&2
        exit 1
      }
    done
    dart run contrib/stagex/artifact_manifest.dart create \
      "$bundle" build/attestations/linux.manifest
    echo "Build complete: $artifact"
  '

artifact="$(find "$STAGEX_PROJECT_ROOT/build/linux" \
  -path "*/release/bundle/${STACK_STAGEX_APP:-stack_wallet}" \
  -type f -print -quit)"
if ldd "$artifact" | grep -q "not found"; then
  echo "Linux release artifact has unresolved libraries." >&2
  exit 1
fi
