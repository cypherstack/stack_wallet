import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/crypto_currency/interfaces/electrumx_currency_interface.dart';
import 'package:stackwallet/wallets/crypto_currency/intermediate/bip39_hd_currency.dart';

mixin PaynymCurrencyInterface on ElectrumXCurrencyInterface, Bip39HDCurrency {
  Amount get dustLimitP2PKH => Amount(
        rawValue: BigInt.from(546),
        fractionDigits: fractionDigits,
      );
}
