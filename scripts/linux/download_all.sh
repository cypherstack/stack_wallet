#!/bin/bash

set -x -e

APP="${1:-stack_wallet}"

mkdir -p build
./build_secure_storage_deps.sh

if [[ "$APP" = "stack_wallet" ]]; then
    (cd ../../crypto_plugins/flutter_libepiccash/scripts/linux && ./download.sh)
    (cd ../../crypto_plugins/flutter_libmwc/scripts/linux && ./download.sh)
fi

if [[ "$APP" = "stack_wallet" || "$APP" = "stack_duo" ]]; then
    (cd ../../crypto_plugins/frostdart/scripts/linux && ./download.sh)
fi

./build_secp256k1.sh

wait
echo "Done"
