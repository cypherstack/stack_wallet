#!/bin/sh

mkdir -p build
. ./config.sh
ANDROID_NDK_SHA256="8381c440fe61fcbb01e209211ac01b519cd6adf51ab1c2281d5daad6ca4c8c8c"

if [ ! -e "$ANDROID_NDK_ZIP" ]; then
  curl https://dl.google.com/android/repository/android-ndk-r20b-linux-x86_64.zip -o "${ANDROID_NDK_ZIP}"
fi
echo "${ANDROID_NDK_SHA256}" "${ANDROID_NDK_ZIP}" | sha256sum -c || exit 1


PLUGINS_DIR=../../crypto_plugins

mkdir -p "${PLUGINS_DIR}"/flutter_libmonero/scripts/android/build
mkdir -p "${PLUGINS_DIR}"/flutter_liblelantus/scripts/android/build
mkdir -p "${PLUGINS_DIR}"/flutter_libepiccash/scripts/android/build

cp "${ANDROID_NDK_ZIP}" "${PLUGINS_DIR}"/flutter_libmonero/scripts/android/build/
cp "${ANDROID_NDK_ZIP}" "${PLUGINS_DIR}"/flutter_liblelantus/scripts/android/build/
cp "${ANDROID_NDK_ZIP}" "${PLUGINS_DIR}"/flutter_libepiccash/scripts/android/build/
