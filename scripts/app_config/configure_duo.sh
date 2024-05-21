#!/bin/bash

set -e

# Configure files for Duo.
export ORIGINAL_NAME="Stack Wallet"
export ORIGINAL_APP_ID="com.cypherstack.stackwallet"

export NEW_NAME="Stack Duo"
export NEW_APP_ID="com.cypherstack.stackduo"

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
