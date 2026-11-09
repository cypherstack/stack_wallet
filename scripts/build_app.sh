#!/usr/bin/env bash

set -e

source "$(dirname -- "${BASH_SOURCE[0]}")/env.sh"

# Function to display usage.
usage() {
    echo "Usage: $0 -v <version> -b <build_number> -p <platform> -a <app> [-d] [-i] [-f] [-s]"
    echo "  Default: build dnix libraries from source with Nix and verify their hashes."
    echo "  -d: use verified dnix prebuilts; other packages may still build from source."
    echo "  -i: skip platform native dependencies (secure storage and secp256k1)."
    echo "  -f: build Isar from source. -s: use system Linux secure-storage libraries."
    exit "${1:-1}"
}

confirmDisclaimer() {
    while true; do
        # shellcheck disable=SC2162
        read -p "Please confirm you understand that when using certain values for <version> and <build_number> there is a chance that the resulting app WILL DELETE CRITICAL WALLET DATA. Are you sure you want to continue? (yes/no): " response
        case $response in
            [Yy][Ee][Ss] ) echo "Continuing..."; break;;
            [Nn][Oo] ) exit 0;;
            * ) echo "Invalid response";;
        esac
    done
}

# required args
unset -v APP_VERSION_STRING
unset -v APP_BUILD_NUMBER
unset -v APP_BUILD_PLATFORM
unset -v APP_NAMED_ID

# optional args (with defaults)
# -i: skip building the platform native deps (secure storage deps, secp256k1).
SKIP_NATIVE_DEPS_BUILD=0
# dnix checks the package's pinned hashes in both source and prebuilt mode.
DNIX_BUILD_MODE=source
BUILD_ISAR_FROM_SOURCE=0
USE_SYSTEM_SECURE_STORAGE_DEPS=0

# Parse command-line arguments.
while getopts "v:b:p:a:idfsh" opt; do
    case "${opt}" in
        v) APP_VERSION_STRING="$OPTARG" ;;
        b) APP_BUILD_NUMBER="$OPTARG" ;;
        p) APP_BUILD_PLATFORM="$OPTARG" ;;
        a) APP_NAMED_ID="$OPTARG" ;;
        i) SKIP_NATIVE_DEPS_BUILD=1 ;;
        d) DNIX_BUILD_MODE=prebuilt ;;
        f) BUILD_ISAR_FROM_SOURCE=1 ;;
        s) USE_SYSTEM_SECURE_STORAGE_DEPS=1 ;;
        h) usage 0 ;;
        *) usage ;;
    esac
done

if [ -z "$APP_VERSION_STRING" ]; then
  echo "Missing -v option"
  usage
fi

if [ -z "$APP_BUILD_NUMBER" ]; then
  echo "Missing -b option"
  usage
fi

if [ -z "$APP_BUILD_PLATFORM" ]; then
  echo "Missing -p option"
  usage
fi

if [ -z "$APP_NAMED_ID" ]; then
  echo "Missing -a option"
  usage
fi

case "$APP_BUILD_PLATFORM" in
    android|ios|macos|linux|windows) ;;
    *) echo "Invalid platform: ${APP_BUILD_PLATFORM}"; usage ;;
esac

case "$APP_NAMED_ID" in
    stack_wallet|stack_duo|campfire) ;;
    *) echo "Invalid app id: ${APP_NAMED_ID}"; usage ;;
esac

if [[ ! "$APP_VERSION_STRING" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$ ]]; then
    echo "Invalid version: ${APP_VERSION_STRING}"
    usage
fi

if [[ ! "$APP_BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "Invalid build number: ${APP_BUILD_NUMBER}"
    usage
fi

confirmDisclaimer
set -x

source "${APP_PROJECT_ROOT_DIR}/scripts/app_config/templates/configure_template_files.sh"

export BUILD_ISAR_FROM_SOURCE
export USE_SYSTEM_SECURE_STORAGE_DEPS

PLAY_STORE_ICON_FILE="${APP_PROJECT_ROOT_DIR}/android/app/src/main/app_icon-playstore.png"
if [ -f "${PLAY_STORE_ICON_FILE}" ]; then
  rm "${PLAY_STORE_ICON_FILE}"
fi
cp -rp "${APP_PROJECT_ROOT_DIR}/asset_sources/other/playstore_icon/${APP_NAMED_ID}/app_icon-playstore.png" "${PLAY_STORE_ICON_FILE}"

# apply config project wide change changes
"${APP_PROJECT_ROOT_DIR}/scripts/app_config/shared/update_version.sh" -v "${APP_VERSION_STRING}" -b "${APP_BUILD_NUMBER}"
"${APP_PROJECT_ROOT_DIR}/scripts/app_config/shared/link_assets.sh" "${APP_NAMED_ID}" "${APP_BUILD_PLATFORM}"
# shellcheck disable=SC1090
source "${APP_PROJECT_ROOT_DIR}/scripts/app_config/configure_${APP_NAMED_ID}.sh" "${APP_BUILD_PLATFORM}"
# Render the mode before any Flutter/Dart command that can run build hooks.
sed -i.bak "s/PLACEHOLDER_DNIX_BUILD_MODE/${DNIX_BUILD_MODE}/g" "${ACTUAL_PUBSPEC}"
rm -f "${ACTUAL_PUBSPEC}.bak"
"${APP_PROJECT_ROOT_DIR}/scripts/app_config/platforms/${APP_BUILD_PLATFORM}/platform_config.sh"

if [[ "$APP_BUILD_PLATFORM" != "linux" ]]; then
    # run icon and image generators after project config has completed for non linux
    "${APP_PROJECT_ROOT_DIR}/scripts/app_config/shared/asset_generators.sh" "${APP_BUILD_PLATFORM}"
fi

# Build platform native deps that are not provided by pub packages. The crypto
# plugins (flutter_libepiccash, flutter_libmwc, frostdart, tor_ffi_plugin) are native-assets
# packages now; their build hooks compile (or fetch) them during flutter build.
if [ "$SKIP_NATIVE_DEPS_BUILD" -eq 0 ]; then
    case "$APP_BUILD_PLATFORM" in
        linux)
            pushd "${APP_PROJECT_ROOT_DIR}/scripts/linux"
            ./build_secure_storage_deps.sh
            ./build_secp256k1.sh
            popd
            ;;
        windows)
            # Prebuilt jobs build secp256k1 separately after pub get, as before.
            if [ "$DNIX_BUILD_MODE" = source ]; then
                case "$(uname -s)" in
                    MINGW*|MSYS*|CYGWIN*)
                        pushd "${APP_PROJECT_ROOT_DIR}"
                        cmd.exe /c dart run coinlib:build_windows
                        popd
                        ;;
                    Linux*)
                        pushd "${APP_PROJECT_ROOT_DIR}/scripts/windows"
                        ./build_secp256k1_wsl.sh
                        popd
                        ;;
                    *) echo "Building Windows secp256k1 needs Windows or Linux/WSL." >&2; exit 1 ;;
                esac
            fi
            ;;
    esac
fi
