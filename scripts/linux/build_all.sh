#!/bin/bash

(cd ../../crypto_plugins/flutter_liblelantus/scripts/linux && ./build_all.sh ) &
(cd ../../crypto_plugins/flutter_libepiccash/scripts/linux && ./build_all.sh )  &
(cd ../../crypto_plugins/flutter_libmonero/scripts/linux && ./build_monero_all.sh && ./build_sharedfile.sh ) &

wait
echo "Done building"
