#!/usr/bin/env bash
# ==============================================================================
# scripts/download_xcode.sh
#
# Download and install Xcode from archive.org without an Apple ID, App Store
# login or the `xcodes` CLI. Opt-in only: `make bootstrap-xcode-download`.
#
# Integrity: the .xip is checked against the SHA-1 that archive.org lists for
# the item (detects corruption/tampering of the download), then Apple's
# signature on the .xip is verified with `pkgutil --check-signature`
# (authenticity). Both must pass.
#
# Notes:
#   - Redistribution of Xcode by third parties may violate Apple's license
#     terms and the item can be taken down at any time. Prefer the Mac App
#     Store or developer.apple.com when you can. Not for CI.
#   - dnix (the prebuilt/reproducible native libs) pins Xcode 27.0 for building
#     Apple libraries from source and for `dart tool/verify_release.dart`. Use
#     `-v 27.0` for that; 27.1 is fine for normal app builds with prebuilts.
#
# Usage:
#   ./scripts/download_xcode.sh [-v <version>] [-d <app_path>] [-c <cache_dir>] [-y] [-n]
#
# Options:
#   -v <version>   Xcode version (default: 27.1; supported: 27.1, 27.0, 16.2, 16.0)
#   -d <app_path>  Target .app path (default: /Applications/Xcode_<version>.app)
#   -c <cache_dir> Cache directory for the .xip (default: ~/.cache/xcode)
#   -n             Dry run: print what would happen, download nothing
#   -y             Non-interactive: skip the confirmation prompt, accept the
#                  Xcode license and run first-launch setup
#   -h             Show this help
#
# Works with the macOS system bash 3.2.
# ==============================================================================

set -euo pipefail

XCODE_VERSION="27.1"
TARGET_DIR=""
CACHE_DIR="${XCODE_CACHE_DIR:-$HOME/.cache/xcode}"
DRY_RUN=0
ASSUME_YES=0

# Verified releases (archive.org metadata).
# Output: BUILD|SHA1|IA_ITEM|FILE_NAME
release_info() {
    case "$1" in
        27.1) echo "27A9275|d8b1d16397e6f2faab34bd48b19692a3f7797b9d|xcode-27.1|Xcode_27.1.xip" ;;
        27.0) echo "27A266a|04a7d831229ac95577f09398d87501a1c6fb92ad|xcode-27.0|Xcode_27.xip" ;;
        16.2) echo "16C5032a|aa1a3f12d4217ab04ea4064f40e92399192e15f9|xcode-16.2|Xcode_16.2.xip" ;;
        16.0) echo "16A242d|71b15ff10826474491ebca3d36a6ca5964b9e1c5|xcode-16.0|Xcode_16.xip" ;;
        *) return 1 ;;
    esac
}
SUPPORTED_VERSIONS="27.1 27.0 16.2 16.0"

usage() {
    sed -n '2,/^# =====*$/p' "$0" | sed -e '1d' -e '$d' -e 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while getopts "v:d:c:nyh" opt; do
    case "${opt}" in
        v) XCODE_VERSION="$OPTARG" ;;
        d) TARGET_DIR="$OPTARG" ;;
        c) CACHE_DIR="$OPTARG" ;;
        n) DRY_RUN=1 ;;
        y) ASSUME_YES=1 ;;
        h) usage 0 ;;
        *) usage 1 ;;
    esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "[ERROR] This script must be run on macOS." >&2
    exit 1
fi

if [[ "${CI:-}" == "true" || "${CI:-}" == "1" ]]; then
    echo "[ERROR] Refusing to download Xcode from archive.org in CI." >&2
    exit 1
fi

if ! RELEASE="$(release_info "$XCODE_VERSION")"; then
    echo "[ERROR] Unsupported Xcode version: '$XCODE_VERSION'. Supported: $SUPPORTED_VERSIONS" >&2
    exit 1
fi
IFS="|" read -r BUILD_NUM EXPECTED_SHA1 IA_ITEM FILE_NAME <<< "$RELEASE"

if [[ -z "$TARGET_DIR" ]]; then
    TARGET_DIR="/Applications/Xcode_${XCODE_VERSION}.app"
fi
if [[ "$TARGET_DIR" != *.app || "$TARGET_DIR" == "/" ]]; then
    echo "[ERROR] Target must be an .app path, got: $TARGET_DIR" >&2
    exit 1
