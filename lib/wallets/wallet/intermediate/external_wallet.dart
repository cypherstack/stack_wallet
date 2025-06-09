import '../../crypto_currency/crypto_currency.dart';
import '../wallet.dart';

// anstract class to be fleshed out for the standardization of wallet implementations
// that rely on bridged code libraries outside, or external native wallet functions
abstract class ExternalWallet<T extends CryptoCurrency> extends Wallet<T> {
  ExternalWallet(super.currency);

  // wallet opening and initialization separated to prevent db lock collision errors
  // must be overridden
  Future<void> open();
}
