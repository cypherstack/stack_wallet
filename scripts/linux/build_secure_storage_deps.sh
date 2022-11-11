#!/bin/bash
LINUX_DIRECTORY=$(pwd)
mkdir -p build

# Build JsonCPP
cd build || exit
if ! [ -x "$(command -v git)" ]; then
  echo 'Error: git is not installed.' >&2
  exit 1
fi
git -C jsoncpp pull || git clone https://github.com/open-source-parsers/jsoncpp.git jsoncpp
cd jsoncpp || exit
git checkout 1.7.4
mkdir -p build
cd build || exit
cmake -DCMAKE_BUILD_TYPE=release -DBUILD_STATIC_LIBS=ON -DBUILD_SHARED_LIBS=ON -DARCHIVE_INSTALL_DIR=. -G "Unix Makefiles" ..
make -j"$(nproc)"

cd "$LINUX_DIRECTORY" || exit
# Build libSecret
# sudo apt install meson libgirepository1.0-dev valac xsltproc gi-docgen docbook-xsl
# sudo apt install python3-pip
#pip3 install --user meson --upgrade
# pip3 install --user gi-docgen
cd build || exit
git -C libsecret pull || git clone https://gitlab.gnome.org/GNOME/libsecret.git libsecret
cd libsecret || exit
if ! [ -x "$(command -v meson)" ]; then
  echo 'Error: meson is not installed.' >&2
  exit 1
fi
meson _build
if ! [ -x "$(command -v ninja)" ]; then
  echo 'Error: ninja is not installed.' >&2
  exit 1
fi
ninja -C _build
