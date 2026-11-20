#!/usr/bin/env bash
set -e

mkdir -p build
cd build

if [ ! -d "secp256k1" ]; then
    git clone https://github.com/bitcoin-core/secp256k1
fi

cd secp256k1
git checkout 68b55209f1ba3e6c0417789598f5f75649e9c14c
git reset --hard

rm -rf build
mkdir -p build
cd build
cmake .. -DSECP256K1_ENABLE_MODULE_RECOVERY=ON
cmake --build .

SECP_SO="$(find lib -maxdepth 1 -type f -name 'libsecp256k1.so*' | sort | head -n1)"
if [ -z "$SECP_SO" ]; then
    echo "[ERROR] libsecp256k1 shared library not found after build."
    exit 1
fi

# Legacy location used by parts of the build pipeline.
mkdir -p ../../../../../build
cp "$SECP_SO" ../../../../../build/libsecp256k1.so

# Do not copy into coinlib's output folder
# (build/linux/<arch>/release/secp256k1/lib). coinlib builds its own pinned
# libsecp256k1 there; overwriting it made a rebuilt bundle ship a different
# version than a clean build. If that library is missing on a host, fix the
# coinlib build instead of patching its output from here.
