import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

mixin MultiAddress<T extends CryptoCurrency> on Wallet<T> {
  Future<void> generateNewReceivingAddress();
  Future<void> checkReceivingAddressForTransactions();
  Future<void> generateNewChangeAddress();
  Future<void> checkChangeAddressForTransactions();
}
