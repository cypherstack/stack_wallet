import 'package:stackwallet/wallets/crypto_currency/coins/nano.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/nano_currency.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/nano_interface.dart';

class NanoWallet extends Bip39Wallet<NanoCurrency> with NanoInterface {
  NanoWallet(CryptoCurrencyNetwork network) : super(Nano(network));
}
