#!/bin/bash

set -x -e

mkdir -p build

PLUGINS_DIR=../../crypto_plugins

(cd "${PLUGINS_DIR}"/flutter_libepiccash/scripts/ios && ./download.sh)

(cd "${PLUGINS_DIR}"/flutter_libmwc/scripts/ios && ./download.sh)

(cd "${PLUGINS_DIR}"/frostdart/scripts/ios && ./download.sh)

wait
echo "Done"
