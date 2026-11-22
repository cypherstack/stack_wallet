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

# The coinlib CMake install step expects the library inside Flutter's build
# tree (build/linux/<arch>/release/secp256k1/lib). On a clean checkout nothing
# else puts it there, and the install step fails with "file INSTALL cannot
# find .../secp256k1/lib/libsecp256k1.so". Provide it, but never overwrite a
# library that is already there: a rebuild must keep shipping the same one.
# Match Flutter's architecture directory name (x64, arm64).
case "$(uname -m)" in
    x86_64|x64) FLUTTER_ARCH=x64 ;;
    aarch64|arm64) FLUTTER_ARCH=arm64 ;;
    *) FLUTTER_ARCH="$(uname -m)" ;;
esac
COINLIB_SECP_DIR="../../../../../build/linux/${FLUTTER_ARCH}/release/secp256k1/lib"
mkdir -p "$COINLIB_SECP_DIR"
if [ ! -e "$COINLIB_SECP_DIR/libsecp256k1.so" ]; then
    cp "$SECP_SO" "$COINLIB_SECP_DIR/libsecp256k1.so"
fi
