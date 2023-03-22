#!/bin/bash

(cd ../../crypto_plugins/flutter_libmonero/scripts/ios/ && ./build_all.sh  ) &

wait
echo "Done building"