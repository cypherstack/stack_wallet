#!/bin/bash

mkdir build
. ./config.sh
./install_ndk.sh

(cd ../../crypto_plugins/flutter_libmonero/scripts/android/ && ./install_ndk.sh && ./build_monero_all.sh && ./copy_monero_deps.sh  ) &

wait
echo "Done building"
