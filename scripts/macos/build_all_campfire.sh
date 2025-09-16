#!/bin/bash

set -x -e


# libepiccash requires old rust
source ../rust_version.sh
set_rust_version_for_libepiccash
(cd ../../crypto_plugins/flutter_libepiccash/scripts/macos && ./build_all.sh )
(cd ../../crypto_plugins/flutter_libmwc/scripts/macos && ./build_all.sh )
# set rust (back) to a more recent stable release after building epiccash
set_rust_to_everything_else

(cd ../../crypto_plugins/frostdart/scripts/macos && ./build_all.sh )

wait
echo "Done building"
