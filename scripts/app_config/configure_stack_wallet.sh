#!/bin/bash

set -x -e

# Configure files for Stack Wallet.

# currently unused
#export APP_NAME="Stack Wallet"
#export APP_ID="com.cypherstack.stackwallet"

PUBSPEC_FILE="${APP_PROJECT_ROOT_DIR}/pubspec.yaml"
PUBSPEC_NAME="stackwallet"
PUBSPEC_DESC="Stack Wallet"

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
const _suffix = "Wallet";

final List<CryptoCurrency> _supportedCoins = List.unmodifiable([
  Bitcoin(CryptoCurrencyNetwork.main),
  BitcoinFrost(CryptoCurrencyNetwork.main),
  Litecoin(CryptoCurrencyNetwork.main),
  Bitcoincash(CryptoCurrencyNetwork.main),
  Dogecoin(CryptoCurrencyNetwork.main),
  Epiccash(CryptoCurrencyNetwork.main),
  Ecash(CryptoCurrencyNetwork.main),
  Ethereum(CryptoCurrencyNetwork.main),
  Firo(CryptoCurrencyNetwork.main),
  Monero(CryptoCurrencyNetwork.main),
  Particl(CryptoCurrencyNetwork.main),
  Peercoin(CryptoCurrencyNetwork.main),
  Solana(CryptoCurrencyNetwork.main),
  Stellar(CryptoCurrencyNetwork.main),
  Tezos(CryptoCurrencyNetwork.main),
  Wownero(CryptoCurrencyNetwork.main),
  Namecoin(CryptoCurrencyNetwork.main),
  Nano(CryptoCurrencyNetwork.main),
  Banano(CryptoCurrencyNetwork.main),
  Bitcoin(CryptoCurrencyNetwork.test),
  BitcoinFrost(CryptoCurrencyNetwork.test),
  Litecoin(CryptoCurrencyNetwork.test),
  Bitcoincash(CryptoCurrencyNetwork.test),
  Firo(CryptoCurrencyNetwork.test),
  Dogecoin(CryptoCurrencyNetwork.test),
  Stellar(CryptoCurrencyNetwork.test),
  Peercoin(CryptoCurrencyNetwork.test),
]);

EOF