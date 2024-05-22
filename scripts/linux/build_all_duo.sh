#!/bin/bash

set -x -e

# Configure Linux for Duo.
sed -i "s/${ORIGINAL_APP_ID}/${NEW_APP_ID}/g" ../../linux/CMakeLists.txt
sed -i "s/${ORIGINAL_NAME}/${NEW_NAME}/g" ../../linux/my_application.cc

# todo: revisit following at some point

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_1671

# for arm
# flutter-elinux clean
# flutter-elinux pub get
# flutter-elinux build linux --dart-define="IS_ARM=true"
mkdir -p build
./build_secure_storage_deps.sh &
(cd ../../crypto_plugins/flutter_liblelantus/scripts/linux && ./build_all.sh ) &
(cd ../../crypto_plugins/flutter_libepiccash/scripts/linux && ./build_all.sh )  &
(cd ../../crypto_plugins/flutter_libmonero/scripts/linux && ./build_monero_all.sh && ./build_sharedfile.sh )
set_rust_to_1720
(cd ../../crypto_plugins/frostdart/scripts/linux && ./build_all.sh ) &

./build_secp256k1.sh

wait
echo "Done building"
