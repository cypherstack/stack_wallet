#!/usr/bin/env bash

set -x -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <platform>"
    exit 1
fi

APP_BUILD_PLATFORM=$1

# run icon and image generators
pushd "${APP_PROJECT_ROOT_DIR}"
YAML_FILE="${APP_PROJECT_ROOT_DIR}/scripts/app_config/platforms/${APP_BUILD_PLATFORM}/flutter_launcher_icons.yaml"
flutter pub get
dart run flutter_launcher_icons -f "${YAML_FILE}"

if [[ "${APP_BUILD_PLATFORM}" = 'ios' || "${APP_BUILD_PLATFORM}" = 'android' ]]; then
  dart run flutter_native_splash:create
fi
popd
