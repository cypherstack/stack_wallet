#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/env.sh"

APP_CONFIG_DART_FILE="${APP_PROJECT_ROOT_DIR}/lib/app_config.g.dart"

if test -f "$APP_CONFIG_DART_FILE"; then
    echo 'ensure_test_app_config.sh: verified lib/app_config.g.dart'
    exit 0
fi

BUILT_COMMIT_HASH="$(git -C "${APP_PROJECT_ROOT_DIR}" log -1 --pretty=format:%H 2>/dev/null || true)"

cat > "$APP_CONFIG_DART_FILE" <<EOF
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

const _mwebdExeHash = "";

const Set<AppFeature> _features = {
  AppFeature.themeSelection,
  AppFeature.buy,
  AppFeature.tor,
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
  Fact0rn(CryptoCurrencyNetwork.main),
  Firo(CryptoCurrencyNetwork.main),
  Litecoin(CryptoCurrencyNetwork.main),
  if (!Platform.isMacOS) Mimblewimblecoin(CryptoCurrencyNetwork.main),
  Nano(CryptoCurrencyNetwork.main),
  Namecoin(CryptoCurrencyNetwork.main),
  Particl(CryptoCurrencyNetwork.main),
  Peercoin(CryptoCurrencyNetwork.main),
  Salvium(CryptoCurrencyNetwork.main),
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
  Salvium(CryptoCurrencyNetwork.test),
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

echo 'ensure_test_app_config.sh: created lib/app_config.g.dart'
