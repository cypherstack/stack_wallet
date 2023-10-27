import 'dart:typed_data';

import 'package:bitcoindart/src/utils/constants/op.dart' as op;
import 'package:bitcoindart/src/utils/script.dart' as bscript;
import 'package:stackwallet/utilities/extensions/impl/string.dart';

abstract final class BchUtils {
  static const FUSE_ID = 'FUZ\x00';

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

  static bool isFUZE(Uint8List scriptPubKey) {
    final id = FUSE_ID.toUint8ListFromUtf8;
    final decompiled = bscript.decompile(scriptPubKey);

    if (decompiled != null &&
        decompiled.length > 2 &&
        decompiled.first == op.OPS["OP_RETURN"]) {
      // check session hash length. Should be 32 bytes
      final sessionHash = decompiled[2];
      if (!(sessionHash is List<int> && sessionHash.length == 32)) {
        return false;
      }

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
