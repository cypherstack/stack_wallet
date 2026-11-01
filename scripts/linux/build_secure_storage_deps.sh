#!/usr/bin/env bash

if [ "${USE_SYSTEM_SECURE_STORAGE_DEPS:-0}" = "1" ]; then
    echo "USE_SYSTEM_SECURE_STORAGE_DEPS is set; skipping build of jsoncpp and libsecret (using system packages)"
    exit 0
fi

LINUX_DIRECTORY=$(pwd)
JSONCPP_TAG=1.7.4
LIBSECRET_TAG=0.21.4
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
cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=release -DBUILD_STATIC_LIBS=ON -DBUILD_SHARED_LIBS=ON -DARCHIVE_INSTALL_DIR=. -G "Unix Makefiles" ..
make -j"$(nproc)"

cd "$LINUX_DIRECTORY" || exit 1
# Build libSecret
# sudo apt install meson libgirepository1.0-dev valac xsltproc gi-docgen docbook-xsl
# sudo apt install python3-pip
#pip3 install --user meson markdown tomli --upgrade
# pip3 install --user gi-docgen
cd build || exit 1
git -C libsecret pull origin $LIBSECRET_TAG || git clone https://git.cypherstack.com/Cypher_Stack/libsecret.git libsecret
cd libsecret || exit 1
git checkout $LIBSECRET_TAG
if ! [ -x "$(command -v meson)" ]; then
  echo 'Error: meson is not installed.' >&2
  exit 1
fi
meson _build -Dvapi=false  -Dmanpage=false -Dgtk_doc=false
if ! [ -x "$(command -v ninja)" ]; then
  echo 'Error: ninja is not installed.' >&2
  exit 1
fi
ninja -C _build

# Publish a local pkg-config file that points at the locally built libsecret.
# This avoids relying on distro-specific libsecret/glib pkg-config metadata.
mkdir -p "$LINUX_DIRECTORY/pc"
cat > "$LINUX_DIRECTORY/pc/libsecret-1.pc" <<EOF
prefix=$LINUX_DIRECTORY/build/libsecret
exec_prefix=\${prefix}
libdir=\${prefix}/_build/libsecret
includedir=\${prefix}

Name: libsecret-1
Description: GObject bindings for Secret Service API
Version: $LIBSECRET_TAG
Libs: -L\${libdir} -lsecret-1
Cflags: -I\${includedir} -I\${includedir}/_build
EOF
