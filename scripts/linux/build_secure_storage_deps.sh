#!/bin/bash
LINUX_DIRECTORY=$(pwd)
mkdir build

# Build JsonCPP
cd build
git clone https://github.com/open-source-parsers/jsoncpp.git
git checkout 8190e061bc2d95da37479a638aa2c9e483e58ec6
cd jsoncpp
mkdir build
cd build
cmake ..
make -j$(nproc)

cd $LINUX_DIRECTORY
# Build libSecret
# sudo apt install libgirepository1.0-dev valac xsltproc gi-docgen docbook-xsl
# pip3 install --user gi-docgen
cd build
git clone https://gitlab.gnome.org/GNOME/libsecret.git
cd libsecret
meson _build
ninja -C _build
