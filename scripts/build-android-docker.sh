#!/usr/bin/env bash
#
# BitFinite native wallet — Dockerized Android build (Stack Wallet fork toolchain).
#
# Mirrors the webwallet's Capacitor Docker build: no host Flutter/SDK/Rust needed.
# Uses the fork's own multi-stage Dockerfile (`--target android`) — or, by default,
# PULLS the upstream prebuilt CI image to skip the ~30-45 min local image build.
#
# Usage:
#   scripts/build-android-docker.sh            # debug APK (default)
#   scripts/build-android-docker.sh profile    # release-speed APK you can profile and time
#   scripts/build-android-docker.sh release    # split-per-abi release APKs (unsigned unless keystore wired)
#
# Use `profile` for any measurement. A debug build runs the Dart VM in JIT with
# assertions enabled and is several times slower than what a user gets, so
# timings taken from one are not evidence about the app.
#
# Env overrides:
#   BUILD_IMAGE=1   force a local `docker build` instead of pulling
#   BFX_CI_IMAGE=…  override the image ref (default: upstream cypherstack CI image)
#   BFX_PLATFORM=…  docker platform (default linux/amd64 — see note below)
#   VERSION / BUILD_NUM   app version + build number (default 0.1.0 / 1)
#
# On Apple Silicon this runs the amd64 toolchain under emulation, so expect it
# to be considerably slower than on an x86_64 host. It is the only workable
# route: the Android NDK ships no linux-arm64 host toolchain, and this build
# compiles Rust crypto libs for Android.
#
# Output: build/app/outputs/flutter-apk/

set -euo pipefail

cd "$(dirname "$0")/.."
REPO="$(pwd)"

APP=bitfinite
VERSION="${VERSION:-0.1.0}"
BUILD_NUM="${BUILD_NUM:-1}"
MODE="${1:-debug}"

# A debug build must not claim the production application id.
#
# Without this, `scripts/build-android-docker.sh` with no BFX_APP_ID produces an
# APK whose id is org.bitfinitechain.wallet — the real wallet. It cannot install
# beside it (same id), so the failure is a signature mismatch, which reads like a
# keystore problem and sends you looking in the wrong place. Chasing that is how
# a locally built APK ended up installed over a real wallet.
#
# The advice was already written in configure_bitfinite.sh and was still missed,
# so it is enforced here rather than documented again. Override with
# BFX_ALLOW_PROD_ID=1 for the rare deliberate case, such as reproducing a
# release build locally.
if [ "$MODE" != "release" ] && [ "${BFX_ALLOW_PROD_ID:-0}" != "1" ]; then
  case "${BFX_APP_ID:-}" in
    *.debug|*.profile) : ;;
    *)
      echo "refusing to build $MODE with app id '${BFX_APP_ID:-<default: org.bitfinitechain.wallet>}'." >&2
      echo "" >&2
      echo "  A debug build sharing the production id cannot be installed" >&2
      echo "  alongside the real wallet, and overwriting it loses nothing" >&2
      echo "  visibly until it does." >&2
      echo "" >&2
      echo "  Use:  BFX_APP_ID=org.bitfinitechain.wallet.debug $0 $*" >&2
      echo "  Or:   BFX_ALLOW_PROD_ID=1 $0 $*   # deliberate, overwrites the real app" >&2
      exit 1
      ;;
  esac
fi
# Our own CI toolchain image, published to GHCR by build-ci-image.yaml. It is
# publicly pullable, so no `docker login` is needed. Override with BFX_CI_IMAGE
# to fall back to upstream (ghcr.io/cypherstack/stackwallet-ci:android) if ours
# is ever unavailable.
# Pinned by DIGEST, not by tag. A tag is mutable: rebuild the CI image and every
# release built afterwards has a different toolchain, so an APK that reproduced
# yesterday stops reproducing today — silently, and only a third party trying to
# verify it would notice. The digest makes the toolchain part of the release.
# To move to a new image, pull it, read `docker image inspect --format
# '{{index .RepoDigests 0}}'`, and change the line below in a commit of its own.
IMAGE="${BFX_CI_IMAGE:-ghcr.io/bitfinitechain/bitfinitewallet-ci@sha256:193012d6983743632a3c5ccb87851bd192ab8921bed45414453afaaed3bc5f4f}"
# The CI image is published for linux/amd64 only, and the Dockerfile hardcodes
# amd64 paths (JAVA_HOME, the Go tarball) while the Android NDK ships no
# linux-arm64 host toolchain. So pin the platform: on Apple Silicon this runs
# under emulation (slower, but correct) instead of failing to find a manifest
# and falling back to an arm64 image build that cannot work.
PLATFORM="${BFX_PLATFORM:-linux/amd64}"

echo ">> BitFinite Android build (mode=$MODE, app=$APP, v$VERSION+$BUILD_NUM)"

# 1) Obtain the toolchain image ------------------------------------------------
if [[ "${BUILD_IMAGE:-0}" == "1" ]]; then
  echo ">> Building android image locally from Dockerfile (--target android)…"
  docker build --platform "$PLATFORM" --target android -t bitfinite-wallet-ci:android "$REPO"
  IMAGE=bitfinite-wallet-ci:android
