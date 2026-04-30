#!/bin/bash

set -x -e

mkdir -p build
. ./config.sh

PLUGINS_DIR=../../crypto_plugins

(cd "${PLUGINS_DIR}"/flutter_libepiccash/scripts/android && ./download.sh)

source ../rust_version.sh
set_rust_version_for_libmwc
(cd "${PLUGINS_DIR}"/flutter_libmwc/scripts/android && ./build_all.sh)
set_rust_to_everything_else

(cd "${PLUGINS_DIR}"/frostdart/scripts/android && ./build_all.sh)

wait
echo "Done"
