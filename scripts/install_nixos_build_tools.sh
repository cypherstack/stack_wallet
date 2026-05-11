#!/usr/bin/env bash

set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This installer is for Linux/NixOS only."
  exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
  echo "Nix is required. Install it first: https://nixos.org/download/"
  exit 1
fi

if ! command -v rustup >/dev/null 2>&1; then
  echo "rustup is required. Install it first (for toolchain pinning): https://rustup.rs"
  exit 1
fi

echo "Installing Nix profile packages..."
nix --extra-experimental-features "nix-command flakes" profile add \
  nixpkgs#direnv \
  nixpkgs#flutter \
  nixpkgs#go \
  nixpkgs#cmake \
  nixpkgs#ninja \
  nixpkgs#pkg-config \
  nixpkgs#gnumake \
  nixpkgs#gnused \
  nixpkgs#protobuf \
  nixpkgs#autoconf \
  nixpkgs#automake \
  nixpkgs#libtool \
  nixpkgs#clang || true

echo "Ensuring Rust toolchains are installed..."
# Two toolchains are required:
#   - stable: used for frostdart, coinlib, secp256k1, and everything else
#   - 1.85.1: pinned for flutter_libepiccash / flutter_libmwc (older Rust dialect)
# See scripts/rust_version.sh and flake.nix.
rustup toolchain install --no-self-update stable 1.85.1
rustup default stable
rustup target add aarch64-unknown-linux-gnu x86_64-unknown-linux-gnu --toolchain stable >/dev/null 2>&1 || true
rustup target add aarch64-unknown-linux-gnu x86_64-unknown-linux-gnu --toolchain 1.85.1 >/dev/null 2>&1 || true

echo "Installing Rust CLI build tools..."
cargo install cargo-ndk cbindgen cargo-lipo || true

echo "Verifying toolchain..."
if command -v flutter >/dev/null 2>&1; then
  flutter --version
else
  echo "flutter not found in PATH."
fi

if command -v dart >/dev/null 2>&1; then
  dart --version
else
  echo "dart not found in PATH. It should come with Flutter."
fi

rustup --version
rustc --version
rustup run stable rustc --version
go version
protoc --version || true
cmake --version | head -n 1 || true
pkg-config --version || true
autoreconf --version | head -n 1 || true
aclocal --version | head -n 1 || true

echo "Done."
