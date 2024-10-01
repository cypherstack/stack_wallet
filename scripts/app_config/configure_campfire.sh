#!/usr/bin/env bash

set -x -e

# Configure files for Duo.
APP_BUILD_PLATFORM=$1

export NEW_NAME="Campfire"
if [[ "$APP_BUILD_PLATFORM" != "ios" ]]; then
  export NEW_APP_ID="com.cypherstack.campfire"
else
  # for some reason this was different in the old campfire code for ios
  export NEW_APP_ID="com.cypherstack.campfirefirowallet"
fi
export NEW_APP_ID_CAMEL="com.cypherstack.campfire"
export NEW_APP_ID_SNAKE="com.cypherstack.campfire"
export NEW_BASIC_NAME="campfire"

NEW_PUBSPEC_NAME="paymint" # paymint used in original pubspec for some reason
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

const _prefix = "Campfire";
const _separator = "";
const _suffix = "";
const _emptyWalletsMessage =
    "Join us around the Campfire and create a wallet!";
const _appDataDirName = "campfire";
const _shortDescriptionText = "Your privacy. Your wallet. Your Firo.";
const _commitHash = "$BUILT_COMMIT_HASH";

const Set<AppFeature> _features = {
  AppFeature.swap
};

const ({String light, String dark})? _appIconAsset = (
  light: "assets/in_app_logo_icons/campfire-icon_light.svg",
  dark: "assets/in_app_logo_icons/campfire-icon_dark.svg",
);

final List<CryptoCurrency> _supportedCoins = List.unmodifiable([
  Firo(CryptoCurrencyNetwork.main),
]);

EOF