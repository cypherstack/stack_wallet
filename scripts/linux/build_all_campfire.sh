#!/bin/bash

set -x -e

# for arm
# flutter-elinux clean
# flutter-elinux pub get
# flutter-elinux build linux --dart-define="IS_ARM=true"
mkdir -p build
./build_secure_storage_deps.sh
(cd ../../crypto_plugins/flutter_liblelantus/scripts/linux && ./build_all.sh )
(cd ../../crypto_plugins/flutter_libepiccash/scripts/linux && ./build_all.sh )
(cd ../../crypto_plugins/frostdart/scripts/linux && ./build_all.sh )

./build_secp256k1.sh

wait
echo "Done building"
