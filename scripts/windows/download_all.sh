#!/bin/bash

set -x -e

mkdir -p build

PLUGINS_DIR=../../crypto_plugins

(cd "${PLUGINS_DIR}"/flutter_libepiccash/scripts/windows && ./download.sh)

(cd "${PLUGINS_DIR}"/flutter_libmwc/scripts/windows && ./download.sh)

(cd "${PLUGINS_DIR}"/frostdart/scripts/windows && ./download.sh)

wait
echo "Done"
