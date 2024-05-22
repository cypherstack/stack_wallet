#!/usr/bin/env bash

set -x -e

# run icon and image generators
pushd "${APP_PROJECT_ROOT_DIR}"
flutter pub get
#native splash screen not used
#dart run flutter_native_splash:create
dart run flutter_launcher_icons
popd