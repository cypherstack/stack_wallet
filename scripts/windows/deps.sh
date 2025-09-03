#!/bin/bash

cd ../../crypto_plugins/flutter_libepiccash/scripts/windows && ./deps.sh
(cd ../../crypto_plugins/flutter_libmwc/scripts/windows && ./deps.sh)
sudo apt install libgtk2.0-dev

wait
echo "Done building"
