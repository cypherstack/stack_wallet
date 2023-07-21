#!/bin/bash

(cd ../../crypto_plugins/flutter_liblelantus/scripts/macos && ./build_all.sh ) &
(cd ../../crypto_plugins/flutter_libepiccash/scripts/macos && ./build_all.sh )  &
(cd ../../crypto_plugins/flutter_libmonero/scripts/macos/ && ./build_all.sh  ) &

wait
echo "Done building"