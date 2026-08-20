#!/bin/bash

set -x -e

APP="${1:-stack_wallet}"

# for arm
# flutter-elinux clean
# flutter-elinux pub get
# flutter-elinux build linux --dart-define="IS_ARM=true"
mkdir -p build
./build_secure_storage_deps.sh

source ../rust_version.sh

if [[ "$APP" = "stack_wallet" ]]; then
    set_rust_version_for_libepiccash
    (cd ../../crypto_plugins/flutter_libepiccash/scripts/linux && ./build_all.sh )
    set_rust_version_for_libmwc
    (cd ../../crypto_plugins/flutter_libmwc/scripts/linux && ./build_all.sh )
fi

set_rust_to_everything_else

if [[ "$APP" = "stack_wallet" || "$APP" = "stack_duo" ]]; then
    (cd ../../crypto_plugins/frostdart/scripts/linux && ./build_all.sh )
fi

./build_secp256k1.sh

wait
echo "Done building"
