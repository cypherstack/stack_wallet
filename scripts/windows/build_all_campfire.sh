#!/bin/bash

set -x -e

mkdir -p build

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_everything_else

./build_secp256k1_wsl.sh

wait
echo "Done building"
