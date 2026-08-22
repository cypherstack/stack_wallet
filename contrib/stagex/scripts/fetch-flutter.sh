#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
source "$PROJECT_ROOT/flutter_version.env"

case "$(uname -s):$(uname -m)" in
  Linux:x86_64|Linux:amd64)
    os=linux
    arch=x64
    archive="flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
    checksum="$FLUTTER_SHA256_LINUX_X64"
    ;;
  Darwin:x86_64|Darwin:amd64)
    os=macos
    arch=x64
    archive="flutter_macos_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.zip"
    checksum="$FLUTTER_SHA256_X64"
    ;;
  Darwin:arm64|Darwin:aarch64)
    os=macos
    arch=arm64
    archive="flutter_macos_arm64_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.zip"
    checksum="$FLUTTER_SHA256_ARM64"
    ;;
  *)
    echo "Unsupported Flutter host: $(uname -s)/$(uname -m)." >&2
    exit 69
    ;;
esac

marker="{\"schema\":1,\"os\":\"$os\",\"arch\":\"$arch\",\"version\":\"$FLUTTER_VERSION\",\"channel\":\"$FLUTTER_CHANNEL\",\"archive_sha256\":\"$checksum\"}"
sdk_root="$PROJECT_ROOT/.flutter-sdk"
sdk="$sdk_root/flutter"
if [ -x "$sdk/bin/flutter" ] && [ -f "$sdk/.stagex-verified.json" ] &&
   [ "$(cat "$sdk/.stagex-verified.json")" = "$marker" ]; then
  echo "Flutter $FLUTTER_VERSION already checksum-verified."
  exit 0
fi

url="https://storage.googleapis.com/flutter_infra_release/releases/$FLUTTER_CHANNEL/$os/$archive"
partial="$sdk_root/$archive.partial"
extracting="$sdk_root/.flutter-extracting"
mkdir -p "$sdk_root"
curl --fail --location --retry 5 --retry-all-errors --connect-timeout 30 \
  --output "$partial" "$url"
if [ "$os" = linux ]; then
  echo "$checksum  $partial" | sha256sum -c -
else
  echo "$checksum  $partial" | shasum -a 256 -c -
fi

rm -rf -- "$extracting"
mkdir -p "$extracting"
if [ "$os" = linux ]; then
  tar -xJf "$partial" -C "$extracting"
else
  unzip -q "$partial" -d "$extracting"
fi
rm "$partial"
[ -x "$extracting/flutter/bin/flutter" ] || {
  echo "Unexpected Flutter archive structure." >&2
  exit 1
}
rm -rf -- "$sdk"
mv "$extracting/flutter" "$sdk"
rmdir "$extracting"
printf '%s\n' "$marker" > "$sdk/.stagex-verified.json"
"$sdk/bin/flutter" --version
