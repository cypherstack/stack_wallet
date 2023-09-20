#!/bin/bash

set -e

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_1680

mkdir -p build
(cd ../../crypto_plugins/flutter_libepiccash/scripts/windows && ./build_all.sh )  &
(cd ../../crypto_plugins/flutter_liblelantus/scripts/windows && ./build_all.sh ) &
(cd ../../crypto_plugins/flutter_libmonero/scripts/windows && ./build_all.sh) &

wait
echo "Done building"

# set rust (back) to a more recent stable release to allow stack wallet to build tor
set_rust_to_1720
