#!/bin/bash

set -x -e

APP="${1:-stack_wallet}"

mkdir -p build
. ./config.sh

PLUGINS_DIR=../../crypto_plugins

if [[ "$APP" = "stack_wallet" ]]; then
    (cd "${PLUGINS_DIR}"/flutter_libepiccash/scripts/android && ./download.sh)
    (cd "${PLUGINS_DIR}"/flutter_libmwc/scripts/android && ./download.sh)
fi

if [[ "$APP" = "stack_wallet" || "$APP" = "stack_duo" ]]; then
    (cd "${PLUGINS_DIR}"/frostdart/scripts/android && ./download.sh)
fi

wait
echo "Done"
