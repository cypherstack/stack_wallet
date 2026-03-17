#!/bin/bash

set -x -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

# libepiccash requires old rust
source "${SCRIPT_DIR}/../rust_version.sh"
set_rust_version_for_libepiccash
(cd "${ROOT_DIR}/crypto_plugins/flutter_libepiccash/scripts/macos" && ./build_all.sh )
set_rust_version_for_libmwc
(cd "${ROOT_DIR}/crypto_plugins/flutter_libmwc/scripts/macos" && ./build_all.sh )
# set rust (back) to a more recent stable release after building epiccash
set_rust_to_everything_else

(cd "${ROOT_DIR}/crypto_plugins/frostdart/scripts/macos" && ./build_all.sh )

wait
echo "Done building"
