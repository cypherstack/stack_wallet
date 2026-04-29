# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git gnupg sudo xz-utils file python3 unzip \
      build-essential automake cmake meson ninja-build pkg-config libtool \
      libglib2.0-dev libgtk-3-dev liblzma-dev \
      libgcrypt20-dev libgirepository1.0-dev \
      libgit2-dev clang rsync \
      libncurses5-dev libncursesw5-dev zlib1g-dev llvm debhelper \
      libclang-dev opencl-headers libssl-dev ocl-icd-opencl-dev \
      valac libtss2-dev libsecret-1-dev libjsoncpp-dev \
 && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --default-toolchain 1.89.0 --profile minimal --no-modify-path \
 && rustup install 1.85.1 --profile minimal \
 && rustup target add x86_64-unknown-linux-gnu --toolchain 1.89.0 \
 && cargo install cargo-ndk \
 && chmod -R a+rwX "$CARGO_HOME" "$RUSTUP_HOME"

ENV FLUTTER_HOME=/opt/flutter \
    PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH

RUN git clone --depth 1 --branch 3.38.1 https://github.com/flutter/flutter.git "$FLUTTER_HOME" \
 && git config --global --add safe.directory '*' \
 && flutter config --no-analytics \
 && flutter precache --linux \
 && chmod -R a+rwX "$FLUTTER_HOME"

RUN git config --system --add safe.directory '*'

RUN flutter --version && rustc --version && cargo --version && node --version
