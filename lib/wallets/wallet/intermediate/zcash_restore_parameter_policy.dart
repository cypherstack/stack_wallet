import '../../crypto_currency/crypto_currency.dart';

bool shouldAcquireSaplingParametersAfterRestore({
  required CryptoCurrencyNetwork network,
  required int spendableSaplingZatoshis,
}) => spendableSaplingZatoshis > 0;
