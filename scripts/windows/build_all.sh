#!/bin/bash

mkdir -p build
(cd ../../crypto_plugins/flutter_libepiccash/scripts/windows && ./build_all.sh )  &
(cd ../../crypto_plugins/flutter_liblelantus/scripts/windows && ./build_all.sh ) &
# (cd ../../crypto_plugins/flutter_libmonero/scripts/windows && ./build_all.sh) &

wait
echo "Done building"
