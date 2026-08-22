#!/usr/bin/env bash
# Enter a development shell for Android Flutter development.
#
# Usage:
#   ./scripts/shell-android.sh              # uses system/env Java + Android SDK
#   ./scripts/shell-android.sh --pinned     # uses the locked Nix Android shell
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"

# Detect host OS.
case "$(uname -s)" in
    Darwin) HOST_OS="mac" ;;
    Linux)  HOST_OS="linux" ;;
    *)      echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

# Locate Flutter SDK.
if [ -d "$PROJECT_ROOT/.flutter-sdk/flutter" ]; then
    FLUTTER_DIR="$PROJECT_ROOT/.flutter-sdk/flutter"
elif command -v flutter &>/dev/null; then
    FLUTTER_DIR="$(dirname "$(dirname "$(command -v flutter)")")"
else
    if [ "$HOST_OS" = "linux" ]; then
        echo "Flutter SDK not found. Run scripts/fetch-flutter-linux.sh first."
    else
        echo "Flutter SDK not found. Run scripts/fetch-flutter.sh first."
    fi
    exit 1
fi

# Locate Android SDK.
if [ -x "$PROJECT_ROOT/.android-sdk/cmdline-tools/latest/bin/sdkmanager" ]; then
    ANDROID_DIR="$PROJECT_ROOT/.android-sdk"
elif [ -d "$HOME/Library/Android/sdk" ]; then
    ANDROID_DIR="$HOME/Library/Android/sdk"
elif [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME" ]; then
    ANDROID_DIR="$ANDROID_HOME"
else
    echo "Android SDK not found. Run scripts/fetch-android-sdk.sh first."
    exit 1
fi

export PROJECT_ROOT

if [ "${1:-}" = "--pinned" ]; then
    # Nix android shell provides JDK 17 on both macOS and Linux.
    echo "Using pinned Nix android shell + Android SDK"
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true
    # \$JAVA_HOME is expanded inside the Nix shell (where jdk17 sets it).
    FLAKE_DIR="path:${NIX_FLAKE_DIR:-$PROJECT_ROOT/nix}"
    exec nix develop "$FLAKE_DIR#android" --command bash --init-file <(cat <<INITEOF
export PATH="$FLUTTER_DIR/bin:\$JAVA_HOME/bin:$ANDROID_DIR/platform-tools:$ANDROID_DIR/cmdline-tools/latest/bin:\$PATH"
export FLUTTER_ROOT="$FLUTTER_DIR"
export ANDROID_HOME="$ANDROID_DIR"
export ANDROID_SDK_ROOT="$ANDROID_DIR"
export PROJECT_ROOT="$PROJECT_ROOT"
echo "Ready. Flutter + Android SDK + Java (Nix) provided."
echo "Try: flutter doctor"
INITEOF
)
fi

# Non-pinned: locate Java from environment or system.
if [ -n "${JAVA_HOME:-}" ] && [ -d "$JAVA_HOME" ]; then
    JAVA="$JAVA_HOME"
elif [ -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home" ]; then
    JAVA="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
elif command -v java &>/dev/null; then
    # Resolve symlinks to get the real JDK home (works on Linux and macOS with GNU readlink).
    _JAVA_BIN="$(command -v java)"
    if [ "$HOST_OS" = "linux" ]; then
        _JAVA_BIN="$(readlink -f "$_JAVA_BIN")"
    fi
    JAVA="$(dirname "$(dirname "$_JAVA_BIN")")"
else
    echo "Java not found. Set JAVA_HOME, or use the Nix android shell:"
    echo "  ./scripts/shell-android.sh --pinned"
    if [ "$HOST_OS" = "linux" ]; then
        echo "Or install a system JDK:"
        echo "  sudo apt install openjdk-17-jdk   # Debian/Ubuntu"
        echo "  sudo dnf install java-17-openjdk  # Fedora/RHEL"
    else
        echo "Or install Android Studio."
    fi
    exit 1
fi

echo "Using system Java + Android SDK"
exec bash --init-file <(cat <<INITEOF
export PATH="$FLUTTER_DIR/bin:$JAVA/bin:$ANDROID_DIR/platform-tools:$ANDROID_DIR/cmdline-tools/latest/bin:\$PATH"
export FLUTTER_ROOT="$FLUTTER_DIR"
export ANDROID_HOME="$ANDROID_DIR"
export ANDROID_SDK_ROOT="$ANDROID_DIR"
export JAVA_HOME="$JAVA"
export PROJECT_ROOT="$PROJECT_ROOT"
echo "Ready. Flutter + Android SDK provided."
echo "Try: flutter doctor"
INITEOF
)
