import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

abstract class CryptonoteCurrency extends CryptoCurrency {
  CryptonoteCurrency(super.network);

  @override
  String get genesisHash {
    return "not used in stack's cryptonote coins";
  }
}
