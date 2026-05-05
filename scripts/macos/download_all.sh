#!/bin/bash

set -x -e

mkdir -p build

PLUGINS_DIR=../../crypto_plugins

(cd "${PLUGINS_DIR}"/flutter_libepiccash/scripts/macos && ./download.sh)

(cd "${PLUGINS_DIR}"/flutter_libmwc/scripts/macos && ./download.sh)

(cd "${PLUGINS_DIR}"/frostdart/scripts/macos && ./download.sh)

wait
echo "Done"
