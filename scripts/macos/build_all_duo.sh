#!/bin/bash

set -x -e

# todo: revisit following at some point

(cd ../../crypto_plugins/flutter_liblelantus/scripts/macos && ./build_all.sh )
(cd ../../crypto_plugins/flutter_libepiccash/scripts/macos && ./build_all.sh )
(cd ../../crypto_plugins/frostdart/scripts/macos && ./build_all.sh )

wait
echo "Done building"

