import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_hd_wallet.dart';

mixin CoinControlInterface<T extends Bip39HDCurrency> on Bip39HDWallet<T> {
  // any required here?
  // currently only used to id which wallets support coin control
}
