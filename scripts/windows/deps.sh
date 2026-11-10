#!/bin/bash

# Toolchain for cross-compiling secp256k1.dll from WSL (build_secp256k1_wsl.sh).
sudo apt install clang gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64
sudo apt install libgtk2.0-dev

wait
echo "Done building"
