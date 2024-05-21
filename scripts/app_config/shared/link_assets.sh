#!/usr/bin/env bash

set -x -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <theme specific assets dir name (ex. stack_wallet)>"
    exit 1
fi


SELECT_ASSETS_DIR=$1

# set project root
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pushd "${SCRIPT_DIR}/../../../"
PROJECT_ROOT="$(pwd)"
popd

# declare full paths
ASSET_SOURCES_DIR="${PROJECT_ROOT}/asset_sources"
ASSETS_DIR="${PROJECT_ROOT}/assets"

# finally update symlinks

rm -f "${ASSETS_DIR}/default_themes"
ln -s "${ASSET_SOURCES_DIR}/bundled_themes/${SELECT_ASSETS_DIR}" "${ASSETS_DIR}/default_themes"

rm -f "${ASSETS_DIR}/icon"
ln -s "${ASSET_SOURCES_DIR}/icon/${SELECT_ASSETS_DIR}" "${ASSETS_DIR}/icon"




# todo run flutter_native_splash
# todo run flutter_launcher_icons