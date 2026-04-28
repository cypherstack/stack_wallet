import 'dart:convert';
import 'dart:typed_data';

// import 'package:dart_bs58/dart_bs58.dart';
// import 'package:dart_bs58check/dart_bs58check.dart';
import 'package:hex/hex.dart';

extension Uint8ListExtensions on Uint8List {
  String get toUtf8String => utf8.decode(this);

  String get toHex {
    return HEX.encode(this);
  }

  // String get toBase58Encoded {
  //   return bs58.encode(this);
  // }
  //
  // String get toBase58CheckEncoded {
  //   return bs58check.encode(this);
  // }

  BigInt get toBigInt {
    BigInt number = BigInt.zero;
    for (final byte in this) {
      number = (number << 8) | BigInt.from(byte & 0xff);
    }
    return number;
  }

  bool equals(Uint8List other) {
    if (length != other.length) return false;
    for (var i = 0; i < length; i++) {
      if (this[i] != other[i]) return false;
    }
    return true;
  }
}
