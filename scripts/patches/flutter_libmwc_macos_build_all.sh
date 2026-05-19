#!/usr/bin/env bash
set -e
rm -rf build
mkdir build
echo ''$(git log -1 --pretty=format:"%H")' '$(date) >> build/git_commit_version.txt
VERSIONS_FILE=../../lib/git_versions.dart
EXAMPLE_VERSIONS_FILE=../../lib/git_versions_example.dart
if [ ! -f "$VERSIONS_FILE" ]; then
    cp $EXAMPLE_VERSIONS_FILE $VERSIONS_FILE
fi
COMMIT=$(git log -1 --pretty=format:"%H")
OSX="OSX"
tmp_file="${VERSIONS_FILE}.tmp"
awk -v os="$OSX" -v commit="$COMMIT" '
  index($0, "/*" os "_VERSION*/") { print "/*" os "_VERSION*/ const " os "_VERSION = \"" commit "\";"; next }
  { print }
' "$VERSIONS_FILE" > "$tmp_file"
mv "$tmp_file" "$VERSIONS_FILE"
cp -r ../../rust build/rust
cd build/rust

# some people need this apparently
# export PROTOC=/opt/homebrew/bin/protoc
unset MAKEFLAGS MFLAGS CARGO_MAKEFLAGS MAKELEVEL MAKE_TERMOUT MAKE_TERMERR
export MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-11.0}"

# building
cbindgen src/lib.rs -l c > libmwc_wallet.h
env -u MAKEFLAGS -u MFLAGS -u CARGO_MAKEFLAGS -u MAKELEVEL -u MAKE_TERMOUT -u MAKE_TERMERR \
  cargo build --release --target aarch64-apple-darwin --lib

xcodebuild -create-xcframework \
  -library target/aarch64-apple-darwin/release/libmwc_wallet.a \
  -headers libmwc_wallet.h \
  -output ../MWCWallet.xcframework

# moving files to the macos project
fwk=../../../../macos/framework/
rm -rf ${fwk}
mkdir ${fwk}
mv ../MWCWallet.xcframework ${fwk}
