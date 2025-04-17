mkdir -p build
cd build
if [ ! -d "secp256k1" ]; then
    git clone https://github.com/bitcoin-core/secp256k1
fi
cd secp256k1
git checkout 68b55209f1ba3e6c0417789598f5f75649e9c14c
git reset --hard
mkdir -p build && cd build
cmake ..
cmake --build .
mkdir -p ../../../../../build
cp lib/libsecp256k1.so.2.2.2 "../../../../../build/libsecp256k1.so"
cd ../../../