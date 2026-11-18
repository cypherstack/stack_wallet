#!/usr/bin/env bash
# Build an x86_64 AppImage with a pinned, hash-verified Type 2 runtime.
# Usage: VERSION=<version> appimage/build_appimage.sh <app> <bundle dir> <output.AppImage>

script_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=appimage/lib.sh
source "$script_dir/lib.sh"

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
  curl --fail --silent --show-error --location --retry 3 --retry-all-errors \
    --connect-timeout 30 --max-time 300 \
    --proto '=https' --proto-redir '=https' \
    --output "$destination" "$url"
  verify_sha256 "$destination" "$expected"
}

verify_x86_64_bundle() {
  local executable=$1
  local header
  local machine
  if ! header=$(LC_ALL=C readelf --wide --file-header -- "$executable" 2>/dev/null); then
    echo "bundle executable must be an x86-64 ELF: $executable (machine: unknown)" >&2
    return 1
  fi
  machine=$(sed -n 's/^[[:space:]]*Machine:[[:space:]]*//p' <<< "$header")
  if [ "$machine" != "Advanced Micro Devices X86-64" ]; then
    echo "bundle executable must be an x86-64 ELF: $executable (machine: ${machine:-unknown})" >&2
    return 1
  fi
}

cleanup() {
  if [ -n "${APPIMAGE_STAGED_OUTPUT:-}" ]; then
    rm -f -- "$APPIMAGE_STAGED_OUTPUT"
  fi
  if [ -n "${APPIMAGE_WORKDIR:-}" ] && [ -d "$APPIMAGE_WORKDIR" ]; then
    rm -rf -- "$APPIMAGE_WORKDIR"
  fi
}

main() {
  set -euo pipefail

  if [ $# -ne 3 ]; then
    echo "usage: VERSION=<version> $0 <app> <bundle dir> <output.AppImage>" >&2
    return 1
  fi
  if [ -z "${VERSION:-}" ]; then
    echo "VERSION must be set" >&2
    return 1
  fi
  case "$VERSION" in
    *[!A-Za-z0-9._+-]*)
      echo "VERSION contains unsupported characters: $VERSION" >&2
      return 1
      ;;
  esac

  local app=$1
  local bundle=$2
  local output=$3
  local root
  root=$(CDPATH='' cd -- "$script_dir/.." && pwd)
  # Keep the executable runtime and its trust root together in reviewed source.
  # Environment variables must not be able to replace either half of this pin.
  # Use the modern static runtime so current distributions do not need the
  # obsolete libfuse2 package. AppImageLauncher 2.2 cannot start static
  # runtimes; integrated launch requires the AppImageLauncher 3 beta or later.
  # Verification depends on this runtime retaining TARGET_APPIMAGE support for
  # --appimage-offset and --appimage-extract; preserve that when updating it.
  local runtime_url="https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64"
  local runtime_sha256="2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d"

  require_tools appstreamcli basename chmod cmp curl cut desktop-file-edit \
    desktop-file-validate dirname mkdir mksquashfs mktemp mv readelf realpath \
    rm sed sha256sum unsquashfs

  local output_dir
  output_dir=$(dirname -- "$output")
  mkdir -p "$output_dir"
  output_dir=$(CDPATH='' cd -- "$output_dir" && pwd)
  output="$output_dir/$(basename -- "$output")"

  APPIMAGE_WORKDIR=""
  APPIMAGE_STAGED_OUTPUT=""
  trap cleanup EXIT
  APPIMAGE_WORKDIR=$(mktemp -d "$output_dir/.appimage-work.XXXXXX")
  APPIMAGE_STAGED_OUTPUT=$(mktemp "$output_dir/.appimage-unverified.XXXXXX")

  local runtime="$APPIMAGE_WORKDIR/runtime-x86_64"
  local appdir="$APPIMAGE_WORKDIR/AppDir"

  # Verify external tooling before copying the potentially large application
  # bundle, so supply-chain or network failures fail early.
  download_verified "$runtime_url" "$runtime_sha256" "$runtime"
  chmod 0755 "$runtime"
  verify_x86_64_bundle "$bundle/$app"

  "$root/appimage/make_appdir.sh" "$app" "$bundle" "$appdir"
  "$root/appimage/assemble_appimage.sh" \
    "$appdir" "$runtime" "$APPIMAGE_STAGED_OUTPUT" "$VERSION"
  "$root/appimage/verify_appimage.sh" "$APPIMAGE_STAGED_OUTPUT" "$runtime"
  mv -fT -- "$APPIMAGE_STAGED_OUTPUT" "$output"
  APPIMAGE_STAGED_OUTPUT=""
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
