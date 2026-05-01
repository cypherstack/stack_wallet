# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8


SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl file git gnupg python3 sudo unzip xz-utils \
      automake build-essential cmake debhelper libtool meson ninja-build pkg-config rsync \
      clang libclang-dev llvm \
      libgcrypt20-dev libgirepository1.0-dev libgit2-dev libglib2.0-dev libgtk-3-dev \
      libjsoncpp-dev liblzma-dev libncurses5-dev libncursesw5-dev \
      libsecret-1-dev libssl-dev libtss2-dev \
      ocl-icd-opencl-dev opencl-headers valac zlib1g-dev \
      g++-aarch64-linux-gnu gcc-aarch64-linux-gnu \
      g++-mingw-w64-x86-64 gcc-mingw-w64-x86-64 \
      openjdk-17-jdk-headless \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --default-toolchain 1.89.0 --profile minimal --no-modify-path \
 && rustup install 1.85.1 1.71.0 --profile minimal \
 && rustup target add x86_64-unknown-linux-gnu --toolchain 1.89.0 \
 && cargo install cargo-ndk \
 && chmod -R a+rwX "$CARGO_HOME" "$RUSTUP_HOME"

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

ENV ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_NDK_ROOT=/opt/android-sdk/ndk/28.2.13676358 \
    ANDROID_NDK_HOME=/opt/android-sdk/ndk/28.2.13676358 \
    PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:$PATH

RUN mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools" \
 && curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-14742923_latest.zip \
      -o /tmp/cmdline-tools.zip \
 && echo "48833c34b761c10cb20bcd16582129395d121b27  /tmp/cmdline-tools.zip" | sha1sum -c \
 && unzip -q /tmp/cmdline-tools.zip -d "$ANDROID_SDK_ROOT/cmdline-tools" \
 && mv "$ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest" \
 && rm /tmp/cmdline-tools.zip \
 && yes | sdkmanager --licenses \
 && sdkmanager \
      "platform-tools" \
      "build-tools;35.0.0" \
      "platforms;android-35" \
      "ndk;28.2.13676358" \
 && chmod -R a+rwX "$ANDROID_SDK_ROOT"

ENV FLUTTER_HOME=/opt/flutter \
    PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH

RUN git clone --depth 1 --branch 3.38.1 https://github.com/flutter/flutter.git "$FLUTTER_HOME" \
 && git config --global --add safe.directory '*' \
 && flutter config --no-analytics \
 && flutter precache --linux --android \
 && chmod -R a+rwX "$FLUTTER_HOME"

RUN git config --system --add safe.directory '*'

RUN flutter --version && rustc --version && cargo --version && node --version
