#!/usr/bin/env bash
# Download and set up pinned Android SDK components (macOS and Linux).
# Requires Java on PATH (from the Nix android shell or a system JDK).
# The SDK is stored in .android-sdk/ (git-ignored).
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"
source "$PROJECT_ROOT/android_sdk_version.env"

SDK_DIR="$PROJECT_ROOT/.android-sdk"
CMDLINE_DIR="$SDK_DIR/cmdline-tools/latest"

# Detect host OS.
case "$(uname -s)" in
    Darwin) HOST_OS="mac" ;;
    Linux)  HOST_OS="linux" ;;
    *)      echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

if [ "$HOST_OS" = "linux" ]; then
    EXPECTED_SHA="${ANDROID_CMDLINE_TOOLS_SHA256_LINUX:-}"
else
    EXPECTED_SHA="${ANDROID_CMDLINE_TOOLS_SHA256:-}"
fi
[ -n "$EXPECTED_SHA" ] || {
    echo "No reviewed Android cmdline-tools checksum for $HOST_OS." >&2
    exit 78
}
mkdir -p "$SDK_DIR"

case "$HOST_OS" in
    linux)
        PLATFORM_TOOLS_HOST="linux"
        PLATFORM_TOOLS_SHA="$ANDROID_PLATFORM_TOOLS_SHA256_LINUX"
        ;;
    mac)
        PLATFORM_TOOLS_HOST="darwin"
        PLATFORM_TOOLS_SHA="$ANDROID_PLATFORM_TOOLS_SHA256_MACOS"
        ;;
esac
[ -n "$PLATFORM_TOOLS_SHA" ] || {
    echo "No reviewed platform-tools checksum for $HOST_OS." >&2
    exit 78
}
PLATFORM_TOOLS_DIR="$SDK_DIR/platform-tools"
PLATFORM_TOOLS_MARKER="$PLATFORM_TOOLS_DIR/.stack-wallet-nix-sdk"
if [ ! -x "$PLATFORM_TOOLS_DIR/adb" ] ||
   [ ! -f "$PLATFORM_TOOLS_MARKER" ] ||
   [ "$(cat "$PLATFORM_TOOLS_MARKER" 2>/dev/null || true)" != "${ANDROID_PLATFORM_TOOLS_VERSION}:${PLATFORM_TOOLS_SHA}" ]; then
    PLATFORM_TOOLS_ARCHIVE="platform-tools_r${ANDROID_PLATFORM_TOOLS_VERSION}-${PLATFORM_TOOLS_HOST}.zip"
    PLATFORM_TOOLS_PARTIAL="$SDK_DIR/${PLATFORM_TOOLS_ARCHIVE}.partial"
    curl --fail --location --retry 4 --retry-all-errors \
        --connect-timeout 20 --output "$PLATFORM_TOOLS_PARTIAL" \
        "https://dl.google.com/android/repository/$PLATFORM_TOOLS_ARCHIVE"
    if [ "$HOST_OS" = "linux" ]; then
        echo "$PLATFORM_TOOLS_SHA  $PLATFORM_TOOLS_PARTIAL" | sha256sum -c -
    else
        echo "$PLATFORM_TOOLS_SHA  $PLATFORM_TOOLS_PARTIAL" | shasum -a 256 -c -
    fi
    TMPEXTRACT="$(mktemp -d "$SDK_DIR/platform-tools.XXXXXX")"
    unzip -qo "$PLATFORM_TOOLS_PARTIAL" -d "$TMPEXTRACT"
    rm "$PLATFORM_TOOLS_PARTIAL"
    [ -x "$TMPEXTRACT/platform-tools/adb" ] || {
        echo "Unexpected platform-tools archive structure." >&2
        rm -rf "$TMPEXTRACT"
        exit 1
    }
    rm -rf "$PLATFORM_TOOLS_DIR"
    mv "$TMPEXTRACT/platform-tools" "$PLATFORM_TOOLS_DIR"
    rm -rf "$TMPEXTRACT"
    printf '%s\n' "${ANDROID_PLATFORM_TOOLS_VERSION}:${PLATFORM_TOOLS_SHA}" > "$PLATFORM_TOOLS_MARKER"
fi
MARKER="$CMDLINE_DIR/.stack-wallet-nix-sdk"

# Verify Java is available.
if ! command -v java &>/dev/null; then
    echo "ERROR: java not found on PATH."
    if [ "$HOST_OS" = "linux" ]; then
        echo "Enter the Nix android shell first (it provides JDK 17):"
        echo "  make shell-android-pinned"
        echo "Or install a system JDK:"
        echo "  sudo apt install openjdk-17-jdk   # Debian/Ubuntu"
        echo "  sudo dnf install java-17-openjdk  # Fedora/RHEL"
    else
        echo "Install via Nix shell or set JAVA_HOME to Android Studio's JBR:"
        echo "  export JAVA_HOME=\"/Applications/Android Studio.app/Contents/jbr/Contents/Home\""
    fi
    exit 1
