#!/bin/bash

set -x -e

APP="${1:-stack_wallet}"

mkdir -p build

PLUGINS_DIR=../../crypto_plugins

if [[ "$APP" = "stack_wallet" ]]; then
    (cd "${PLUGINS_DIR}"/flutter_libepiccash/scripts/macos && ./download.sh)
    (cd "${PLUGINS_DIR}"/flutter_libmwc/scripts/macos && ./download.sh)
fi

if [[ "$APP" = "stack_wallet" || "$APP" = "stack_duo" ]]; then
    (cd "${PLUGINS_DIR}"/frostdart/scripts/macos && ./download.sh)
fi

wait
echo "Done"
