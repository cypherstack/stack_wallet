import 'dart:typed_data';

import 'package:bitcoindart/src/utils/constants/op.dart' as op;
import 'package:bitcoindart/src/utils/script.dart' as bscript;

abstract final class BchUtils {
  static bool isSLP(Uint8List scriptPubKey) {
    const id = [83, 76, 80, 0]; // 'SLP\x00'
    final decompiled = bscript.decompile(scriptPubKey);

    if (decompiled != null &&
        decompiled.length > 1 &&
        decompiled.first == op.OPS["OP_RETURN"]) {
      final _id = decompiled[1];

      if (_id is List<int> && _id.length == id.length) {
        for (int i = 0; i < id.length; i++) {
          if (_id[i] != id[i]) {
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
