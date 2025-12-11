#!/bin/bash

set -x -e


# libepiccash requires old rust
source ../rust_version.sh
set_rust_to_everything_else

wait
echo "Done building"
