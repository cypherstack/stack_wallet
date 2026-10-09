import 'dart:typed_data';

import 'package:pointycastle/digests/keccak.dart';

/// CryptoNote base58: 8 byte blocks encode to 11 characters, the trailing
/// partial block to one of the lengths in [_decodedBlockSize].
const _alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
const _fullBlockSize = 8;
const _fullEncodedBlockSize = 11;

/// Encoded block length -> decoded byte length. `-1` marks lengths CryptoNote
/// base58 can never emit.
const _decodedBlockSize = <int>[0, -1, 1, 2, -1, 3, 4, 5, -1, 6, 7, 8];

const _checksumSize = 4;
const _keySize = 32;
const _paymentIdSize = 8;

final _alphabetIndex = <int, int>{
  for (int i = 0; i < _alphabet.length; i++) _alphabet.codeUnitAt(i): i,
};

/// The base58 network tag of [address] (which identifies both the network and
/// whether the address is standard, integrated or a subaddress), or `null` if
/// [address] is not a structurally valid, checksum correct CryptoNote address.
int? cryptonoteAddressTag(String address) {
  final raw = _decodeBase58(address);
  if (raw == null || raw.length <= _checksumSize) {
    return null;
  }

  final body = raw.sublist(0, raw.length - _checksumSize);
  final expected = KeccakDigest(256).process(body);
  for (int i = 0; i < _checksumSize; i++) {
    if (raw[body.length + i] != expected[i]) {
      return null;
    }
  }

  final tag = _readVarint(body);
  if (tag == null) {
    return null;
  }

  final payload = body.length - tag.size;
  if (payload != 2 * _keySize && payload != 2 * _keySize + _paymentIdSize) {
    return null;
  }

  return tag.value;
}

({int value, int size})? _readVarint(Uint8List bytes) {
  int value = 0;
  int shift = 0;
  for (int i = 0; i < bytes.length; i++) {
    value |= (bytes[i] & 0x7f) << shift;
    if (bytes[i] & 0x80 == 0) {
      return (value: value, size: i + 1);
    }
    shift += 7;
    if (shift > 56) {
      return null;
    }
  }
  return null;
}

Uint8List? _decodeBase58(String input) {
  if (input.isEmpty) {
    return null;
  }

  final fullBlocks = input.length ~/ _fullEncodedBlockSize;
  final lastEncodedSize = input.length % _fullEncodedBlockSize;
  final lastSize = _decodedBlockSize[lastEncodedSize];
  if (lastSize < 0) {
    return null;
  }

  final out = Uint8List(fullBlocks * _fullBlockSize + lastSize);
  for (int i = 0; i <= fullBlocks; i++) {
    final start = i * _fullEncodedBlockSize;
    final size = i < fullBlocks ? _fullBlockSize : lastSize;
    if (size == 0) {
      break;
    }
    final block = input.substring(
      start,
      i < fullBlocks ? start + _fullEncodedBlockSize : input.length,
    );
    if (!_decodeBlock(block, out, i * _fullBlockSize, size)) {
      return null;
    }
  }

  return out;
}

bool _decodeBlock(String block, Uint8List out, int offset, int size) {
  BigInt value = BigInt.zero;
  for (final unit in block.codeUnits) {
    final digit = _alphabetIndex[unit];
    if (digit == null) {
      return false;
    }
    value = value * BigInt.from(_alphabet.length) + BigInt.from(digit);
  }

  // Reject overlong encodings, which would otherwise decode to a different
  // byte string than the one that produced them.
  if (value.bitLength > 8 * size) {
    return false;
  }

  for (int i = size - 1; i >= 0; i--) {
    out[offset + i] = (value & BigInt.from(0xff)).toInt();
    value >>= 8;
  }
  return true;
}
