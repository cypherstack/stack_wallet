#!/bin/bash

set -e

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_1671

mkdir -p build
. ./config.sh
./install_ndk.sh

(cd ../../crypto_plugins/flutter_liblelantus/scripts/android && ./build_all.sh )
(cd ../../crypto_plugins/flutter_libepiccash/scripts/android && ./install_ndk.sh && ./build_openssl.sh && ./build_all.sh )
(cd ../../crypto_plugins/flutter_libmonero/scripts/android/ && ./build_all.sh)

wait
echo "Done building"

# set rust (back) to a more recent stable release to allow stack wallet to build tor
set_rust_to_1720

