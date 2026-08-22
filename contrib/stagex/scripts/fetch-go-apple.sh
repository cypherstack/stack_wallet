#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"
source "$STAGEX_PROJECT_ROOT/go_version.env"

[ "$(uname -s)" = Darwin ] || {
  echo "The Apple Go SDK requires a macOS host." >&2
  exit 69
}
case "$(uname -m)" in
  arm64|aarch64)
    go_arch=arm64
    checksum="$GO_SHA256_DARWIN_ARM64"
    ;;
  x86_64|amd64)
    go_arch=amd64
    checksum="$GO_SHA256_DARWIN_X64"
    ;;
  *)
    echo "Unsupported macOS architecture: $(uname -m)." >&2
    exit 69
    ;;
esac

sdk_root="$STAGEX_PROJECT_ROOT/.go-sdk"
sdk="$sdk_root/go"
marker="$sdk/.stack-wallet-stagex-sdk"
expected="$GO_VERSION:$go_arch:$checksum"
if [ -x "$sdk/bin/go" ] && [ -f "$marker" ] &&
   [ "$(cat "$marker")" = "$expected" ]; then
  printf '%s\n' "$sdk"
  exit 0
fi

archive="go$GO_VERSION.darwin-$go_arch.tar.gz"
partial="$sdk_root/$archive.partial"
mkdir -p "$sdk_root"
curl --fail --location --retry 5 --retry-all-errors --connect-timeout 30 \
  --output "$partial" "https://go.dev/dl/$archive"
echo "$checksum  $partial" | shasum -a 256 -c -
safe_remove_output .go-sdk/go
tar -xzf "$partial" -C "$sdk_root"
rm "$partial"
[ -x "$sdk/bin/go" ] || {
  echo "Unexpected Go archive structure." >&2
  exit 1
}
printf '%s\n' "$expected" > "$marker"
"$sdk/bin/go" version | grep -Fq "go version go$GO_VERSION darwin/$go_arch"
printf '%s\n' "$sdk"
