#!/bin/bash

set -x -e

# ensure ios rust triples are there
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios

# ensure ios rust triples are there
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios

# libepiccash requires old rust
source ../rust_version.sh
set_rust_version_for_libepiccash
(cd ../../crypto_plugins/flutter_libepiccash/scripts/ios && ./build_all.sh )
set_rust_to_1810
(cd ../../crypto_plugins/flutter_libmwc/scripts/ios/ && ./build_all.sh )
set_rust_to_1720
# set rust (back) to a more recent stable release after building epiccash
set_rust_to_everything_else

(cd ../../crypto_plugins/frostdart/scripts/ios && ./build_all.sh )

wait
echo "Done building"

# ensure ios rust triples are there
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios
