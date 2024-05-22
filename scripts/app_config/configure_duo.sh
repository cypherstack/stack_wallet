#!/bin/bash

set -x -e

# Configure files for Duo.
ORIGINAL_PUBSPEC_NAME="stackwallet"
NEW_PUBSPEC_NAME="stackduo"

export ORIGINAL_NAME="Stack Wallet"
export ORIGINAL_APP_ID="com.cypherstack.stackwallet"

export NEW_NAME="Stack Duo"
export NEW_APP_ID="com.cypherstack.stackduo"

# String replacements.
if [[ "$(uname)" == 'Darwin' ]]; then
  # macos specific sed
  sed -i '' 's/Wallet/Duo/g' ../../lib/app_config.dart
  sed -i '' "s/${ORIGINAL_NAME}/${NEW_NAME}/g" ../../pubspec.yaml
  sed -i '' "s/${ORIGINAL_PUBSPEC_NAME}/${NEW_PUBSPEC_NAME}/g" ../../pubspec.yaml
else
  sed -i 's/Wallet/Duo/g' ../../lib/app_config.dart
  sed -i "s/${ORIGINAL_NAME}/${NEW_NAME}/g" ../../pubspec.yaml
  sed -i "s/${ORIGINAL_PUBSPEC_NAME}/${NEW_PUBSPEC_NAME}/g" ../../pubspec.yaml
fi
