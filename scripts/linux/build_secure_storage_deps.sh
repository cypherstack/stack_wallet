#!/bin/bash
LINUX_DIRECTORY=$(pwd)
mkdir build

# Build JsonCPP
cd build
git clone https://github.com/open-source-parsers/jsoncpp.git
cd jsoncpp
git checkout 1.7.4
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=release -DBUILD_STATIC_LIBS=ON -DBUILD_SHARED_LIBS=ON -DARCHIVE_INSTALL_DIR=. -G "Unix Makefiles" ..
make -j$(nproc)

cd $LINUX_DIRECTORY
# Build libSecret
# sudo apt install meson libgirepository1.0-dev valac xsltproc gi-docgen docbook-xsl
# sudo apt install python3-pip
#pip3 install --user meson --upgrade
# pip3 install --user gi-docgen
cd build
git clone https://gitlab.gnome.org/GNOME/libsecret.git
cd libsecret
meson _build
ninja -C _build
