#!/usr/bin/env bash
# Download and verify a pinned Flutter SDK (macOS).
# The SDK is stored in .flutter-sdk/ (git-ignored).
# Supports x86_64 and arm64.
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
source "$PROJECT_ROOT/flutter_version.env"

SDK_DIR="$PROJECT_ROOT/.flutter-sdk"

[ "$(uname -s)" = Darwin ] || {
    echo "The macOS Flutter SDK requires a macOS host." >&2
    exit 69
}

# Detect the archive name and reviewed checksum before touching the cache.
case "$(uname -m)" in
    x86_64|amd64)
        ARCH=""
        HASH="${FLUTTER_SHA256_X64:-}"
        ;;
    arm64|aarch64)
        ARCH="_arm64"
        HASH="${FLUTTER_SHA256_ARM64:-}"
        ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 64 ;;
esac
[ -n "$HASH" ] || {
    echo "No reviewed Flutter checksum for macOS $(uname -m)." >&2
    exit 78
}

ARCHIVE="flutter_macos${ARCH}_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.zip"
URL="https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/macos/$ARCHIVE"
MARKER="${SDK_DIR}/flutter/.stack-wallet-nix-sdk"

if [ -x "$SDK_DIR/flutter/bin/flutter" ] &&
   [ -f "$MARKER" ] &&
   [ "$(cat "$MARKER")" = "${FLUTTER_VERSION}:${HASH}" ]; then
    echo "Flutter $FLUTTER_VERSION already present in $SDK_DIR"
    exit 0
fi

echo "Downloading Flutter $FLUTTER_VERSION ($FLUTTER_CHANNEL) for $(uname -m)..."
mkdir -p "$SDK_DIR"
cd "$SDK_DIR"

PARTIAL="${ARCHIVE}.partial"
if ! curl --fail --location --retry 4 --retry-all-errors \
    --connect-timeout 20 --output "$PARTIAL" "$URL"; then
    echo "ERROR: Failed to download $URL"
    rm -f "$PARTIAL"
    exit 1
fi
echo "$HASH  $PARTIAL" | shasum -a 256 -c -
mv "$PARTIAL" "$ARCHIVE"

echo "Extracting..."
rm -rf "$SDK_DIR/flutter"
unzip -qo "$ARCHIVE"
rm "$ARCHIVE"
printf '%s\n' "${FLUTTER_VERSION}:${HASH}" > "$MARKER"

echo "Flutter SDK ready at $SDK_DIR/flutter"
echo "Version:"
"$SDK_DIR/flutter/bin/flutter" --version
