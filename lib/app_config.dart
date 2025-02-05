import 'wallets/crypto_currency/crypto_currency.dart';
import 'wallets/crypto_currency/intermediate/frost_currency.dart';

/// This file is part of the app configuration for the StackWallet application.
/// 
/// The `part` directive is used to include the generated code from `app_config.g.dart`.
/// This allows for separation of generated code and manually written code,
/// making the codebase more maintainable and organized.
part 'app_config.g.dart';
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// AppConfigGenerator
// **************************************************************************

// Add generated code here
const _prefix = "StackWallet";
const _separator = "-";
const _suffix = "App";
const _emptyWalletsMessage = "No wallets available.";
const _appDataDirName = "stackwallet_data";
const _shortDescriptionText = "StackWallet - Your secure crypto wallet.";
const _commitHash = "abc123";
const _features = <AppFeature>{
  AppFeature.themeSelection,
  AppFeature.buy,
  AppFeature.swap,
};
const _appIconAsset = (light: "assets/icons/light_icon.png", dark: "assets/icons/dark_icon.png");
const _supportedCoins = <CryptoCurrency>[
  // Add supported cryptocurrencies here
];
const _swapDefaults = (from: "BTC", to: "ETH");
enum AppFeature {
  themeSelection,
  buy,
  swap;
}

abstract class AppConfig {
  static const appName = _prefix + _separator + suffix;

  static const prefix = _prefix;
  static const suffix = _suffix;

  static const emptyWalletsMessage = _emptyWalletsMessage;

  static String get appDefaultDataDirName => _appDataDirName;
  static String get shortDescriptionText => _shortDescriptionText;
  static String get commitHash => _commitHash;

  static bool hasFeature(AppFeature feature) => _features.contains(feature);

  static ({String light, String dark})? get appIconAsset => _appIconAsset;

  static List<CryptoCurrency> get coins => _supportedCoins;

  static ({String from, String to}) get swapDefaults => _swapDefaults;

  static bool get isSingleCoinApp => coins.length == 1;

  static CryptoCurrency? getCryptoCurrencyFor(String coinIdentifier) {
    try {
      return coins.firstWhere((e) => e.identifier == coinIdentifier);
    } catch (_) {
      return null;
    }
  }

  static CryptoCurrency? getCryptoCurrencyForTicker(
    final String ticker, {
    bool caseInsensitive = true,
  }) {
    final _ticker = caseInsensitive ? ticker.toLowerCase() : ticker;
    try {
      return coins.firstWhere(
        caseInsensitive
            ? (e) => e.ticker.toLowerCase() == _ticker && e is! FrostCurrency
            : (e) => e.ticker == _ticker && e is! FrostCurrency,
      );
    } catch (_) {
      return null;
    }
  }

  static bool isStackCoin(String? ticker) {
    if (ticker == null) {
      return false;
    }

    if (getCryptoCurrencyForTicker(ticker, caseInsensitive: false) != null) {
      return true;
    }

    try {
      getCryptoCurrencyByPrettyName(ticker);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fuzzy logic. Use with caution!!
  @Deprecated("dangerous")
  static CryptoCurrency getCryptoCurrencyByPrettyName(final String prettyName) {
    final name = prettyName.replaceAll(" ", "").toLowerCase();
    try {
      return coins.firstWhere(
        (e) => e.identifier.toLowerCase() == name || e.prettyName == prettyName,
      );
    } catch (_) {
      throw Exception("getCryptoCurrencyByPrettyName($prettyName) failed!");
    }
  }
}
