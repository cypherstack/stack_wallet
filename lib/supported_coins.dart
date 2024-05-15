import 'package:stackwallet/wallets/crypto_currency/coins/banano.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoin.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoin_frost.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/bitcoincash.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/dogecoin.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/ecash.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/epiccash.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/ethereum.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/firo.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/litecoin.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/monero.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/namecoin.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/nano.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/particl.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/peercoin.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/solana.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/stellar.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/tezos.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/wownero.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/frost_currency.dart';

/// The supported coins. Eventually move away from the Coin enum
class SupportedCoins {
  /// A List of our supported coins.
  static final List<CryptoCurrency> cryptocurrencies = [
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
      cryptocurrencies.firstWhere(
        (e) => e.identifier == coinIdentifier,
      );

  static CryptoCurrency getCryptoCurrencyForTicker(
    final String ticker, {
    bool caseInsensitive = true,
  }) {
    final _ticker = caseInsensitive ? ticker.toLowerCase() : ticker;
    return cryptocurrencies.firstWhere(
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
      return cryptocurrencies.firstWhere(
        (e) => e.identifier.toLowerCase() == name || e.prettyName == prettyName,
      );
    } catch (_) {
      throw Exception("getCryptoCurrencyByPrettyName($prettyName) failed!");
    }
  }
}
