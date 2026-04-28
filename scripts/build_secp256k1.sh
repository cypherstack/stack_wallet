#!/usr/bin/env bash
# Build libsecp256k1.so from bitcoin-core/secp256k1 upstream source.
#
# This script clones the upstream repository, builds with autotools, and
# copies the resulting shared library to $PROJECT_ROOT/build/ where coin's
# NativeCurveGateIo FFI loader expects it.
#
# Requirements: git, autoconf, automake, libtool, gcc/clang, make
#
# Note: coin also supports a pure-Dart SoftCurveGate fallback that produces
# identical cryptographic results (just slower). If autotools are not
# available, you can copy an existing libsecp256k1.so from any valid build.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="/tmp/secp256k1-build"
OUTPUT_DIR="$PROJECT_ROOT/build"

echo "==> Building libsecp256k1 from bitcoin-core/secp256k1"

# Clean previous build
rm -rf "$BUILD_DIR"

# Clone upstream
echo "==> Cloning bitcoin-core/secp256k1..."
git clone --depth 1 https://github.com/bitcoin-core/secp256k1.git "$BUILD_DIR"
cd "$BUILD_DIR"

# Build with required modules
echo "==> Running autogen.sh..."
./autogen.sh

echo "==> Configuring with recovery, schnorrsig, ecdh, extrakeys modules..."
./configure \
  --enable-module-recovery \
  --enable-module-schnorrsig \
  --enable-module-ecdh \
  --enable-module-extrakeys

echo "==> Building..."
make -j"$(nproc)"

# Copy to project build directory
mkdir -p "$OUTPUT_DIR"
cp .libs/libsecp256k1.so "$OUTPUT_DIR/libsecp256k1.so"

echo "==> Installed: $OUTPUT_DIR/libsecp256k1.so"
echo ""
echo "Run tests with:"
echo "  LD_LIBRARY_PATH=$OUTPUT_DIR flutter test test/bitcoindart_coverage/"
