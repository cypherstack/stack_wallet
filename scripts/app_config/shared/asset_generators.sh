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
if [[ "${APP_BUILD_PLATFORM}" = 'windows' ]]; then
  cmd.exe /c flutter pub get
  WIN_PATH_VERSION=$(wslpath -w ${YAML_FILE})
  cmd.exe /c dart run flutter_launcher_icons -f "${WIN_PATH_VERSION}"
  #native splash screen not used
  #cmd.exe /c dart run flutter_native_splash:create
else
  flutter pub get
  dart run flutter_launcher_icons -f "${YAML_FILE}"
  #native splash screen not used
  #dart run flutter_native_splash:create
fi
popd