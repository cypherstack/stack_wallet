#!/bin/bash

set -x -e

mkdir -p build
. ./config.sh

PLUGINS_DIR=../../crypto_plugins

(cd "${PLUGINS_DIR}"/flutter_libepiccash/scripts/android && ./download.sh)

(cd "${PLUGINS_DIR}"/flutter_libmwc/scripts/android && ./download.sh)

(cd "${PLUGINS_DIR}"/frostdart/scripts/android && ./download.sh)

wait
echo "Done"
