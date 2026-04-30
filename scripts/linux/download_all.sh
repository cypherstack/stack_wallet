#!/bin/bash

set -x -e

mkdir -p build
./build_secure_storage_deps.sh

(cd ../../crypto_plugins/flutter_libepiccash/scripts/linux && ./download.sh)

source ../rust_version.sh
set_rust_version_for_libmwc
(cd ../../crypto_plugins/flutter_libmwc/scripts/linux && ./build_all.sh)
set_rust_to_everything_else

(cd ../../crypto_plugins/frostdart/scripts/linux && ./build_all.sh)

./build_secp256k1.sh

wait
echo "Done"
