#!/bin/sh

. ./config.sh
echo ''$(git log -1 --pretty=format:"%H")' '$(date) >> build/git_commit_version.txt
VERSIONS_FILE=../../lib/git_versions.dart
EXAMPLE_VERSIONS_FILE=../../lib/git_versions_example.dart
if [ ! -f "$VERSIONS_FILE" ]; then
    cp $EXAMPLE_VERSIONS_FILE $VERSIONS_FILE
fi
COMMIT=$(git log -1 --pretty=format:"%H")
OS="LINUX"
sed -i "/\/\*${OS}_VERSION/c\\/\*${OS}_VERSION\*\/ const ${OS}_VERSION = \"$COMMIT\";" $VERSIONS_FILE
cd build
mkdir monero_build
MONERO_BUILD=$(pwd)/monero_build

cd $MONERO_BUILD
cmake ../../crypto_plugins/flutter_libmonero/scripts/linux/cmakefiles/monero/${TYPES_OF_BUILD}
make -j$(nproc)
cp libcw_monero.so ../


