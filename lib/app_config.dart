import 'wallets/crypto_currency/crypto_currency.dart';
import 'wallets/crypto_currency/intermediate/frost_currency.dart';

part 'app_config.g.dart';

enum AppFeature { themeSelection, buy, swap }

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
