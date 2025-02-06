#!/bin/sh

set_rust_to_1671() {
  if rustup toolchain list | grep -q "1.67.1"; then
    rustup default 1.67.1
  else
    echo "Rust version 1.67.1 is not installed. Please install it using 'rustup install 1.67.1'." >&2
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

set_rust_to_1840() {
  if rustup toolchain list | grep -q "1.84.0"; then
    rustup default 1.84.0
  else
    echo "Rust version 1.84.0 is not installed. Please install it using 'rustup install 1.84.0'." >&2
    exit 1
  fi
}