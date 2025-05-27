#!/bin/bash

set -x -e

# Configure files for Stack Wallet.

export NEW_NAME="Stack Wallet"
export NEW_APP_ID="com.cypherstack.stackwallet"
export NEW_APP_ID_CAMEL="com.cypherstack.stackWallet"
export NEW_APP_ID_SNAKE="com.cypherstack.stack_wallet"
export NEW_BASIC_NAME="stack_wallet"

NEW_PUBSPEC_NAME="stackwallet"
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
const _suffix = "Wallet";
const _emptyWalletsMessage =
    "You do not have any wallets yet. Start building your crypto Stack!";
const _appDataDirName = "stackwallet";
const _shortDescriptionText = "An open-source, multicoin wallet for everyone";
const _commitHash = "$BUILT_COMMIT_HASH";

const Set<AppFeature> _features = {
  AppFeature.themeSelection,
  AppFeature.buy,
  AppFeature.swap
};

const ({String light, String dark})? _appIconAsset = null;

final List<CryptoCurrency> _supportedCoins = List.unmodifiable([
  Bitcoin(CryptoCurrencyNetwork.main),
  Monero(CryptoCurrencyNetwork.main),
  Banano(CryptoCurrencyNetwork.main),
  Bitcoincash(CryptoCurrencyNetwork.main),
  BitcoinFrost(CryptoCurrencyNetwork.main),
  Cardano(CryptoCurrencyNetwork.main),
  Dash(CryptoCurrencyNetwork.main),
  Dogecoin(CryptoCurrencyNetwork.main),
  Ecash(CryptoCurrencyNetwork.main),
  Epiccash(CryptoCurrencyNetwork.main),
  Ethereum(CryptoCurrencyNetwork.main),
  Firo(CryptoCurrencyNetwork.main),
  Litecoin(CryptoCurrencyNetwork.main),
  Nano(CryptoCurrencyNetwork.main),
  Namecoin(CryptoCurrencyNetwork.main),
  Particl(CryptoCurrencyNetwork.main),
  Peercoin(CryptoCurrencyNetwork.main),
  Solana(CryptoCurrencyNetwork.main),
  Stellar(CryptoCurrencyNetwork.main),
  Tezos(CryptoCurrencyNetwork.main),
  Wownero(CryptoCurrencyNetwork.main),
  Xelis(CryptoCurrencyNetwork.main),
  Bitcoin(CryptoCurrencyNetwork.test),
  Bitcoin(CryptoCurrencyNetwork.test4),
  Bitcoincash(CryptoCurrencyNetwork.test),
  BitcoinFrost(CryptoCurrencyNetwork.test),
  BitcoinFrost(CryptoCurrencyNetwork.test4),
  Dogecoin(CryptoCurrencyNetwork.test),
  Firo(CryptoCurrencyNetwork.test),
  Litecoin(CryptoCurrencyNetwork.test),
  Peercoin(CryptoCurrencyNetwork.test),
  Stellar(CryptoCurrencyNetwork.test),
  Xelis(CryptoCurrencyNetwork.test),
]);

final ({String from, String fromFuzzyNet, String to, String toFuzzyNet})
_swapDefaults = (
  from: "BTC",
  fromFuzzyNet: "btc",
  to: "XMR",
  toFuzzyNet: "xmr",
);

EOF