import 'dart:typed_data';

import 'package:bip47/src/util.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';

abstract class Bip47Utils {
  /// looks at tx outputs and returns a blinded payment code if found
  static Uint8List? getBlindedPaymentCodeBytesFrom(Transaction transaction) {
    Uint8List? blindedCodeBytes;

    for (int i = 0; i < transaction.outputs.length; i++) {
      List<String>? scriptChunks =
          transaction.outputs.elementAt(i).scriptPubKeyAsm?.split(" ");
      if (scriptChunks?.length == 2 && scriptChunks?[0] == "OP_RETURN") {
        final blindedPaymentCode = scriptChunks![1];
        final bytes = blindedPaymentCode.fromHex;

        // https://en.bitcoin.it/wiki/BIP_0047#Sending
        if (bytes.length == 80 && bytes.first == 1) {
          blindedCodeBytes = bytes;
        }
      }
    }

    return blindedCodeBytes;
  }
}
