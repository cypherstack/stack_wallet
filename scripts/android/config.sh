#!/bin/sh

export WORKDIR="$(pwd)/"build
export ANDROID_NDK_ZIP=${WORKDIR}/android-ndk-r20b.zip
export TOOLCHAIN_DIR="${WORKDIR}/toolchain"
# Change this Value to a lower number if you run out of memory while compiling
export OVERRIDE_THREADS="$(nproc)"