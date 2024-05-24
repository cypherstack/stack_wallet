#!/usr/bin/env bash

set -x -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <platform>"
    exit 1
fi

APP_BUILD_PLATFORM=$1

# run icon and image generators
pushd "${APP_PROJECT_ROOT_DIR}"
flutter pub get
#native splash screen not used
#dart run flutter_native_splash:create
dart run flutter_launcher_icons -f "${APP_PROJECT_ROOT_DIR}/scripts/app_config/platforms/${APP_BUILD_PLATFORM}/flutter_launcher_icons.yaml"
popd