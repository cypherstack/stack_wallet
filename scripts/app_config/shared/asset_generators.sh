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
  if command -v cygpath >/dev/null 2>&1; then
    WIN_PATH_VERSION=$(cygpath -w "${YAML_FILE}")
  else
    WIN_PATH_VERSION=$(wslpath -w "${YAML_FILE}")
  fi
  if [[ -n "${WINDOWS_FLUTTER_EXE:-}" && -n "${WINDOWS_DART_EXE:-}" ]]; then
    # shellcheck disable=SC2016 # PowerShell expands these expressions.
    powershell.exe -NoLogo -NoProfile -NonInteractive -Command \
      '& $env:WINDOWS_FLUTTER_EXE pub get; if ($LASTEXITCODE) { exit $LASTEXITCODE }'
    # shellcheck disable=SC2016 # PowerShell expands these expressions.
    powershell.exe -NoLogo -NoProfile -NonInteractive -Command \
      '& $env:WINDOWS_DART_EXE run flutter_launcher_icons -f $args[0]; exit $LASTEXITCODE' \
      "${WIN_PATH_VERSION}"
  else
    cmd.exe /c flutter pub get
    cmd.exe /c dart run flutter_launcher_icons -f "${WIN_PATH_VERSION}"
  fi
  # not needed in windows
#  cmd.exe /c dart run flutter_native_splash:create
else
  flutter pub get
  dart run flutter_launcher_icons -f "${YAML_FILE}"

  if [[ "${APP_BUILD_PLATFORM}" = 'ios' || "${APP_BUILD_PLATFORM}" = 'android' ]]; then
    dart run flutter_native_splash:create
  fi
fi
popd
