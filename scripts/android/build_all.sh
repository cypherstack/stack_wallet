#!/bin/bash

set -x -e

APP="${1:-stack_wallet}"

mkdir -p build
. ./config.sh

PLUGINS_DIR=../../crypto_plugins

source ../rust_version.sh

if [[ "$APP" = "stack_wallet" ]]; then
    set_rust_version_for_libepiccash
    (cd "${PLUGINS_DIR}"/flutter_libepiccash/scripts/android && ./build_all.sh )
    set_rust_version_for_libmwc
    (cd "${PLUGINS_DIR}"/flutter_libmwc/scripts/android && ./build_all.sh )
fi

set_rust_to_everything_else

if [[ "$APP" = "stack_wallet" || "$APP" = "stack_duo" ]]; then
    (cd "${PLUGINS_DIR}"/frostdart/scripts/android && ./build_all.sh )
fi

wait
echo "Done building"
