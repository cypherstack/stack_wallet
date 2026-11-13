#!/usr/bin/env bash
# Build an x86_64 AppImage with pinned, hash-verified AppImage tooling.
# Usage: appimage/build_appimage.sh <stack_wallet|stack_duo|campfire> <bundle dir> <output.AppImage>
set -euo pipefail

readonly APPIMAGETOOL_VERSION="1.9.1"
readonly APPIMAGETOOL_SHA256="ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0"
readonly APPIMAGE_RUNTIME_VERSION="20251108"
readonly APPIMAGE_RUNTIME_SHA256="2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d"
APPIMAGE_WORKDIR=""

verify_sha256() {
  local file=$1
  local expected=$2
  local actual
  actual=$(sha256sum "$file" | cut -d ' ' -f1)
  if [ "$actual" != "$expected" ]; then
    echo "SHA-256 mismatch for $file: expected $expected, got $actual" >&2
    return 1
  fi
}

download_verified() {
  local url=$1
  local expected=$2
  local destination=$3
  curl --fail --silent --show-error --location --retry 3 \
    --proto '=https' --proto-redir '=https' \
    --output "$destination" "$url"
  verify_sha256 "$destination" "$expected"
}

main() {
  if [ $# -ne 3 ]; then
    echo "usage: $0 <stack_wallet|stack_duo|campfire> <bundle dir> <output.AppImage>" >&2
    return 1
  fi

  local app=$1
  local bundle=$2
  local output=$3
  case "$app" in
    stack_wallet|stack_duo|campfire) ;;
    *) echo "unknown app: $app" >&2; return 1 ;;
  esac
  if [ ! -d "$bundle" ]; then
    echo "bundle directory not found: $bundle" >&2
    return 1
  fi

  local root
  root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
  local output_dir
  output_dir=$(dirname -- "$output")
  mkdir -p "$output_dir"
  output_dir=$(cd -- "$output_dir" && pwd)
  output="$output_dir/$(basename -- "$output")"

  local build_root="$root/build/appimage-work"
  mkdir -p "$build_root"
  APPIMAGE_WORKDIR=$(mktemp -d "$build_root/run.XXXXXX")
  trap 'rm -rf -- "$APPIMAGE_WORKDIR"' EXIT

  local appdir="$APPIMAGE_WORKDIR/AppDir"
  local appimagetool="$APPIMAGE_WORKDIR/appimagetool-x86_64.AppImage"
  local runtime="$APPIMAGE_WORKDIR/runtime-x86_64"

  "$root/appimage/make_appdir.sh" "$app" "$bundle" "$appdir"
  download_verified \
    "https://github.com/AppImage/appimagetool/releases/download/${APPIMAGETOOL_VERSION}/appimagetool-x86_64.AppImage" \
    "$APPIMAGETOOL_SHA256" "$appimagetool"
  download_verified \
    "https://github.com/AppImage/type2-runtime/releases/download/${APPIMAGE_RUNTIME_VERSION}/runtime-x86_64" \
    "$APPIMAGE_RUNTIME_SHA256" "$runtime"
  chmod +x "$appimagetool"

  ARCH=x86_64 "$appimagetool" --appimage-extract-and-run \
    --no-appstream --runtime-file "$runtime" \
    "$appdir" "$output"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
