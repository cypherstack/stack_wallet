#!/bin/bash

cd ../../crypto_plugins/flutter_libepiccash/scripts/windows && ./deps.sh
cd ../../crypto_plugins/flutter_liblelantus/scripts/windows && ./mxedeps.sh
# cd ../../crypto_plugins/flutter_libmonero/scripts/windows && ./monerodeps.sh && ./mxedeps.sh
sudo apt install libgtk2.0-dev

wait
echo "Done building"
