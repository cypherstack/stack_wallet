#!/bin/bash

set -x -e

APP="${1:-stack_wallet}"

source ../rust_version.sh

if [[ "$APP" = "stack_wallet" ]]; then
    set_rust_version_for_libepiccash
    (cd ../../crypto_plugins/flutter_libepiccash/scripts/macos && ./build_all.sh )
    set_rust_version_for_libmwc
    (cd ../../crypto_plugins/flutter_libmwc/scripts/macos && ./build_all.sh )
fi

set_rust_to_everything_else

if [[ "$APP" = "stack_wallet" || "$APP" = "stack_duo" ]]; then
    (cd ../../crypto_plugins/frostdart/scripts/macos && ./build_all.sh )
fi

wait
echo "Done building"
