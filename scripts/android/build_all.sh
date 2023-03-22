#!/bin/bash

mkdir build
. ./config.sh
./install_ndk.sh

(cd ../../crypto_plugins/flutter_libmonero/scripts/android/ && ./build_all.sh ) &

wait
echo "Done building"