fi

# A relative cache or target dir must not change meaning after the extraction cd below.
case "$CACHE_DIR" in
    /*) ;;
    *) CACHE_DIR="$PWD/$CACHE_DIR" ;;
esac
case "$TARGET_DIR" in
    /*) ;;
    *) TARGET_DIR="$PWD/$TARGET_DIR" ;;
esac

# sudo is only needed when the target directory is not writable (for example /Applications).
SUDO=""
mkdir -p "$(dirname "$TARGET_DIR")" 2>/dev/null || true
if [[ ! -w "$(dirname "$TARGET_DIR")" ]]; then
    SUDO="sudo"
fi

# XCODE_XIP_URL can point to another mirror (the SHA-1 and the Apple signature are still checked).
DOWNLOAD_URL="${XCODE_XIP_URL:-https://archive.org/download/${IA_ITEM}/${FILE_NAME}}"
TORRENT_URL="https://archive.org/download/${IA_ITEM}/${IA_ITEM}_archive.torrent"
XIP_PATH="${CACHE_DIR}/${FILE_NAME}"
XIP_PART="${XIP_PATH}.part"

finish_install() {
    if [[ $ASSUME_YES -eq 1 ]]; then
        if [[ "$(xcode-select -p 2>/dev/null || true)" != "${TARGET_DIR}/Contents/Developer" ]]; then
            sudo xcode-select -s "${TARGET_DIR}/Contents/Developer"
        fi
        if ! xcodebuild -license check >/dev/null 2>&1; then
            sudo xcodebuild -license accept
        fi
        if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
            sudo xcodebuild -runFirstLaunch
        fi
        echo "[SUCCESS] Xcode ${XCODE_VERSION} (${BUILD_NUM}) installed and selected."
        xcodebuild -version
    else
        echo "[SUCCESS] Installed ${TARGET_DIR}. Finish with:"
        echo "  sudo xcode-select -s \"${TARGET_DIR}/Contents/Developer\""
        echo "  sudo xcodebuild -license        # read and accept"
        echo "  sudo xcodebuild -runFirstLaunch"
    fi
}

echo "================================================================="
echo " Xcode from archive.org (hash + signature verified)"
echo "================================================================="
echo " Xcode version : ${XCODE_VERSION} (build ${BUILD_NUM})"
echo " Target        : ${TARGET_DIR}"
echo " Source        : ${DOWNLOAD_URL}"
echo " Expected SHA-1: ${EXPECTED_SHA1}"
echo " Cache         : ${XIP_PATH}"
echo "================================================================="

# Already installed?
if [[ -d "$TARGET_DIR" ]]; then
    CURRENT_BUILD="$("$TARGET_DIR/Contents/Developer/usr/bin/xcodebuild" -version 2>/dev/null | awk '/Build version/ {print $3}' || true)"
    if [[ "$CURRENT_BUILD" == "$BUILD_NUM" ]]; then
        echo "[OK] Xcode ${XCODE_VERSION} (${BUILD_NUM}) is already installed at ${TARGET_DIR}."
        # With -y, finish selection/license/first-launch now instead of exiting
        # before the setup the caller explicitly asked for.
        finish_install
        exit 0
    fi
    echo "[WARN] ${TARGET_DIR} exists with build '${CURRENT_BUILD}', expected '${BUILD_NUM}'. It will be replaced."
fi

if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY-RUN] Would download : ${DOWNLOAD_URL}"
    echo "[DRY-RUN] Alternative    : ${TORRENT_URL}"
    echo "[DRY-RUN] Would verify   : SHA-1 ${EXPECTED_SHA1}, then pkgutil --check-signature"
    exit 0
fi

if [[ $ASSUME_YES -eq 0 ]]; then
    echo "This downloads ~2 GB, needs ~20 GB free while extracting, and uses sudo only if ${TARGET_DIR} is not writable."
    echo "Redistribution of Xcode by third parties may conflict with Apple's license terms."
    read -r -p "Continue? (yes/no): " ANSWER
    [[ "$ANSWER" == "yes" ]] || { echo "Aborted."; exit 1; }
fi

mkdir -p "$CACHE_DIR"
FREE_KB="$(df -k "$CACHE_DIR" | awk 'NR==2 {print $4}')"
if [[ "$FREE_KB" -lt $((20 * 1024 * 1024)) ]]; then
    echo "[ERROR] At least 20 GB free are required in ${CACHE_DIR}." >&2
    exit 1
fi

# 1. Resumable download. A verified archive is reused; a partial .part file is
# resumed with curl -C - instead of being treated as a complete archive.
if [[ -f "$XIP_PATH" ]]; then
    CACHED_SHA1="$(shasum -a 1 "$XIP_PATH" | awk '{print $1}')"
    if [[ "$CACHED_SHA1" == "$EXPECTED_SHA1" ]]; then
        echo "Using cached archive: $XIP_PATH"
    else
        echo "[WARN] Cached archive does not match the expected SHA-1; downloading again." >&2
        rm -f "$XIP_PATH"
    fi
fi
if [[ ! -f "$XIP_PATH" ]]; then
    if [[ -f "$XIP_PART" ]]; then
        echo "Resuming partial download: $XIP_PART"
    else
        echo "Downloading ${FILE_NAME} (resumable; torrent alternative: ${TORRENT_URL})..."
    fi
    if ! curl -fL -C - --retry 8 --retry-delay 5 --retry-all-errors --progress-bar -o "$XIP_PART" "$DOWNLOAD_URL"; then
        echo "[WARN] Could not resume; restarting the download from scratch." >&2
        rm -f "$XIP_PART"
        curl -fL --retry 8 --retry-delay 5 --retry-all-errors --progress-bar -o "$XIP_PART" "$DOWNLOAD_URL"
    fi
    PART_SHA1="$(shasum -a 1 "$XIP_PART" | awk '{print $1}')"
    if [[ "$PART_SHA1" != "$EXPECTED_SHA1" ]]; then
        echo "[ERROR] SHA-1 mismatch, the download is corrupt or altered." >&2
        echo "  expected: $EXPECTED_SHA1" >&2
        echo "  got     : $PART_SHA1" >&2
        rm -f "$XIP_PART"
        exit 1
    fi
    mv "$XIP_PART" "$XIP_PATH"
fi

# 2. Integrity: SHA-1 from archive.org metadata
echo "Verifying SHA-1..."
ACTUAL_SHA1="$(shasum -a 1 "$XIP_PATH" | awk '{print $1}')"
if [[ "$ACTUAL_SHA1" != "$EXPECTED_SHA1" ]]; then
    echo "[ERROR] SHA-1 mismatch, the download is corrupt or altered." >&2
    echo "  expected: $EXPECTED_SHA1" >&2
    echo "  got     : $ACTUAL_SHA1" >&2
    rm -f "$XIP_PATH"
    exit 1
fi
echo "[OK] SHA-1 matches."

# 3. Authenticity: Apple's signature on the .xip
echo "Verifying Apple signature..."
if ! pkgutil --check-signature "$XIP_PATH"; then
    echo "[ERROR] Apple signature check failed. Not installing." >&2
    exit 1
fi
echo "[OK] Apple signature valid."

# Remove the quarantine flag from the archive, otherwise it spreads to every file in Xcode.app and
# Gatekeeper scans them all on first use (15 to 25 minutes).
xattr -d com.apple.quarantine "$XIP_PATH" 2>/dev/null || true

# 4. Extract (signature is checked again by xip itself)
EXTRACT_DIR="${CACHE_DIR}/extract_${BUILD_NUM}"
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"
echo "Extracting (5-10 minutes)..."
(
    cd "$EXTRACT_DIR"
    if command -v unxip >/dev/null 2>&1; then
        unxip "$XIP_PATH"
    else
        /usr/bin/xip --expand "$XIP_PATH"
    fi
)
if [[ ! -d "${EXTRACT_DIR}/Xcode.app" ]]; then
    echo "[ERROR] Extraction failed: Xcode.app not found." >&2
    exit 1
fi

# 5. Install
echo "Installing to ${TARGET_DIR}${SUDO:+ (sudo)}..."
$SUDO rm -rf "$TARGET_DIR"
$SUDO mv "${EXTRACT_DIR}/Xcode.app" "$TARGET_DIR"
$SUDO xattr -dr com.apple.quarantine "$TARGET_DIR" 2>/dev/null || true
rm -rf "$EXTRACT_DIR"

# 6. Select and first-launch only with -y; otherwise print the commands.
finish_install
