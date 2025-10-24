#!/bin/bash

set -x -e

# todo: revisit following at some point


# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_everything_else

(cd ../../crypto_plugins/frostdart/scripts/macos && ./build_all.sh )

wait
echo "Done building"

