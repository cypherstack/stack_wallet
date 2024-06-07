import '../intermediate/bip39_hd_currency.dart';

mixin ElectrumXCurrencyInterface on Bip39HDCurrency {
  int get transactionVersion;

  /// The default fee rate in satoshis per kilobyte.
  int get defaultFeeRate;
}
