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
const _emptyWalletsMessage =
    "You do not have any wallets yet. Start building your crypto Stack!";
const _appDataDirName = "stackduo";
const _shortDescriptionText = "An open-source, multicoin wallet for everyone";
const _commitHash = "$BUILT_COMMIT_HASH";

const Set<AppFeature> _features = {
  AppFeature.themeSelection,
  AppFeature.buy,
  AppFeature.swap
};

const ({String light, String dark})? _appIconAsset = (
  light: "assets/in_app_logo_icons/stack-duo-icon_light.svg",
  dark: "assets/in_app_logo_icons/stack-duo-icon_dark.svg",
);

final List<CryptoCurrency> _supportedCoins = List.unmodifiable([
  Bitcoin(CryptoCurrencyNetwork.main),
  Monero(CryptoCurrencyNetwork.main),
  BitcoinFrost(CryptoCurrencyNetwork.main),
  Bitcoin(CryptoCurrencyNetwork.test),
  Bitcoin(CryptoCurrencyNetwork.test4),
  BitcoinFrost(CryptoCurrencyNetwork.test),
  BitcoinFrost(CryptoCurrencyNetwork.test4),
]);

final ({String from, String fromFuzzyNet, String to, String toFuzzyNet})
_swapDefaults = (
  from: "BTC",
  fromFuzzyNet: "btc",
  to: "XMR",
  toFuzzyNet: "xmr",
);

EOF