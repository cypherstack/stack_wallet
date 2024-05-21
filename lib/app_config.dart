import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

abstract class AppConfig {
  static const appName = prefix + _separator + suffix;

  static const prefix = "Stack";

  static const _separator = " ";

  static const suffix = "Wallet";

  // comment out coins to disable them
  static const supportedCoins = [
    Bitcoin,
    BitcoinFrost,
    Litecoin,
    Bitcoincash,
    Dogecoin,
    Epiccash,
    Ecash,
    Ethereum,
    Firo,
    Monero,
    Particl,
    Peercoin,
    Solana,
    Stellar,
    Tezos,
    Wownero,
    Namecoin,
    Nano,
    Banano,
  ];
}
