mkdir -p build
cd build
git clone https://github.com/bitcoin-core/secp256k1
cd secp256k1
mkdir -p build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/x86_64-w64-mingw32.toolchain.cmake
cmake --build .
mkdir -p ../../../../../build
cp src/libsecp256k1-2.dll "../../../../../build/secp256k1.dll"
cd ../../../
