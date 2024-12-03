if not exist "build" mkdir "build"
cd build
git clone https://github.com/bitcoin-core/secp256k1
cd secp256k1
git checkout 68b55209f1ba3e6c0417789598f5f75649e9c14c
git reset --hard
cmake -G "Visual Studio 17 2022" -A x64 -S . -B build
cd build
cmake --build .
if not exist "..\..\..\..\build\" mkdir "..\..\..\..\build\"
xcopy bin\Debug\libsecp256k1-2.dll "..\..\..\..\build\secp256k1.dll" /Y
cd ..\..\..\
