#!/bin/bash

mkdir build
. ./config.sh
./install_ndk.sh

(cd ../../crypto_plugins/flutter_libepiccash/scripts/android && ./install_ndk.sh && ./build_all.sh )  &

wait
echo "Done building"
