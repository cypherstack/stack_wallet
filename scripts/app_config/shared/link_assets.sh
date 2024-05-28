#!/usr/bin/env bash

set -x -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <theme specific assets dir name (ex. stack_wallet)> <platform (ex. windows)>"
    exit 1
fi

SELECT_ASSETS_DIR=$1
APP_BUILD_PLATFORM=$2

# declare full paths
ASSET_SOURCES_DIR="${APP_PROJECT_ROOT_DIR}/asset_sources"
ASSETS_DIR="${APP_PROJECT_ROOT_DIR}/assets"


# finally update symlinks

for dirname in "default_themes" "icon" "lottie" "in_app_logo_icons"; do
  LINK_SOURCE_DIR="${ASSET_SOURCES_DIR}/${dirname}/${SELECT_ASSETS_DIR}"

  rm -f "${ASSETS_DIR}/${dirname}"

  if [[ "${APP_BUILD_PLATFORM}" = 'windows' ]]; then
    LINK_SOURCE_DIR_WIN_PATH_VERSION=$(wslpath -w "${LINK_SOURCE_DIR}")
    LINK_NAME_WIN_PATH_VERSION=$(wslpath -w "${ASSETS_DIR}")
    cmd.exe /c mklink /D "${LINK_NAME_WIN_PATH_VERSION}\\${dirname}" "${LINK_SOURCE_DIR_WIN_PATH_VERSION}"
  else
    ln -s "${LINK_SOURCE_DIR}" "${ASSETS_DIR}/${dirname}"
  fi
done
