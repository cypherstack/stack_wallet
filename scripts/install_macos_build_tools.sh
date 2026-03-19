#!/usr/bin/env bash

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer is for macOS only."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install it first: https://brew.sh"
  exit 1
fi

echo "Installing Homebrew packages..."
brew install direnv rustup-init cmake meson ninja pkg-config gnu-sed cocoapods go protobuf autoconf automake libtool

echo "Installing Flutter cask..."
brew install --cask flutter

if ! command -v rustup >/dev/null 2>&1; then
  echo "Initializing Rust toolchain..."
  rustup-init -y
fi

if [[ -f "$HOME/.cargo/env" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.cargo/env"
fi

echo "Ensuring Rust toolchains are installed..."
rustup toolchain install stable
rustup default stable
rustup toolchain install 1.85.1
rustup default stable
rustup target add aarch64-apple-darwin x86_64-apple-darwin aarch64-apple-ios --toolchain stable >/dev/null 2>&1 || true
rustup target add aarch64-apple-darwin x86_64-apple-darwin --toolchain 1.85.1 >/dev/null 2>&1 || true

echo "Installing Rust CLI build tools..."
cargo install cargo-lipo cbindgen || true

echo "Verifying toolchain..."
if command -v flutter >/dev/null 2>&1; then
  flutter --version
else
  echo "flutter not found in PATH. Add Flutter bin to your shell profile."
fi

if command -v dart >/dev/null 2>&1; then
  dart --version
else
  echo "dart not found in PATH. It should come with Flutter."
fi

rustup --version
rustc --version
rustup run stable rustc --version
pod --version
go version
autoreconf --version | head -n 1 || true
aclocal --version | head -n 1 || true

echo "Done."
