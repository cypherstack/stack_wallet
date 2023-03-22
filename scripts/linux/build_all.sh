#!/bin/bash

# for arm
# flutter-elinux clean
# flutter-elinux pub get
# flutter-elinux build linux --dart-define="IS_ARM=true"
mkdir -p build
./build_secure_storage_deps.sh &
(cd ../../crypto_plugins/flutter_libmonero/scripts/linux && ./build_monero_all.sh ) &

wait
echo "Done building"
