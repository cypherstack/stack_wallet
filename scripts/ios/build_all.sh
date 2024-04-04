#!/bin/bash

set -e

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_1671

# ensure ios rust triples are there
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios

# ensure ios rust triples are there
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios

(cd ../../crypto_plugins/flutter_liblelantus/scripts/ios && ./build_all.sh )
(cd ../../crypto_plugins/flutter_libepiccash/scripts/ios && ./build_all.sh )
(cd ../../crypto_plugins/flutter_libmonero/scripts/ios   && ./build_all.sh )
set_rust_to_1720
(cd ../../crypto_plugins/frostdart/scripts/ios && ./build_all.sh )

wait

pushd ../../crypto_plugins/monero_c
    ./apply_patches.sh monero
    ./apply_patches.sh wownero
    rm -rf external/ios/build/ios/
    ./build_single.sh monero host-apple-ios -j8
    ./build_single.sh wownero host-apple-ios -j8

    unxz -f release/*/*.xz
popd

echo "Done building"

# ensure ios rust triples are there
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios
