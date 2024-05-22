#!/usr/bin/env bash

set -x -e

source ./env.sh

APP_PLATFORMS=("android" "ios" "macos" "linux" "windows")
APP_NAMED_IDS=("stack_wallet" "stack_duo")

# Function to display usage.
usage() {
    echo "Usage: $0 -v <version> -b <build_number> -p <platform> -a <app>"
    exit 1
}

# required args
unset -v APP_VERSION_STRING
unset -v APP_BUILD_NUMBER
unset -v APP_BUILD_PLATFORM
unset -v APP_NAMED_ID

# optional args (with defaults)
BUILD_CRYPTO_PLUGINS=0

# Parse command-line arguments.
while getopts "v:b:p:a:i" opt; do
    case "${opt}" in
        v) APP_VERSION_STRING="$OPTARG" ;;
        b) APP_BUILD_NUMBER="$OPTARG" ;;
        p) APP_BUILD_PLATFORM="$OPTARG" ;;
        a) APP_NAMED_ID="$OPTARG" ;;
        i) BUILD_CRYPTO_PLUGINS=1 ;;
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



if printf '%s\0' "${APP_PLATFORMS[@]}" | grep -Fxqz -- "${APP_BUILD_PLATFORM}"; then
    pushd "${APP_PROJECT_ROOT_DIR}/scripts/${APP_BUILD_PLATFORM}"
else
    echo "Invalid platform: ${APP_BUILD_PLATFORM}"
    usage
fi

if printf '%s\0' "${APP_NAMED_IDS[@]}" | grep -Fxqz -- "${APP_NAMED_ID}"; then
    # shellcheck disable=SC1090
    source "${APP_PROJECT_ROOT_DIR}/scripts/app_config/configure_${APP_NAMED_ID}.sh"
    "${APP_PROJECT_ROOT_DIR}/scripts/app_config/shared/update_version.sh" -v "${APP_VERSION_STRING}" -b "${APP_BUILD_NUMBER}"
    "${APP_PROJECT_ROOT_DIR}/scripts/app_config/shared/link_assets.sh" "${APP_NAMED_ID}"
else
    echo "Invalid app id: ${APP_NAMED_ID}"
    exit 1
fi

if [ "$BUILD_CRYPTO_PLUGINS" -eq 0 ]; then
    if [[ "$APP_NAMED_ID" = "stack_wallet" ]]; then
        ./build_all.sh
    elif [[ "$APP_NAMED_ID" = "stack_duo" ]]; then
        ./build_all_duo.sh
    else
        echo "Invalid app id: ${APP_NAMED_ID}"
        exit 1
    fi
fi

popd
