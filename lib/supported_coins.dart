import 'package:stackwallet/app_config.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/frost_currency.dart';

/// The supported coins. Eventually move away from the Coin enum
class Coins {
  /// A List of enabled coins.
  static List<CryptoCurrency> get enabled => all
      .where(
          (element) => AppConfig.supportedCoins.contains(element.runtimeType))
      .toList();

  /// A List of all implemented coins.
  static final List<CryptoCurrency> all = [
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
  ];

  static CryptoCurrency getCryptoCurrencyFor(String coinIdentifier) =>
      all.firstWhere(
        (e) => e.identifier == coinIdentifier,
      );

  static CryptoCurrency getCryptoCurrencyForTicker(
    final String ticker, {
    bool caseInsensitive = true,
  }) {
    final _ticker = caseInsensitive ? ticker.toLowerCase() : ticker;
    return all.firstWhere(
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
      return all.firstWhere(
        (e) => e.identifier.toLowerCase() == name || e.prettyName == prettyName,
      );
    } catch (_) {
      throw Exception("getCryptoCurrencyByPrettyName($prettyName) failed!");
    }
  }
}
