import 'dart:typed_data';

import 'package:coin/coin.dart' as coin;

const OP_EXCHANGEADDR = 0xe0;

class EXP2PKHAddress {
  /// The 160bit public key or redeemScript hash for the base58 address
  final Uint8List _hash;

  /// The network and address type version of the address
  final Uint8List version;

  String? _encodedCache;

  EXP2PKHAddress._(Uint8List hash, this.version) : _hash = hash {
    if (version.length != 3) {
      throw ArgumentError(
        "version bytes length must be 3",
      );
    }
  }

  factory EXP2PKHAddress.fromString(String encoded, Uint8List versionBytes) {
    if (versionBytes.length != 3) {
      throw ArgumentError(
        "version bytes length must be 3",
      );
    }

    final data = coin.base58Decode(encoded);
    if (data.length != 23) throw ArgumentError('Invalid EX address');

    final version = data.sublist(0, 3);

    for (int i = 0; i < 3; i++) {
      if (version[i] != versionBytes[i]) {
        throw Exception("EX address version bytes do not match");
      }
    }

    final payload = data.sublist(3);

    final addr = EXP2PKHAddress._(payload, version);

    addr._encodedCache = encoded;
    return addr;
  }

  @override
  String toString() => _encodedCache.toString();

  Uint8List get scriptPubKey => Uint8List.fromList([
        0xe0, // OP_EXCHANGEADDR
        0x76, // OP_DUP
        0xa9, // OP_HASH160
        0x14, // push 20 bytes
        ..._hash,
        0x88, // OP_EQUALVERIFY
        0xac, // OP_CHECKSIG
      ]);
}

class EXP2PKH {
  static Uint8List scriptPubKey(Uint8List pkHash) => Uint8List.fromList([
        0xe0, // OP_EXCHANGEADDR
        0x76, // OP_DUP
        0xa9, // OP_HASH160
        0x14, // push 20 bytes
        ...pkHash,
        0x88, // OP_EQUALVERIFY
        0xac, // OP_CHECKSIG
      ]);
}
