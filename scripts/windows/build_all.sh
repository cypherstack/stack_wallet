#!/bin/bash

set -e

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_1671

mkdir -p build
(cd ../../crypto_plugins/flutter_libepiccash/scripts/windows && ./build_all.sh )
(cd ../../crypto_plugins/flutter_liblelantus/scripts/windows && ./build_all.sh )

set_rust_to_1720
(cd ../../crypto_plugins/frostdart/scripts/windows && ./build_all.sh )

wait
sudo apt install -y gcc g++ gperf # Can be removed (deps are listed in docs/building.md).
pushd ../../crypto_plugins/monero_c
    ./apply_patches.sh monero
    ./apply_patches.sh wownero
    ./build_single.sh monero x86_64-w64-mingw32 -j$(nproc)
    ./build_single.sh wownero x86_64-w64-mingw32 -j$(nproc)

    unxz -f release/*/*.xz
pop

wait
echo "Done building"
