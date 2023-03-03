import 'dart:typed_data';

import 'package:dart_bs58/dart_bs58.dart';
import 'package:dart_bs58check/dart_bs58check.dart';
import 'package:hex/hex.dart';

extension Uint8ListExtensions on Uint8List {
  String get toHex {
    return HEX.encode(this);
  }

  String get toBase58Encoded {
    return bs58.encode(this);
  }

  String get toBase58CheckEncoded {
    return bs58check.encode(this);
  }

  /// returns copy of byte list in reverse order
  Uint8List get reversed {
    final reversed = Uint8List(length);
    for (final byte in this) {
      reversed.insert(0, byte);
    }
    return reversed;
  }

  BigInt get toBigInt {
    BigInt number = BigInt.zero;
    for (final byte in this) {
      number = (number << 8) | BigInt.from(byte & 0xff);
    }
    return number;
  }
}
