import 'dart:typed_data';

import 'package:coin/coin.dart' as coin;
import 'package:hex/hex.dart';
import 'package:pointycastle/ecc/api.dart';

const _base58Alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

/// Pure-Dart base58 encoding (no checksum).
String _base58Encode(Uint8List data) {
  var number = BigInt.zero;
  for (final b in data) {
    number = number * BigInt.from(256) + BigInt.from(b);
  }
  final chars = <String>[];
  final big58 = BigInt.from(58);
  while (number > BigInt.zero) {
    final rem = (number % big58).toInt();
    chars.add(_base58Alphabet[rem]);
    number ~/= big58;
  }
  for (final b in data) {
    if (b != 0) break;
    chars.add('1');
  }
  return chars.reversed.join();
}

/// Pure-Dart base58 decoding (no checksum).
Uint8List _base58Decode(String encoded) {
  var number = BigInt.zero;
  final big58 = BigInt.from(58);
  for (final c in encoded.codeUnits) {
    final idx = _base58Alphabet.indexOf(String.fromCharCode(c));
    if (idx < 0) {
      throw FormatException(
          'Invalid base58 character: ${String.fromCharCode(c)}');
    }
    number = number * big58 + BigInt.from(idx);
  }

  var leadingZeros = 0;
  for (final c in encoded.codeUnits) {
    if (String.fromCharCode(c) == '1') {
      leadingZeros++;
    } else {
      break;
    }
  }

  final bytes = <int>[];
  final big256 = BigInt.from(256);
  while (number > BigInt.zero) {
    bytes.add((number % big256).toInt());
    number ~/= big256;
  }

  final result = Uint8List(leadingZeros + bytes.length);
  result.setRange(leadingZeros, result.length, bytes.reversed.toList());
  return result;
}

extension Uint8ListExt on Uint8List {
  String get toHex {
    return HEX.encode(this);
  }

  String get toBase58 {
    return _base58Encode(this);
  }

  String get toBase58Check {
    return coin.VaultKeeper.vault.codec.base58CheckEncode(this);
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

extension StringExt on String {
  Uint8List get fromHex {
    return Uint8List.fromList(HEX.decode(this));
  }

  Uint8List get fromBase58 {
    return _base58Decode(this);
  }

  Uint8List get fromBase58Check {
    return coin.VaultKeeper.vault.codec.base58CheckDecode(this);
  }
}

extension BigIntExt on BigInt {
  String get toHex {
    final String hex = toRadixString(16);
    if (hex.length % 2 == 0) {
      return hex;
    } else {
      return "0$hex";
    }
  }

  Uint8List to32Bytes() {
    BigInt number = this;
    const bytes = 32;
    var b256 = BigInt.from(256);
    var result = Uint8List(bytes);

    for (int i = 0; i < bytes; i++) {
      if (number == BigInt.zero) {
        result[bytes - 1 - i] = 0;
      } else {
        result[bytes - 1 - i] = number.remainder(b256).toUnsigned(8).toInt();
      }
      number = number >> 8;
    }
    return result;
  }

  bool isScalarGroupMemberOf(ECDomainParameters ecDomainParameters) {
    return BigInt.zero <= this && this < ecDomainParameters.n;
  }
}

abstract class Util {
  /// xor two equal length lists of bytes byte by byte
  static Uint8List xor(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      throw ArgumentError("Byte count does not match");
    }

    Uint8List result = Uint8List(a.length);

    for (int i = 0; i < a.length; i++) {
      result[i] = a[i] ^ b[i];
    }

    return result;
  }

  static void copyBytes(
    Uint8List source,
    int sourceStartingIndex,
    Uint8List destination,
    int destinationStartingIndex,
    int numberOfBytes,
  ) {
    for (int i = 0; i < numberOfBytes; i++) {
      destination[i + destinationStartingIndex] =
          source[i + sourceStartingIndex];
    }
  }

  static bool isBitSet(int byte, int pos) {
    int test = 0;
    return (setBit(test, pos) & byte) > 0;
  }

  static int setBit(int byte, int pos) {
    return (byte | (1 << pos));
  }
}
