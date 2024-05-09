import 'package:stackwallet/utilities/enums/coin_enum.dart';
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
import 'package:stackwallet/wallets/crypto_currency/coins/solana.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/stellar.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/tezos.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/wownero.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

/// The supported coins. Eventually move away from the Coin enum
class SupportedCoins {
  /// A List of our supported coins. Piggy back on [Coin] for now
  static final List<CryptoCurrency> cryptocurrencies =
      Coin.values.map((e) => getCryptoCurrencyFor(e)).toList(growable: false);

  /// A getter function linking a [CryptoCurrency] with its associated [Coin].
  ///
  /// Temporary: Remove when the Coin enum is removed.
  static CryptoCurrency getCryptoCurrencyFor(Coin coin) {
    switch (coin) {
      case Coin.bitcoin:
        return Bitcoin(CryptoCurrencyNetwork.main);
      case Coin.bitcoinFrost:
        return BitcoinFrost(CryptoCurrencyNetwork.main);
      case Coin.litecoin:
        return Litecoin(CryptoCurrencyNetwork.main);
      case Coin.bitcoincash:
        return Bitcoincash(CryptoCurrencyNetwork.main);
      case Coin.dogecoin:
        return Dogecoin(CryptoCurrencyNetwork.main);
      case Coin.epicCash:
        return Epiccash(CryptoCurrencyNetwork.main);
      case Coin.eCash:
        return Ecash(CryptoCurrencyNetwork.main);
      case Coin.ethereum:
        return Ethereum(CryptoCurrencyNetwork.main);
      case Coin.firo:
        return Firo(CryptoCurrencyNetwork.main);
      case Coin.monero:
        return Monero(CryptoCurrencyNetwork.main);
      case Coin.particl:
        return Particl(CryptoCurrencyNetwork.main);
      case Coin.solana:
        return Solana(CryptoCurrencyNetwork.main);
      case Coin.stellar:
        return Stellar(CryptoCurrencyNetwork.main);
      case Coin.tezos:
        return Tezos(CryptoCurrencyNetwork.main);
      case Coin.wownero:
        return Wownero(CryptoCurrencyNetwork.main);
      case Coin.namecoin:
        return Namecoin(CryptoCurrencyNetwork.main);
      case Coin.nano:
        return Nano(CryptoCurrencyNetwork.main);
      case Coin.banano:
        return Banano(CryptoCurrencyNetwork.main);
      case Coin.bitcoinTestNet:
        return Bitcoin(CryptoCurrencyNetwork.test);
      case Coin.bitcoinFrostTestNet:
        return BitcoinFrost(CryptoCurrencyNetwork.test);
      case Coin.litecoinTestNet:
        return Litecoin(CryptoCurrencyNetwork.test);
      case Coin.bitcoincashTestnet:
        return Bitcoincash(CryptoCurrencyNetwork.test);
      case Coin.firoTestNet:
        return Firo(CryptoCurrencyNetwork.test);
      case Coin.dogecoinTestNet:
        return Dogecoin(CryptoCurrencyNetwork.test);
      case Coin.stellarTestnet:
        return Stellar(CryptoCurrencyNetwork.test);
    }
  }
}
