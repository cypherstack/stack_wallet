#!/bin/bash

(cd ../../crypto_plugins/flutter_liblelantus/scripts/ios && ./build_all.sh ) &
(cd ../../crypto_plugins/flutter_libepiccash/scripts/ios && ./build_all.sh )  &
(cd ../../crypto_plugins/flutter_libmonero/scripts/ios/ && ./build_all.sh  ) &

wait
echo "Done building"