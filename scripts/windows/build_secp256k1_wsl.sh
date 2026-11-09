#!/usr/bin/env bash
set -e
# Compatibility entry point; shares the native Windows source revision and recipe.
exec dart "$(dirname -- "${BASH_SOURCE[0]}")/build_secp256k1.dart" "$@"
