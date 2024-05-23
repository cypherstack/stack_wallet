import '../../crypto_currency/coins/nano.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../crypto_currency/intermediate/nano_currency.dart';
import '../intermediate/bip39_wallet.dart';
import '../wallet_mixin_interfaces/nano_interface.dart';

class NanoWallet extends Bip39Wallet<NanoCurrency> with NanoInterface {
  NanoWallet(CryptoCurrencyNetwork network) : super(Nano(network));
}
