import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/frost_currency.dart';

part 'app_config.g.dart';

abstract class AppConfig {
  static const appName = _prefix + _separator + suffix;

  static const prefix = _prefix;
  static const suffix = _suffix;

  static List<CryptoCurrency> get coins => _supportedCoins;

  static CryptoCurrency getCryptoCurrencyFor(String coinIdentifier) =>
      coins.firstWhere(
        (e) => e.identifier == coinIdentifier,
      );

  static CryptoCurrency getCryptoCurrencyForTicker(
    final String ticker, {
    bool caseInsensitive = true,
  }) {
    final _ticker = caseInsensitive ? ticker.toLowerCase() : ticker;
    return coins.firstWhere(
      caseInsensitive
          ? (e) => e.ticker.toLowerCase() == _ticker && e is! FrostCurrency
          : (e) => e.ticker == _ticker && e is! FrostCurrency,
    );
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