else
  echo ">> Pulling $IMAGE (set BUILD_IMAGE=1 to build locally instead)…"
  if ! docker pull --platform "$PLATFORM" "$IMAGE"; then
    echo ">> Pull failed — falling back to local image build."
    docker build --platform "$PLATFORM" --target android -t bitfinite-wallet-ci:android "$REPO"
    IMAGE=bitfinite-wallet-ci:android
  fi
fi

# 2) Build inside the container ------------------------------------------------
# Named volumes cache pub + gradle across runs; repo is bind-mounted so the APK
# lands on the host. The bfx-android-config volume persists /root/.android so the
# debug keystore is STABLE across builds — otherwise every rebuild signs the
# debug APK with a fresh key and `adb install -r` fails with
# INSTALL_FAILED_UPDATE_INCOMPATIBLE (forcing an uninstall that wipes wallet data).
# Runs as root (image expects writable dirs), then chowns the outputs back to the
# invoking user.
#
# `build/` is sometimes a symlink pointing outside the repo — on macOS it has to
# be moved off an iCloud-synced folder or iOS codesigning fails on
# Flutter.framework. A symlink to a host path does not resolve inside the
# container, so the build would die writing its outputs; mount its target
# explicitly when that is the case.
BUILD_MOUNT=()
if [[ -L "$REPO/build" ]]; then
  BUILD_TARGET="$(cd "$REPO" && readlink build)"
  echo ">> build/ is a symlink -> $BUILD_TARGET (mounting it into the container)"
  mkdir -p "$BUILD_TARGET"
  BUILD_MOUNT=(-v "$BUILD_TARGET":/work/build)
fi

docker run --rm --platform "$PLATFORM" \
  -v "$REPO":/work -w /work \
  "${BUILD_MOUNT[@]+"${BUILD_MOUNT[@]}"}" \
  -v bfx-pub-cache:/root/.pub-cache \
  -v bfx-gradle:/root/.gradle \
  -v bfx-android-config:/root/.android \
  -e APP="$APP" -e VERSION="$VERSION" -e BUILD_NUM="$BUILD_NUM" -e MODE="$MODE" \
  -e BFX_APP_ID="${BFX_APP_ID:-}" \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  "$IMAGE" bash -euxo pipefail -c '
    git config --system --add safe.directory "*"

    # api-key + test-param templates (dev build; exchange features stubbed)
    ( cd scripts && ./prebuild.sh )

    # configure the flavor (app_config.g.dart, pubspec, assets, launcher icons).
    # build_app.sh sources ./env.sh relatively, so it MUST run from scripts/.
    # download_all.sh is a no-op for the bitfinite app, so -d is safe.
    ( cd scripts && echo yes | ./build_app.sh -v "$VERSION" -b "$BUILD_NUM" -p android -a "$APP" -d -s )

    flutter pub get

    # stub dirs the build expects to exist (epic/mwc plugins are not built here)
    mkdir -p crypto_plugins/flutter_libepiccash/lib crypto_plugins/flutter_libmwc/lib

    # Keep Gradle inside the container'"'"'s memory budget and off features that
    # break under emulation. Without this the build daemon is killed partway
    # ("Gradle build daemon disappeared unexpectedly") on Apple Silicon, where
    # QEMU overhead sits on top of Gradle and the Kotlin daemon. Written to
    # GRADLE_USER_HOME (a cached volume) so the repo tree stays clean.
    mkdir -p /root/.gradle
    cat > /root/.gradle/gradle.properties <<EOF
org.gradle.jvmargs=-Xmx3g -XX:MaxMetaspaceSize=768m
org.gradle.daemon=false
org.gradle.vfs.watch=false
org.gradle.parallel=false
kotlin.compiler.execution.strategy=in-process
kotlin.incremental=false
EOF

    # point gradle at the in-image SDK/Flutter (matches CI)
    cat > android/local.properties <<EOF
sdk.dir=/opt/android-sdk
flutter.sdk=/opt/flutter
EOF

    # VERSION/BUILD_NUM reach build_app.sh above, but the APK takes its version
    # from pubspec unless told otherwise — so every build stamped version code
    # 1 and Android refused the next install as a downgrade.
    case "$MODE" in
      release)
        flutter build apk --split-per-abi --release \
          --build-name "$VERSION" --build-number "$BUILD_NUM"
        ;;
      profile)
        # Release-grade compilation with the profiler still attachable. This is
        # the only build worth taking timings from: debug runs the Dart VM in
        # JIT with assertions on and is several times slower for reasons that
        # have nothing to do with our code, so a debug measurement says almost
        # nothing about what a user experiences.
        flutter build apk --profile \
          --build-name "$VERSION" --build-number "$BUILD_NUM"
        ;;
      debug)
        flutter build apk --debug \
          --build-name "$VERSION" --build-number "$BUILD_NUM"
        ;;
      *)
        # Previously anything unrecognised fell through to debug, so asking for
        # a profile build quietly produced a debug APK and the timings taken
        # from it were wrong in the direction that mattered.
        echo "unknown mode: $MODE (expected debug, profile or release)" >&2
        exit 2
        ;;
    esac

    chown -R "$HOST_UID:$HOST_GID" build android/app .dart_tool 2>/dev/null || true
  '

echo ">> Done. APK(s):"
ls -1 build/app/outputs/flutter-apk/*.apk 2>/dev/null || echo "   (check build output above)"
echo ">> Sideload: adb install -r build/app/outputs/flutter-apk/app-debug.apk"
