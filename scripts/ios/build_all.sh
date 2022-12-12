#!/bin/bash

(cd ../../crypto_plugins/flutter_libepiccash/scripts/ios && ./build_all.sh )  &

wait
echo "Done building"