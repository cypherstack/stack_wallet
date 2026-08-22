#!/usr/bin/env bash
# Build the Flutter Linux app inside a Nix shell.
# This is a non-interactive build -- suitable for CI.
# Defaults to --pinned for reproducibility.
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
SDK_DIR="$PROJECT_ROOT/.flutter-sdk/flutter"
source "$PROJECT_ROOT/rust_version.env"
source "$PROJECT_ROOT/go_version.env"

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
export STACK_NIX_RUST_VERSION="$RUST_VERSION"
export STACK_NIX_GO_VERSION="$GO_VERSION"

BUILD_CMD='
set -euo pipefail
export PATH="$FLUTTER_NIX_SDK_DIR/bin:$PATH"
export FLUTTER_ROOT="$FLUTTER_NIX_SDK_DIR"
export USE_SYSTEM_SECURE_STORAGE_DEPS=1
state_dir="$FLUTTER_NIX_PROJECT_ROOT/.nix-build-state/linux"
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
export CFLAGS="-Wdate-time -ffile-prefix-map=$FLUTTER_NIX_PROJECT_ROOT=."
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--build-id=sha1"
runtime_paths=()
for linker_flag in ${NIX_LDFLAGS:-}; do
  case "$linker_flag" in
    -L/nix/store/*) runtime_paths+=("${linker_flag#-L}") ;;
  esac
done
[ "${#runtime_paths[@]}" -gt 0 ] || {
  echo "Nix runtime library closure is empty." >&2
  exit 1
}
STACK_NIX_RUNTIME_LIBRARY_PATH="$(
  IFS=:
  echo "${runtime_paths[*]}"
)"
export STACK_NIX_RUNTIME_LIBRARY_PATH
mkdir -p "$HOME" "$PUB_CACHE" "$CARGO_HOME" "$GOCACHE" "$TMPDIR"
"$STACK_NIX_REAL_RUSTUP" set auto-self-update disable
"$STACK_NIX_REAL_RUSTUP" toolchain install \
  "$STACK_NIX_RUST_VERSION" --profile minimal
rustup run stable rustc --version \
  | grep -F "rustc $STACK_NIX_RUST_VERSION "
go version | grep -F "go version go$STACK_NIX_GO_VERSION "
cd "$FLUTTER_NIX_PROJECT_ROOT"

echo "--- Checking for Linux desktop support ---"
if [ ! -d linux ]; then
  echo "Creating Linux desktop project..."
  flutter create --platforms=linux .
else
  echo "Linux desktop project already exists."
fi

echo "--- flutter pub get ---"
flutter clean
flutter pub get --enforce-lockfile

# CMake 4 defaults this nested install to lib64 on x86_64.
coinlib_cmake="$(
  find "$PUB_CACHE/git" -path "*/coinlib_flutter/src/CMakeLists.txt" \
    -type f -print -quit
)"
[ -n "$coinlib_cmake" ] || {
  echo "Locked Coinlib CMake file not found." >&2
  exit 1
}
install_prefix="  -DCMAKE_INSTALL_PREFIX=\${SECP256K1_PREFIX}"
[ "$(grep -Fxc "$install_prefix" "$coinlib_cmake")" -eq 1 ] || {
  echo "Unexpected Coinlib install configuration." >&2
  exit 1
}
sed -i "/  -DCMAKE_INSTALL_PREFIX=\${SECP256K1_PREFIX}/a\\  -DCMAKE_INSTALL_LIBDIR=lib" \
  "$coinlib_cmake"
grep -Fxq "  -DCMAKE_INSTALL_LIBDIR=lib" "$coinlib_cmake"

# The plugin otherwise links every module exposed by the Nix OpenCV package.
camera_cmake="$(
  find "$PUB_CACHE/git" -path "*/camera-linux-*/src/CMakeLists.txt" \
    -type f -print -quit
)"
[ -n "$camera_cmake" ] || {
  echo "Locked camera_linux CMake file not found." >&2
  exit 1
}
opencv_find="find_package(OpenCV REQUIRED)"
[ "$(grep -Fxc "$opencv_find" "$camera_cmake")" -eq 1 ] || {
  echo "Unexpected camera_linux OpenCV configuration." >&2
  exit 1
}
sed -i \
  "s/^find_package(OpenCV REQUIRED)$/find_package(OpenCV REQUIRED COMPONENTS core imgproc imgcodecs videoio)/" \
  "$camera_cmake"
