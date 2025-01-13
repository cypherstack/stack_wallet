import '../../crypto_currency/crypto_currency.dart';
import '../wallet.dart';

mixin CoinControlInterface<T extends CryptoCurrency> on Wallet<T> {
  // any required here?
  // currently only used to id which wallets support coin control
}
