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
import 'package:stackwallet/wallets/crypto_currency/coins/stellar.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/tezos.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/wownero.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

/// The supported coins.
class SupportedCoins {
  /// A List of our supported coins.
  static final List<CryptoCurrency> cryptocurrencies = [
    // Mainnet coins.
    Bitcoin(CryptoCurrencyNetwork.main),
    Monero(CryptoCurrencyNetwork.main),
    Banano(CryptoCurrencyNetwork.main),
    Bitcoincash(CryptoCurrencyNetwork.main),
    BitcoinFrost(CryptoCurrencyNetwork.main),
    Dogecoin(CryptoCurrencyNetwork.main),
    Ecash(CryptoCurrencyNetwork.main),
    Epiccash(CryptoCurrencyNetwork.main),
    Ethereum(CryptoCurrencyNetwork.main),
    Firo(CryptoCurrencyNetwork.main),
    Litecoin(CryptoCurrencyNetwork.main),
    Namecoin(CryptoCurrencyNetwork.main),
    Nano(CryptoCurrencyNetwork.main),
    Particl(CryptoCurrencyNetwork.main),
    Stellar(CryptoCurrencyNetwork.main),
    Tezos(CryptoCurrencyNetwork.main),
    Wownero(CryptoCurrencyNetwork.main),

    /// Testnet coins.
    Bitcoin(CryptoCurrencyNetwork.test),
    Banano(CryptoCurrencyNetwork.test),
    Bitcoincash(CryptoCurrencyNetwork.test),
    BitcoinFrost(CryptoCurrencyNetwork.test),
    Dogecoin(CryptoCurrencyNetwork.test),
    Stellar(CryptoCurrencyNetwork.test),
    Firo(CryptoCurrencyNetwork.test),
    Litecoin(CryptoCurrencyNetwork.test),
    Stellar(CryptoCurrencyNetwork.test),
  ];

  /// A Map linking a CryptoCurrency with its associated Coin.
  ///
  /// Temporary: Remove when the Coin enum is removed.dd
  static final Map<Coin, CryptoCurrency> coins = {
    Coin.bitcoin: Bitcoin(CryptoCurrencyNetwork.main),
    Coin.monero: Monero(CryptoCurrencyNetwork.main),
    Coin.banano: Banano(CryptoCurrencyNetwork.main),
    Coin.bitcoincash: Bitcoincash(CryptoCurrencyNetwork.main),
    Coin.bitcoinFrost: BitcoinFrost(CryptoCurrencyNetwork.main),
    Coin.dogecoin: Dogecoin(CryptoCurrencyNetwork.main),
    Coin.eCash: Ecash(CryptoCurrencyNetwork.main),
    Coin.epicCash: Epiccash(CryptoCurrencyNetwork.main),
    Coin.ethereum: Ethereum(CryptoCurrencyNetwork.main),
    Coin.firo: Firo(CryptoCurrencyNetwork.main),
    Coin.litecoin: Litecoin(CryptoCurrencyNetwork.main),
    Coin.namecoin: Namecoin(CryptoCurrencyNetwork.main),
    Coin.nano: Nano(CryptoCurrencyNetwork.main),
    Coin.particl: Particl(CryptoCurrencyNetwork.main),
    Coin.stellar: Stellar(CryptoCurrencyNetwork.main),
    Coin.tezos: Tezos(CryptoCurrencyNetwork.main),
    Coin.wownero: Wownero(CryptoCurrencyNetwork.main),
  };
}
