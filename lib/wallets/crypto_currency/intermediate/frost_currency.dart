import 'dart:typed_data';

import '../../../utilities/amount/amount.dart';
import '../crypto_currency.dart';

abstract class FrostCurrency extends CryptoCurrency {
  FrostCurrency(super.network);

  String pubKeyToScriptHash({required Uint8List pubKey});

  Amount get dustLimit;
}
