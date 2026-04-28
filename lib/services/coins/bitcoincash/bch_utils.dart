import 'dart:typed_data';

import 'package:coin/coin.dart';
import '../../../utilities/extensions/impl/string.dart';

abstract final class BchUtils {
  static const FUSE_ID = 'FUZ\x00';

  static bool isSLP(Uint8List scriptPubKey) {
    const id = [83, 76, 80, 0]; // 'SLP\x00'
    final script = Script.decompile(scriptPubKey);

    if (script.ops.length > 1 &&
        script.ops.first is OpCode &&
        (script.ops.first as OpCode).code == Op.returnOp) {
      final idOp = script.ops[1];

      if (idOp is PushData && idOp.data.length == id.length) {
        for (int i = 0; i < id.length; i++) {
          if (idOp.data[i] != id[i]) {
            return false;
          }
        }
        // lists match!
        return true;
      }
    }

    return false;
  }

  static bool isFUZE(Uint8List scriptPubKey) {
    final id = FUSE_ID.toUint8ListFromUtf8;
    final script = Script.decompile(scriptPubKey);

    if (script.ops.length > 2 &&
        script.ops.first is OpCode &&
        (script.ops.first as OpCode).code == Op.returnOp) {
      // check session hash length. Should be 32 bytes
      final sessionOp = script.ops[2];
      if (!(sessionOp is PushData && sessionOp.data.length == 32)) {
        return false;
      }

      final idOp = script.ops[1];

      if (idOp is PushData && idOp.data.length == id.length) {
        for (int i = 0; i < id.length; i++) {
          if (idOp.data[i] != id[i]) {
            return false;
          }
        }
        // lists match!
        return true;
      }
    }

    return false;
  }
}
