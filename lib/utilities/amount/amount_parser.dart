import '../../models/isar/models/contract.dart';
import '../../wallets/crypto_currency/crypto_currency.dart';
import 'amount.dart';
import 'amount_unit.dart';

/// Parses editable text using the locale and unit associated with that text.
///
/// Parsing deliberately has no provider or cached formatting preferences.
/// Display updates must preserve the canonical amount instead of parsing their
/// own output. Only input changes should call this API.
abstract final class AmountParser {
  static Amount? tryParseEditable(
    String text, {
    required String locale,
    required AmountUnit unit,
    required CryptoCurrency coin,
    Contract? tokenContract,
  }) => unit.tryParse(
    text,
    locale: locale,
    coin: coin,
    tokenContract: tokenContract,
  );
}
