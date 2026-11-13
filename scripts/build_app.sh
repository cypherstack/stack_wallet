#!/usr/bin/env bash

set -e

source "$(dirname -- "${BASH_SOURCE[0]}")/env.sh"

# Function to display usage.
usage() {
    echo "Usage: $0 -v <version> -b <build_number> -p <platform> -a <app> [-d] [-i] [-f] [-s] [-w <wsl-distro>]"
    echo "  Default: build dnix libraries from source with Nix and verify their hashes."
    echo "  -d: use verified dnix prebuilts; other packages may still build from source."
    echo "  -i: skip platform native dependencies (secure storage and secp256k1)."
    echo "  -f: build Isar from source. -s: use system Linux secure-storage libraries."
    echo "  -w: dnix WSL distribution (default: DNIX_WSL_DISTRIBUTION or WSL default)."
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
DNIX_WSL_DISTRIBUTION="${DNIX_WSL_DISTRIBUTION:-}"
BUILD_ISAR_FROM_SOURCE=0
USE_SYSTEM_SECURE_STORAGE_DEPS=0

# Parse command-line arguments.
while getopts "v:b:p:a:w:idfsh" opt; do
    case "${opt}" in
        v) APP_VERSION_STRING="$OPTARG" ;;
        b) APP_BUILD_NUMBER="$OPTARG" ;;
        p) APP_BUILD_PLATFORM="$OPTARG" ;;
        a) APP_NAMED_ID="$OPTARG" ;;
        i) SKIP_NATIVE_DEPS_BUILD=1 ;;
        d) DNIX_BUILD_MODE=prebuilt ;;
        f) BUILD_ISAR_FROM_SOURCE=1 ;;
        s) USE_SYSTEM_SECURE_STORAGE_DEPS=1 ;;
        w) [ -n "$OPTARG" ] || { echo "Invalid WSL distribution: -w needs a name"; usage; }
           DNIX_WSL_DISTRIBUTION="$OPTARG" ;;
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

# Check requirements before replacing any generated app/platform files.
# Windows apps are configured from Git Bash and built by native Windows Flutter.
if [ "$APP_BUILD_PLATFORM" = windows ]; then
    case "$(uname -s)" in
        MINGW*|MSYS*) ;;
        *) echo "Configure Windows builds from Git Bash on Windows." >&2; exit 1 ;;
    esac
fi
dart "${APP_PROJECT_ROOT_DIR}/tool/check_native_overrides.dart" "$APP_NAMED_ID"
DNIX_DISTRIBUTION_ARGS=()
if [ -n "$DNIX_WSL_DISTRIBUTION" ]; then
    DNIX_DISTRIBUTION_ARGS=("$DNIX_WSL_DISTRIBUTION")
fi
dart "${APP_PROJECT_ROOT_DIR}/tool/check_build_environment.dart" \
    "$APP_BUILD_PLATFORM" "$APP_NAMED_ID" "$DNIX_BUILD_MODE" "${DNIX_DISTRIBUTION_ARGS[@]}"
if [ "$APP_BUILD_PLATFORM" = windows ] && [ "$SKIP_NATIVE_DEPS_BUILD" -eq 0 ]; then
    dart "${APP_PROJECT_ROOT_DIR}/scripts/windows/build_secp256k1.dart" --check
fi
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
# Record settings for later app builds. Icon/splash executables do not run the
# application's native hooks; each executable uses its own dependency closure.
dart "${APP_PROJECT_ROOT_DIR}/tool/configure_native_assets.dart" \
    "${ACTUAL_PUBSPEC}" "$DNIX_BUILD_MODE" "${DNIX_DISTRIBUTION_ARGS[@]}"
"${APP_PROJECT_ROOT_DIR}/scripts/app_config/platforms/${APP_BUILD_PLATFORM}/platform_config.sh"

if [[ "$APP_BUILD_PLATFORM" != "linux" ]]; then
    # run icon and image generators after project config has completed for non linux
    "${APP_PROJECT_ROOT_DIR}/scripts/app_config/shared/asset_generators.sh" "${APP_BUILD_PLATFORM}"
fi

# Asset generation can resolve dependencies; inspect the resulting checkouts too.
dart "${APP_PROJECT_ROOT_DIR}/tool/check_native_overrides.dart" "$APP_NAMED_ID"

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
            # -d only selects dnix prebuilts. Rebuild this separate library
            # unless -i skips platform native dependencies.
            dart "${APP_PROJECT_ROOT_DIR}/scripts/windows/build_secp256k1.dart"
            ;;
    esac
fi
