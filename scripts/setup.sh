#!/bin/bash

sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y
mkdir "$HOME/development"
mkdir "$HOME/projects"
sudo apt install -y git build-essential curl
export DEVELOPMENT=$HOME/development
export PROJECTS=$HOME/projects

# setup flutter
sudo apt install -y unzip pkg-config clang cmake ninja-build libgtk-3-dev
cd $DEVELOPMENT
git clone https://github.com/flutter/flutter.git
cd flutter 
git checkout 3.7.6
export FLUTTER_DIR=$(pwd)/bin
echo 'export PATH="$PATH:'${FLUTTER_DIR}'"' >> ~/.bashrc
source ~/.bashrc
flutter doctor

# setup stack_duo github
cd $PROJECTS
git clone https://github.com/cypherstack/stack_duo.git
cd stack_duo
export STACK_DUO=$(pwd)
git submodule update --init --recursive

# Create template lib/external_api_keys.dart file if it doesn't already exist
KEYS="$HOME/projects/stack_duo/lib/external_api_keys.dart"
if ! test -f "$KEYS"; then
    echo 'prebuild.sh: creating template lib/external_api_keys.dart file'
    printf 'const kChangeNowApiKey = "";\nconst kSimpleSwapApiKey = "";' > $KEYS
fi

#install stack wallet dependencies
sudo apt-get install -y unzip automake build-essential file pkg-config git python libtool libtinfo5 cmake openjdk-8-jre-headless libgit2-dev clang libncurses5-dev libncursesw5-dev zlib1g-dev llvm 

sudo apt-get install -y debhelper libclang-dev cargo rustc opencl-headers libssl-dev ocl-icd-opencl-dev

sudo apt-get install -y unzip automake build-essential file pkg-config git python libtool libtinfo5 cmake openjdk-8-jre-headless

sudo apt install -y libc6-dev-i386

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh  -s -- -y
cargo install cargo-ndk
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android

# build stack wallet plugins
cd $STACK_DUO
cd scripts/android
./build_all.sh