grep -Fxq \
  "find_package(OpenCV REQUIRED COMPONENTS core imgproc imgcodecs videoio)" \
  "$camera_cmake"

echo "--- flutter build linux ---"
flutter build linux --release

binary_name="${STACK_NIX_APP:-stack_wallet}"
artifact="$(find build/linux -path "*/release/bundle/$binary_name" -type f -print -quit)"
[ -n "$artifact" ] && [ -x "$artifact" ] || {
  echo "Linux release artifact not found." >&2
  exit 1
}
bundle="$(dirname "$artifact")"
[ -f "$bundle/lib/libsecp256k1.so" ] || {
  echo "Coinlib dependency is not bundled: libsecp256k1.so" >&2
  exit 1
}
for runtime_library in epoxy:libepoxy.so.0 fontconfig:libfontconfig.so.1; do
  package="${runtime_library%%:*}"
  library="${runtime_library#*:}"
  library_dir="$(pkg-config --variable=libdir "$package")"
  [ -f "$library_dir/$library" ] || {
    echo "Nix runtime dependency not found: $library" >&2
    exit 1
  }
  cp -L "$library_dir/$library" "$bundle/lib/$library"
  chmod u+w "$bundle/lib/$library"
done
while IFS= read -r candidate; do
  readelf -h "$candidate" >/dev/null 2>&1 || continue
  while IFS= read -r needed; do
    case "$needed" in
      /*)
        bundled_needed="$bundle/lib/$(basename "$needed")"
        [ -f "$bundled_needed" ] || {
          echo "Absolute dependency is not bundled: $needed" >&2
          exit 1
        }
        patchelf --replace-needed "$needed" "$(basename "$needed")" \
          "$candidate"
        ;;
    esac
  done < <(patchelf --print-needed "$candidate")
  if [ "$(dirname "$candidate")" = "$bundle" ]; then
    local_rpath='\''$ORIGIN/lib'\''
  else
    local_rpath='\''$ORIGIN'\''
  fi
  existing_rpath="$(patchelf --print-rpath "$candidate")"
  IFS=: read -r -a existing_paths <<< "$existing_rpath"
  store_paths=()
  for existing_path in "${existing_paths[@]}"; do
    case "$existing_path" in
      /nix/store/*) store_paths+=("$existing_path") ;;
    esac
  done
  store_rpath="$(
    IFS=:
    echo "${store_paths[*]}"
  )"
  resolved_rpath="$local_rpath:$STACK_NIX_RUNTIME_LIBRARY_PATH"
  [ -z "$store_rpath" ] || resolved_rpath="$resolved_rpath:$store_rpath"
  patchelf --force-rpath --set-rpath "$resolved_rpath" "$candidate"
  dependency_report="$(
    LD_LIBRARY_PATH="$bundle/lib" ldd "$candidate" 2>&1
  )" || {
    echo "Unable to inspect Linux bundle dependency: $candidate" >&2
    exit 1
  }
  if grep -q "not found" <<< "$dependency_report"; then
    echo "Unresolved Linux bundle dependency: $candidate" >&2
    exit 1
  fi
done < <(find "$bundle" -type f -print)
camera_dependencies="$(
  LD_LIBRARY_PATH="$bundle/lib" ldd "$bundle/lib/libcamera_linux.so" 2>&1
)"
grep -Fq "$bundle/lib/libopencv_wrapper.so" <<< "$camera_dependencies" || {
  echo "Camera dependency is not bundled: libopencv_wrapper.so" >&2
  exit 1
}
for component in core imgproc imgcodecs videoio; do
  grep -Eq "$bundle/lib/libopencv_${component}\\.so" \
    <<< "$camera_dependencies" || {
    echo "Camera dependency is not bundled: libopencv_${component}.so" >&2
    exit 1
  }
done
dart run contrib/nix/artifact_manifest.dart create \
  "$bundle" build/attestations/linux.manifest
echo "Build complete: $artifact"
'

if [ "${1:-}" = "--refresh" ]; then
    echo "Building with latest nixpkgs..."
    nix develop "$FLAKE_DIR#linux" --refresh --command bash -c "$BUILD_CMD"
else
    echo "Building with pinned nixpkgs (from flake.lock)..."
    nix develop "$FLAKE_DIR#linux" --command bash -c "$BUILD_CMD"
fi
