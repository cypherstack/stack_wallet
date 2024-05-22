#!/bin/bash

set -x -e

# Configure files for Duo.

export ORIGINAL_NAME="Stack Wallet"
export ORIGINAL_APP_ID="com.cypherstack.stackwallet"

export NEW_NAME="Stack Duo"
export NEW_APP_ID="com.cypherstack.stackduo"

PUBSPEC_FILE="${APP_PROJECT_ROOT_DIR}/pubspec.yaml"
PUBSPEC_NAME="stackduo"
PUBSPEC_DESC="Stack Duo"

# String replacements.
if [[ "$(uname)" == 'Darwin' ]]; then
  # macos specific sed
  sed -i '' "s/name: PLACEHOLDER/name: ${PUBSPEC_NAME}/g" "${PUBSPEC_FILE}"
  sed -i '' "s/description: PLACEHOLDER/description: ${PUBSPEC_DESC}/g" "${PUBSPEC_FILE}"
else
  sed -i "s/name: PLACEHOLDER/name: ${PUBSPEC_NAME}/g" "${PUBSPEC_FILE}"
  sed -i "s/description: PLACEHOLDER/description: ${PUBSPEC_DESC}/g" "${PUBSPEC_FILE}"
fi

APP_CONFIG_DART_FILE="${APP_PROJECT_ROOT_DIR}/lib/app_config.g.dart"
rm -f "$APP_CONFIG_DART_FILE"
cat << EOF > "$APP_CONFIG_DART_FILE"
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

const _prefix = "Stack";
const _separator = " ";
const _suffix = "Duo";

final List<CryptoCurrency> _supportedCoins = List.unmodifiable([
  Bitcoin(CryptoCurrencyNetwork.main),
  Monero(CryptoCurrencyNetwork.main),
  Bitcoin(CryptoCurrencyNetwork.test),
]);

EOF