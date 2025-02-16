#!/bin/bash

set -x -e

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_1671

mkdir -p build
. ./config.sh
./install_ndk.sh

PLUGINS_DIR=../../crypto_plugins

(cd "${PLUGINS_DIR}"/flutter_liblelantus/scripts/android && ./build_all.sh )
set_rust_to_1720
(cd "${PLUGINS_DIR}"/flutter_libepiccash/scripts/android && ./build_all.sh )
(cd "${PLUGINS_DIR}"/frostdart/scripts/android && ./build_all.sh )

wait
echo "Done building"
