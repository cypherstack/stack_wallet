#!/bin/bash

set -e

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_1671

# for arm
# flutter-elinux clean
# flutter-elinux pub get
# flutter-elinux build linux --dart-define="IS_ARM=true"
mkdir -p build
./build_secure_storage_deps.sh

(cd ../../crypto_plugins/flutter_liblelantus/scripts/linux && ./build_all.sh )
(cd ../../crypto_plugins/flutter_libepiccash/scripts/linux && ./build_all.sh )

wait
set_rust_to_1720
(cd ../../crypto_plugins/frostdart/scripts/linux && ./build_all.sh )

wait
sudo apt install -y gcc g++ gperf # Can be removed (deps are listed in docs/building.md).
pushd ../../crypto_plugins/monero_c
    ./apply_patches.sh monero
    ./apply_patches.sh wownero
    ./build_single.sh monero $(gcc -dumpmachine) -j$(nproc)
    ./build_single.sh wownero $(gcc -dumpmachine) -j$(nproc)

    unxz -f release/*/*.xz
popd

wait
echo "Done building"
