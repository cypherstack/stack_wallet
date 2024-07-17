import 'dart:typed_data';

import '../../../utilities/amount/amount.dart';
import '../crypto_currency.dart';

abstract class FrostCurrency extends CryptoCurrency {
  FrostCurrency(super.network);

  // String pubKeyToScriptHash({required Uint8List pubKey});

  String addressToScriptHash({required String address});

  Uint8List addressToPubkey({required String address});

  Amount get dustLimit;
}
