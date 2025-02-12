import '../../crypto_currency/intermediate/cryptonote_currency.dart';
import '../wallet.dart';
import '../wallet_mixin_interfaces/coin_control_interface.dart';
import '../wallet_mixin_interfaces/mnemonic_interface.dart';
import 'external_wallet.dart';

abstract class CryptonoteWallet<T extends CryptonoteCurrency> extends ExternalWallet<T>
    with MnemonicInterface<T>, CoinControlInterface<T> {
  CryptonoteWallet(super.currency);
}
