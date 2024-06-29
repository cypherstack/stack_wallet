import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;

const OP_EXCHANGEADDR = 0xe0;

class EXP2PKHAddress implements coinlib.Address {
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

    final data = coinlib.base58Decode(encoded);
    if (data.length != 23) throw coinlib.InvalidAddress();

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

  @override
  coinlib.Program get program => EXP2PKH.fromHash(_hash);
}

class EXP2PKH implements coinlib.Program {
  static const template =
      "OP_EXCHANGEADDR OP_DUP OP_HASH160 <20-bytes> OP_EQUALVERIFY OP_CHECKSIG";

  @override
  final coinlib.Script script;

  EXP2PKH.fromScript(this.script);

  factory EXP2PKH.fromHash(Uint8List pkHash) {
    final List<coinlib.ScriptOp> ops = [
      coinlib.ScriptOpCode(OP_EXCHANGEADDR),
    ];
    final parts = template.split(" ").sublist(1);
    for (final name in parts) {
      if (name.startsWith("OP_")) {
        ops.add(
          coinlib.ScriptOpCode(
            coinlib.scriptOpNameToCode[name.substring(3)]!,
          ),
        );
      } else if (name == "<20-bytes>") {
        ops.add(coinlib.ScriptPushData(pkHash));
      } else {
        throw Exception("Something went wrong in this hacked code");
      }
    }

    return EXP2PKH.fromScript(coinlib.Script(ops));
  }
}
