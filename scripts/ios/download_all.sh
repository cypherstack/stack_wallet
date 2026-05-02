#!/bin/bash

set -x -e

mkdir -p build

PLUGINS_DIR=../../crypto_plugins

(cd "${PLUGINS_DIR}"/flutter_libepiccash/scripts/ios && ./download.sh)

(cd "${PLUGINS_DIR}"/flutter_libmwc/scripts/ios && ./download.sh)

# frostdart iOS is built from source by Cargokit at pod install time

wait
echo "Done"
