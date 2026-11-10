#!/usr/bin/env bash
set -e
# Compatibility entry point; shares the native Windows source revision and recipe.
# WSL often inherits Windows Flutter on PATH. Refuse that SDK before handing it
# a Linux path or accidentally selecting the native Windows compiler.
if ! dart_version=$(dart --version 2>&1); then
    echo "Could not run Dart. Install a Linux Dart/Flutter SDK inside WSL and put its bin directory on PATH." >&2
    exit 1
fi
case "$dart_version" in
    *'on "linux_'*) ;;
    *) echo "This WSL build needs Linux Dart, but PATH selects: $dart_version" >&2
       echo "Put your Linux SDK's bin directory before Windows Flutter on WSL's PATH." >&2
       exit 1 ;;
esac
exec dart "$(dirname -- "${BASH_SOURCE[0]}")/build_secp256k1.dart" "$@"
