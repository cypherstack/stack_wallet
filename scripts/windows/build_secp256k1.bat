if not exist "build" mkdir "build"
cd build
rem git clone https://github.com/bitcoin-core/secp256k1
cd secp256k1
rem cmake -G "Visual Studio 17 2022" -A x64 -S . -B build
cd build
rem cmake --build .
if not exist "..\..\..\..\build\" mkdir "..\..\..\..\build\"
xcopy src\Debug\libsecp256k1-2.dll "..\..\..\..\build\secp256k1.dll" /Y
cd ..\..\..\
