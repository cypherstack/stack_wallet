import 'dart:typed_data';

extension BigIntExtensions on BigInt {
  String get toHex {
    if (this < BigInt.zero) {
      throw Exception("BigInt value is negative");
    }

    final String hex = toRadixString(16);
    if (hex.length % 2 == 0) {
      return hex;
    } else {
      return "0$hex";
    }
  }

  String get toHexUppercase => toHex.toUpperCase();

  Uint8List get toBytes {
    if (this < BigInt.zero) {
      throw Exception("BigInt value is negative");
    }
    BigInt number = this;
    int bytes = (number.bitLength + 7) >> 3;
    final b256 = BigInt.from(256);
    final result = Uint8List(bytes);
    for (int i = 0; i < bytes; i++) {
      result[bytes - 1 - i] = number.remainder(b256).toInt();
      number = number >> 8;
    }
    return result;
  }
}
