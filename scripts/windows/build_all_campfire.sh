#!/bin/bash

set -x -e

mkdir -p build
(cd ../../crypto_plugins/flutter_libepiccash/scripts/windows && ./build_all.sh )
(cd ../../crypto_plugins/flutter_liblelantus/scripts/windows && ./build_all.sh )
(cd ../../crypto_plugins/frostdart/scripts/windows && ./build_all.sh )

./build_secp256k1_wsl.sh

wait
echo "Done building"
