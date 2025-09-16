#!/bin/sh


set_rust_to_everything_else() {
  if rustup toolchain list | grep -q "1.85.1"; then
    rustup default 1.85.1
  else
    echo "Rust version 1.85.1 is not installed. Please install it using 'rustup install 1.85.1'." >&2
    exit 1
  fi
}

set_rust_version_for_libepiccash() {
  if rustup toolchain list | grep -q "1.81.0"; then
    rustup default 1.81
  else
    echo "Rust version 1.81.0 is not installed. Please install it using 'rustup install 1.81.0'." >&2
    exit 1
  fi
}
