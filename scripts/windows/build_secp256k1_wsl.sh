mkdir -p build
cd build
if [ ! -d "secp256k1" ]; then
    git clone https://github.com/bitcoin-core/secp256k1
fi
cd secp256k1
git checkout 68b55209f1ba3e6c0417789598f5f75649e9c14c
git reset --hard
mkdir -p build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../cmake/x86_64-w64-mingw32.toolchain.cmake
cmake --build .
mkdir -p ../../../../../build
cp bin/libsecp256k1-2.dll "../../../../../build/secp256k1.dll"
cd ../../../
