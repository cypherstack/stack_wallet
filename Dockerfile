# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04 AS full

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
      libopencv-dev \
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
 && rustup install 1.85.1 1.71.0 stable --profile minimal \
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
 && mkdir -p "$ANDROID_SDK_ROOT/licenses" \
 && printf '\n24333f8a63b6825ea9c5514f83c2829b004d1fee\n8933bad161af4178b1185d1a37fbf41ea5269c55d7b9237478ea8ec3307c27e4' \
      > "$ANDROID_SDK_ROOT/licenses/android-sdk-license" \
 && printf '\n84831b9409646a918e30573bab4c9c91346d8abd' \
      > "$ANDROID_SDK_ROOT/licenses/android-sdk-preview-license" \
 && printf '\n859f317696f67ef3d7f30a50a5560e7834b43903' \
      > "$ANDROID_SDK_ROOT/licenses/android-sdk-arm-dbt-license" \
 && sdkmanager \
      "platform-tools" \
      "build-tools;35.0.0" \
      "platforms;android-35" \
      "ndk;28.2.13676358" \
 && chmod -R a+rwX "$ANDROID_SDK_ROOT"

ENV PATH=/usr/local/go/bin:$PATH

RUN curl -fsSL https://go.dev/dl/go1.24.13.linux-amd64.tar.gz -o /tmp/go.tar.gz \
 && echo "1fc94b57134d51669c72173ad5d49fd62afb0f1db9bf3f798fd98ee423f8d730  /tmp/go.tar.gz" | sha256sum -c \
 && tar -C /usr/local -xzf /tmp/go.tar.gz \
 && rm /tmp/go.tar.gz

ENV FLUTTER_HOME=/opt/flutter \
    PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH

RUN git clone --depth 1 --branch 3.38.1 https://github.com/flutter/flutter.git "$FLUTTER_HOME" \
 && git config --global --add safe.directory '*' \
 && flutter config --no-analytics \
 && flutter precache --linux --android \
 && chmod -R a+rwX "$FLUTTER_HOME"

RUN git config --system --add safe.directory '*'

RUN flutter --version && rustc --version && cargo --version && node --version && go version


# Minimal image for flutter test (no Rust, no Android SDK, no cross-compilers)
FROM ubuntu:24.04 AS test

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl file git unzip xz-utils \
      build-essential cmake ninja-build pkg-config \
      clang libclang-dev \
      libgirepository1.0-dev libglib2.0-dev libgtk-3-dev \
      libjsoncpp-dev liblzma-dev libsecret-1-dev libssl-dev \
 && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_HOME=/opt/flutter \
    PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH

RUN git clone --depth 1 --branch 3.38.1 https://github.com/flutter/flutter.git "$FLUTTER_HOME" \
 && git config --global --add safe.directory '*' \
 && flutter config --no-analytics \
 && flutter precache --linux \
 && chmod -R a+rwX "$FLUTTER_HOME"

RUN git config --system --add safe.directory '*'

RUN flutter --version
