#!/bin/bash

set -x -e

# for arm
# flutter-elinux clean
# flutter-elinux pub get
# flutter-elinux build linux --dart-define="IS_ARM=true"
mkdir -p build
./build_secure_storage_deps.sh

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_everything_else

./build_secp256k1.sh

wait
echo "Done building"
