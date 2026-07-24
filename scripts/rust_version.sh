#!/usr/bin/env bash

set_rust_to_everything_else() {
  if rustup toolchain list | grep -q "stable"; then
    rustup default stable
  else
    echo "Rust stable toolchain is not installed. Please install it using 'rustup toolchain install stable'." >&2
    echo "Bypassed by Nix"
  fi
}

set_rust_version_for_libepiccash() {
  if rustup toolchain list | grep -q "1.85.1"; then
    rustup default 1.85.1
  else
    echo "Rust version 1.85.1 is not installed. Please install it using 'rustup install 1.85.1'." >&2
    echo "Bypassed by Nix"
  fi
}

set_rust_version_for_libmwc() {
  if rustup toolchain list | grep -q "1.85.1"; then
    rustup default 1.85.1
  else
    echo "Rust version 1.85.1 is not installed. Please install it using 'rustup install 1.85.1'." >&2
    echo "Bypassed by Nix"
  fi
}
