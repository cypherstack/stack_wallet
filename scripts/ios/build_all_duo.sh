#!/bin/bash

set -x -e

# todo: revisit following at some point

# ensure ios rust triples are there
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios

# ensure ios rust triples are there
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_everything_else

(cd ../../crypto_plugins/frostdart/scripts/ios && ./build_all.sh )

wait
echo "Done building"

# ensure ios rust triples are there
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios
