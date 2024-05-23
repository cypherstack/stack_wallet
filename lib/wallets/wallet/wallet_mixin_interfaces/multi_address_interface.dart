import '../../crypto_currency/crypto_currency.dart';
import '../wallet.dart';

mixin MultiAddressInterface<T extends CryptoCurrency> on Wallet<T> {
  Future<void> generateNewReceivingAddress();
  Future<void> checkReceivingAddressForTransactions();
  Future<void> generateNewChangeAddress();
  Future<void> checkChangeAddressForTransactions();
}
