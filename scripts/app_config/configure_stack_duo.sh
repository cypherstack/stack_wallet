#!/bin/bash

set -x -e

# Configure files for Duo.

export NEW_NAME="Stack Duo"
export NEW_APP_ID="com.cypherstack.stackduo"
export NEW_APP_ID_CAMEL="com.cypherstack.stackDuo"
export NEW_APP_ID_SNAKE="com.cypherstack.stack_duo"
export NEW_BASIC_NAME="stack_duo"

NEW_PUBSPEC_NAME="stackduo"
PUBSPEC_FILE="${APP_PROJECT_ROOT_DIR}/pubspec.yaml"

# String replacements.
if [[ "$(uname)" == 'Darwin' ]]; then
  # macos specific sed
  sed -i '' "s/name: PLACEHOLDER/name: ${NEW_PUBSPEC_NAME}/g" "${PUBSPEC_FILE}"
  sed -i '' "s/description: PLACEHOLDER/description: ${NEW_NAME}/g" "${PUBSPEC_FILE}"
else
  sed -i "s/name: PLACEHOLDER/name: ${NEW_PUBSPEC_NAME}/g" "${PUBSPEC_FILE}"
  sed -i "s/description: PLACEHOLDER/description: ${NEW_NAME}/g" "${PUBSPEC_FILE}"
fi

pushd "${APP_PROJECT_ROOT_DIR}"
BUILT_COMMIT_HASH=$(git log -1 --pretty=format:"%H")
popd

APP_CONFIG_DART_FILE="${APP_PROJECT_ROOT_DIR}/lib/app_config.g.dart"
rm -f "$APP_CONFIG_DART_FILE"
cat << EOF > "$APP_CONFIG_DART_FILE"
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

const _prefix = "Stack";
const _separator = " ";
const _suffix = "Duo";
const _appDataDirName = "stackduo";
const _commitHash = "$BUILT_COMMIT_HASH";

const ({String light, String dark})? _appIconAsset = (
  light: "assets/in_app_logo_icons/stack-duo-icon_light.svg",
  dark: "assets/in_app_logo_icons/stack-duo-icon_dark.svg",
);

final List<CryptoCurrency> _supportedCoins = List.unmodifiable([
  Bitcoin(CryptoCurrencyNetwork.main),
  Monero(CryptoCurrencyNetwork.main),
  BitcoinFrost(CryptoCurrencyNetwork.main),
  Bitcoin(CryptoCurrencyNetwork.test),
  BitcoinFrost(CryptoCurrencyNetwork.test),
]);

EOF