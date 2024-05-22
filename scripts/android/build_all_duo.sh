#!/bin/bash

set -x -e

sed -i "s/${ORIGINAL_APP_ID}/${NEW_APP_ID}/g" ../../android/app/build.gradle
sed -i "s/${ORIGINAL_APP_ID}/${NEW_APP_ID}/g" ../../android/app/src/debug/AndroidManifest.xml
sed -i "s/${ORIGINAL_APP_ID}/${NEW_APP_ID}/g" ../../android/app/src/main/AndroidManifest.xml
sed -i "s/${ORIGINAL_APP_ID}/${NEW_APP_ID}/g" ../../android/app/src/main/kotlin/com/cypherstack/stackwallet/MainActivity.kt
sed -i "s/${ORIGINAL_APP_ID}/${NEW_APP_ID}/g" ../../android/app/src/main/profile/AndroidManifest.xml
sed -i "s/${ORIGINAL_APP_ID}/${NEW_APP_ID}/g" ../../android/app/src/profile/AndroidManifest.xml

# todo: revisit following at some point

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_1671

mkdir -p build
. ./config.sh
./install_ndk.sh

PLUGINS_DIR=../../crypto_plugins

(cd "${PLUGINS_DIR}"/flutter_liblelantus/scripts/android && ./build_all.sh ) &
(cd "${PLUGINS_DIR}"/flutter_libepiccash/scripts/android && ./build_all.sh )  &
(cd "${PLUGINS_DIR}"/flutter_libmonero/scripts/android/ && ./build_all.sh  ) &&
set_rust_to_1720 &&
(cd "${PLUGINS_DIR}"/frostdart/scripts/android && ./build_all.sh ) &

wait
echo "Done building"
