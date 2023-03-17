#!/bin/bash

# for arm
# flutter-elinux clean
# flutter-elinux pub get
# flutter-elinux build linux --dart-define="IS_ARM=true"
mkdir -p build
./build_secure_storage_deps.sh &
(cd ../../crypto_plugins/flutter_libmonero/scripts/linux && ./build_iconv.sh && ./build_boost.sh && ./build_openssl.sh && ./build_sodium.sh && ./build_unbound.sh && ./build_zmq.sh && ./build_monero.sh && ./copy_monero_deps.sh ) &
(cd ../../../../scripts/linux ./build_sharedfile.sh ) &

wait
echo "Done building"
