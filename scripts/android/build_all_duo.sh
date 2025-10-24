#!/bin/bash

set -x -e

# todo: revisit following at some point

mkdir -p build
. ./config.sh

PLUGINS_DIR=../../crypto_plugins

source ../rust_version.sh
set_rust_to_everything_else

(cd "${PLUGINS_DIR}"/frostdart/scripts/android && ./build_all.sh )

wait
echo "Done building"
