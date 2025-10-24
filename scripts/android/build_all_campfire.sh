#!/bin/bash

set -x -e

mkdir -p build
. ./config.sh

PLUGINS_DIR=../../crypto_plugins

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_everything_else

wait
echo "Done building"
