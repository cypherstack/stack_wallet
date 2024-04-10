#!/bin/bash

set -e

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_1671

(cd ../../crypto_plugins/flutter_liblelantus/scripts/macos && ./build_all.sh )
(cd ../../crypto_plugins/flutter_libepiccash/scripts/macos && ./build_all.sh )

wait
set_rust_to_1720
(cd ../../crypto_plugins/frostdart/scripts/macos && ./build_all.sh )

wait
pushd ../../crypto_plugins/monero_c
    ./apply_patches.sh monero
    ./apply_patches.sh wownero
    ./build_single.sh monero host-apple-darwin -j$(nproc)
    ./build_single.sh wownero host-apple-darwin -j$(nproc)

    unxz -f release/*/*.xz
popd

echo "Done building"

# set rust (back) to a more recent stable release to allow stack wallet to build tor
set_rust_to_1720
