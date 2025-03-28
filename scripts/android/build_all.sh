#!/bin/bash

set -x -e

mkdir -p build
. ./config.sh

PLUGINS_DIR=../../crypto_plugins

(cd "${PLUGINS_DIR}"/flutter_liblelantus/scripts/android && ./build_all.sh )

# libepiccash requires old rust
source ../rust_version.sh
set_rust_version_for_libepiccash
(cd "${PLUGINS_DIR}"/flutter_libepiccash/scripts/android && ./build_all.sh )
# set rust (back) to a more recent stable release after building epiccash
set_rust_to_everything_else

(cd "${PLUGINS_DIR}"/frostdart/scripts/android && ./build_all.sh )

wait
echo "Done building"
