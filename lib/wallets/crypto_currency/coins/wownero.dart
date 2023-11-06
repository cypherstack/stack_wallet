import 'package:stackwallet/wallets/crypto_currency/intermediate/cryptonote_currency.dart';

class Wownero extends CryptonoteCurrency {
  Wownero(super.network);

  @override
  // TODO: implement genesisHash
  String get genesisHash => throw UnimplementedError();

  @override
  // TODO: implement minConfirms
  int get minConfirms => throw UnimplementedError();

  @override
  bool validateAddress(String address) {
    // TODO: implement validateAddress
    throw UnimplementedError();
  }
}
