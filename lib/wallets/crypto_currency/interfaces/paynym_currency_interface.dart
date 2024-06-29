import '../../../utilities/amount/amount.dart';
import 'electrumx_currency_interface.dart';
import '../intermediate/bip39_hd_currency.dart';

mixin PaynymCurrencyInterface on ElectrumXCurrencyInterface, Bip39HDCurrency {
  Amount get dustLimitP2PKH => Amount(
        rawValue: BigInt.from(546),
        fractionDigits: fractionDigits,
      );
}
