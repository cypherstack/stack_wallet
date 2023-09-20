#!/bin/sh

set_rust_to_1680() {
  if rustup toolchain list | grep -q "1.68.0"; then
    rustup default 1.68.0
  else
    echo "Rust version 1.68.0 is not installed. Please install it using 'rustup install 1.68.0'." >&2
    exit 1
  fi
}

set_rust_to_1720() {
  if rustup toolchain list | grep -q "1.72.0"; then
    rustup default 1.72.0
  else
    echo "Rust version 1.72.0 is not installed. Please install it using 'rustup install 1.72.0'." >&2
    exit 1
  fi
}