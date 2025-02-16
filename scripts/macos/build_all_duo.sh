#!/bin/bash

set -x -e

# todo: revisit following at some point

# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_1671

(cd ../../crypto_plugins/flutter_liblelantus/scripts/macos && ./build_all.sh )
(cd ../../crypto_plugins/flutter_libepiccash/scripts/macos && ./build_all.sh )
set_rust_to_1720
(cd ../../crypto_plugins/frostdart/scripts/macos && ./build_all.sh )

wait
echo "Done building"

# set rust (back) to a more recent stable release to allow stack wallet to build tor
set_rust_to_1720
