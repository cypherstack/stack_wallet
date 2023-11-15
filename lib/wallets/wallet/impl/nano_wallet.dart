import 'package:stackwallet/wallets/crypto_currency/coins/nano.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/nano_currency.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_wallet.dart';
import 'package:stackwallet/wallets/wallet/mixins/nano_based.dart';

class NanoWallet extends Bip39Wallet<NanoCurrency> with NanoBased {
  NanoWallet(CryptoCurrencyNetwork network) : super(Nano(network));
}
