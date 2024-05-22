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

# check for required number of args
if [ $# -ne 8 ]; then
    usage
fi

unset -v APP_VERSION_STRING
unset -v APP_BUILD_NUMBER
unset -v APP_BUILD_PLATFORM
unset -v APP_NAMED_ID

# Parse command-line arguments.
while getopts "v:b:p:a:" opt; do
    case "$opt" in
        v) APP_VERSION_STRING="$OPTARG" ;;
        b) APP_BUILD_NUMBER="$OPTARG" ;;
        p) APP_BUILD_PLATFORM="$OPTARG" ;;
        a) APP_NAMED_ID="$OPTARG" ;;
        *) usage ;;
    esac
done

if printf '%s\0' "${APP_PLATFORMS[@]}" | grep -Fxqz -- "${APP_BUILD_PLATFORM}"; then
    pushd "${APP_PROJECT_ROOT_DIR}/scripts/${APP_BUILD_PLATFORM}"
else
    echo "Invalid platform: ${APP_BUILD_PLATFORM}"
    usage
fi

if printf '%s\0' "${APP_NAMED_IDS[@]}" | grep -Fxqz -- "${APP_NAMED_ID}"; then
    "${APP_PROJECT_ROOT_DIR}/scripts/app_config/update_version.sh" -v "${APP_VERSION_STRING}" -b "${APP_BUILD_NUMBER}"
    "${APP_PROJECT_ROOT_DIR}/scripts/app_config/shared/link_assets.sh" "${APP_NAMED_ID}"
else
    echo "Invalid app id: ${APP_NAMED_ID}"
    exit 1
fi

if [[ "$APP_NAMED_ID" = "stack_wallet" ]]; then
    ./build_all.sh
elif [[ "$APP_NAMED_ID" = "stack_duo" ]]; then
    "${APP_PROJECT_ROOT_DIR}/scripts/app_config/configure_duo.sh"
    ./build_all_duo.sh
else
    echo "Invalid app id: ${APP_NAMED_ID}"
    exit 1
fi

popd
