#!/bin/bash
LINUX_DIRECTORY=$(pwd)
JSONCPP_TAG=1.7.4
mkdir -p build

# Build JsonCPP
cd build || exit 1
if ! [ -x "$(command -v git)" ]; then
  echo 'Error: git is not installed.' >&2
  exit 1
fi
git -C jsoncpp pull origin $JSONCPP_TAG || git clone https://github.com/open-source-parsers/jsoncpp.git jsoncpp
cd jsoncpp || exit 1
git checkout $JSONCPP_TAG
mkdir -p build
cd build || exit 1
cmake -DCMAKE_BUILD_TYPE=release -DBUILD_STATIC_LIBS=ON -DBUILD_SHARED_LIBS=ON -DARCHIVE_INSTALL_DIR=. -G "Unix Makefiles" ..
make -j"$(nproc)"

cd "$LINUX_DIRECTORY" || exit 1
# Build libSecret
# sudo apt install meson libgirepository1.0-dev valac xsltproc gi-docgen docbook-xsl
# sudo apt install python3-pip
#pip3 install --user meson markdown tomli --upgrade
# pip3 install --user gi-docgen
cd build || exit 1
git -C libsecret pull || git clone https://gitlab.gnome.org/GNOME/libsecret.git libsecret
cd libsecret || exit 1
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
