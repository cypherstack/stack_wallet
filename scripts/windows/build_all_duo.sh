#!/bin/bash

set -x -e

# todo: revisit following at some point

mkdir -p build

# libepiccash requires old rust
source ../rust_version.sh
set_rust_version_for_libepiccash
(cd ../../crypto_plugins/flutter_libepiccash/scripts/windows && ./build_all.sh )
# set rust (back) to a more recent stable release after building epiccash
set_rust_to_everything_else

(cd ../../crypto_plugins/flutter_liblelantus/scripts/windows && ./build_all.sh )
(cd ../../crypto_plugins/frostdart/scripts/windows && ./build_all.sh )

./build_secp256k1_wsl.sh

wait
echo "Done building"
