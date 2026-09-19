#!/bin/bash

set -x -e

APP="${1:-stack_wallet}"

mkdir -p build

PLUGINS_DIR=../../crypto_plugins

if [[ "$APP" = "stack_wallet" ]]; then
    (cd "${PLUGINS_DIR}"/flutter_libepiccash/scripts/windows && ./download.sh)
    (cd "${PLUGINS_DIR}"/flutter_libmwc/scripts/windows && ./download.sh)
fi

if [[ "$APP" = "stack_wallet" || "$APP" = "stack_duo" ]]; then
    (cd "${PLUGINS_DIR}"/frostdart/scripts/windows && ./download.sh)
fi

wait
echo "Done"