fi

# Skip only a cache matching the reviewed build and archive checksum.
if [ -x "$CMDLINE_DIR/bin/sdkmanager" ] &&
   [ -f "$MARKER" ] &&
   [ "$(cat "$MARKER")" = "${ANDROID_CMDLINE_TOOLS_BUILD}:${EXPECTED_SHA}" ]; then
    echo "Android cmdline-tools already present at $CMDLINE_DIR"
else
    ARCHIVE="commandlinetools-${HOST_OS}-${ANDROID_CMDLINE_TOOLS_BUILD}_latest.zip"
    URL="https://dl.google.com/android/repository/$ARCHIVE"

    echo "Downloading Android cmdline-tools (build $ANDROID_CMDLINE_TOOLS_BUILD) for $HOST_OS..."
    PARTIAL="$SDK_DIR/${ARCHIVE}.partial"
    if ! curl --fail --location --retry 4 --retry-all-errors \
        --connect-timeout 20 --output "$PARTIAL" "$URL"; then
        echo "ERROR: Failed to download $URL"
        rm -f "$PARTIAL"
        exit 1
    fi

    echo "Verifying checksum..."
    if [ "$HOST_OS" = "linux" ]; then
        echo "$EXPECTED_SHA  $PARTIAL" | sha256sum -c -
    else
        echo "$EXPECTED_SHA  $PARTIAL" | shasum -a 256 -c -
    fi

    echo "Extracting..."
    TMPEXTRACT="$(mktemp -d "$SDK_DIR/extract.XXXXXX")"
    unzip -qo "$PARTIAL" -d "$TMPEXTRACT"
    rm "$PARTIAL"

    # Google's archive contains a top-level cmdline-tools/ directory.
    # Move its contents to cmdline-tools/latest/ as sdkmanager expects.
    mkdir -p "$SDK_DIR/cmdline-tools"
    if [ -d "$TMPEXTRACT/cmdline-tools" ]; then
        rm -rf "$CMDLINE_DIR"
        mv "$TMPEXTRACT/cmdline-tools" "$CMDLINE_DIR"
    else
        echo "ERROR: Unexpected archive structure, no cmdline-tools/ in zip."
        rm -rf "$TMPEXTRACT"
        exit 1
    fi
    rm -rf "$TMPEXTRACT"
    printf '%s\n' "${ANDROID_CMDLINE_TOOLS_BUILD}:${EXPECTED_SHA}" > "$MARKER"
fi

# Pre-accept licenses for non-interactive use.
LICENSES_DIR="$SDK_DIR/licenses"
mkdir -p "$LICENSES_DIR"
printf '\n%s\n' "24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$LICENSES_DIR/android-sdk-license"
printf '\n%s\n' "84831b9409646a918e30573bab4c9c91346d8abd" > "$LICENSES_DIR/android-sdk-arm-dbt-license"

echo "Installing SDK components via sdkmanager..."
SDKMANAGER="$CMDLINE_DIR/bin/sdkmanager"
SDK_PACKAGES=()
for platform_version in "${ANDROID_PLATFORM_VERSIONS[@]}"; do
    SDK_PACKAGES+=("platforms;$platform_version")
done
SDK_PACKAGES+=(
    "build-tools;$ANDROID_BUILD_TOOLS_VERSION"
    "ndk;$ANDROID_NDK_VERSION"
    "ndk;$ANDROID_PLUGIN_NDK_VERSION"
    "cmake;$ANDROID_CMAKE_VERSION"
)
"$SDKMANAGER" --sdk_root="$SDK_DIR" "${SDK_PACKAGES[@]}"

INSTALLED="$($SDKMANAGER --sdk_root="$SDK_DIR" --list_installed 2>/dev/null)"
while IFS='|' read -r package expected_version; do
    [ -n "$package" ] || continue
    actual_version="$(printf '%s\n' "$INSTALLED" | awk -F '|' -v package="$package" '
        {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
            if ($1 == package) print $2
        }
    ')"
    [ "$actual_version" = "$expected_version" ] || {
        echo "Android SDK package drift: $package expected $expected_version, found ${actual_version:-missing}." >&2
        exit 78
    }
done < "$PROJECT_ROOT/contrib/nix/android-sdk-packages.lock"

echo ""
echo "Android SDK ready at $SDK_DIR"
echo "Components installed:"
printf '%s\n' "$INSTALLED" | grep -E "^  " || true
