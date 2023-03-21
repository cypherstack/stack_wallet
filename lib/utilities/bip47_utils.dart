import 'dart:typed_data';

import 'package:bip47/src/util.dart';
import 'package:stackduo/models/isar/models/blockchain_data/output.dart';
import 'package:stackduo/models/isar/models/blockchain_data/transaction.dart';

abstract class Bip47Utils {
  /// looks at tx outputs and returns a blinded payment code if found
  static Uint8List? getBlindedPaymentCodeBytesFrom(Transaction transaction) {
    for (int i = 0; i < transaction.outputs.length; i++) {
      final bytes = getBlindedPaymentCodeBytesFromOutput(
          transaction.outputs.elementAt(i));
      if (bytes != null) {
        return bytes;
      }
    }

    return null;
  }

  static Uint8List? getBlindedPaymentCodeBytesFromOutput(Output output) {
    Uint8List? blindedCodeBytes;

    List<String>? scriptChunks = output.scriptPubKeyAsm?.split(" ");
    if (scriptChunks?.length == 2 && scriptChunks?[0] == "OP_RETURN") {
      final blindedPaymentCode = scriptChunks![1];
      final bytes = blindedPaymentCode.fromHex;

      // https://en.bitcoin.it/wiki/BIP_0047#Sending
      if (bytes.length == 80 && bytes.first == 1) {
        blindedCodeBytes = bytes;
      }
    }

    return blindedCodeBytes;
  }
}
