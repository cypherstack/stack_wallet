#!/bin/bash

set -x -e

mkdir -p build
./build_secure_storage_deps.sh

(cd ../../crypto_plugins/flutter_libepiccash/scripts/linux && ./download.sh)

(cd ../../crypto_plugins/flutter_libmwc/scripts/linux && ./download.sh)

(cd ../../crypto_plugins/frostdart/scripts/linux && ./download.sh)

./build_secp256k1.sh

wait
echo "Done"
