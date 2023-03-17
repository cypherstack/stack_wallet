#!/bin/bash

(cd ../../crypto_plugins/flutter_libmonero/scripts/ios/ && ./install_missing_headers.sh && ./build_monero_all.sh && ./setup.sh  ) &

wait
echo "Done building"