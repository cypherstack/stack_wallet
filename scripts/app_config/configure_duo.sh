#!/bin/bash

set -e

# Configure files for Duo.
export ORIGINAL_NAME="Stack Wallet"
export ORIGINAL_APP_ID="com.cypherstack.stackwallet"

export NEW_NAME="Stack Duo"
export NEW_APP_ID="com.cypherstack.stackduo"
export NEW_VERSION="2.0.0"
export NEW_BUILD="" # Will increment existing build # if empty.

# String replacements.
if [[ "$(uname)" == 'Darwin' ]]; then
  # macos specific sed
  sed -i '' 's/Wallet/Duo/g' ../../lib/app_config.dart
  sed -i '' "s/${ORIGINAL_NAME}/${NEW_NAME}/g" ../../pubspec.yaml
else
  sed -i 's/Wallet/Duo/g' ../../lib/app_config.dart
  sed -i "s/${ORIGINAL_NAME}/${NEW_NAME}/g" ../../pubspec.yaml
fi

# Extract Duo images.
unzip -o stack_duo_assets.zip -d ../../

# Update version & build number.
./update_version.sh -v "${NEW_VERSION}" -b "${NEW_BUILD}"
