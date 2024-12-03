#!/bin/bash

set -x -e

# todo: revisit following at some point

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_1671

mkdir -p build
(cd ../../crypto_plugins/flutter_libepiccash/scripts/windows && ./build_all.sh )
(cd ../../crypto_plugins/flutter_liblelantus/scripts/windows && ./build_all.sh )
set_rust_to_1720
(cd ../../crypto_plugins/frostdart/scripts/windows && ./build_all.sh )

./build_secp256k1_wsl.sh

wait
echo "Done building"
