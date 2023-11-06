import 'package:cw_wownero/api/wallet.dart' as wownero_wallet;
import 'package:stackwallet/wallets/crypto_currency/intermediate/cryptonote_currency.dart';

class Wownero extends CryptonoteCurrency {
  Wownero(super.network);

  @override
  int get minConfirms => 15;

  @override
  bool validateAddress(String address) {
    return wownero_wallet.validateAddress(address);
  }
}
