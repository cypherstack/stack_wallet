import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib;
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/extensions/extensions.dart';

/// Minimal transaction decoder, independent of coinlib's input matching
/// (which does not recognise P2SH-P2WPKH inputs).
class DecodedTx {
  DecodedTx(this.bytes) {
    var o = 0;
    int u8() => bytes[o++];
    int le(int n) {
      var v = 0;
      for (var i = 0; i < n; i++) {
        v |= bytes[o + i] << (8 * i);
      }
      o += n;
      return v;
    }

    int varInt() {
      final b = u8();
      return b < 0xfd ? b : le(b == 0xfd ? 2 : (b == 0xfe ? 4 : 8));
    }

    Uint8List slice(int n) => Uint8List.sublistView(bytes, o, o += n);

    version = le(4);
    final segwit = bytes[o] == 0 && bytes[o + 1] == 1;
    if (segwit) o += 2;
    final nIn = varInt();
    for (var i = 0; i < nIn; i++) {
      final hash = slice(32);
      final n = le(4);
      final scriptSig = slice(varInt());
      final sequence = le(4);
      inputs.add((
        txid: Uint8List.fromList(hash.reversed.toList()).toHex,
        vout: n,
        scriptSig: scriptSig,
        sequence: sequence,
      ));
    }
    final nOut = varInt();
    for (var i = 0; i < nOut; i++) {
      final value = le(8);
      outputs.add((value: value, script: slice(varInt())));
    }
    final witnessStart = o;
    if (segwit) {
      for (var i = 0; i < nIn; i++) {
        witnesses.add([for (var j = varInt(); j > 0; j--) slice(varInt())]);
      }
    }
    final witnessEnd = o;
    locktime = le(4);
    expect(o, bytes.length);
    final stripped = segwit
        ? Uint8List.fromList([
            ...bytes.sublist(0, 4),
            ...bytes.sublist(6, witnessStart),
            ...bytes.sublist(witnessEnd),
          ])
        : bytes;
    weight = stripped.length * 3 + bytes.length;
    txid = Uint8List.fromList(
      coinlib.sha256DoubleHash(stripped).reversed.toList(),
    ).toHex;
    wtxid = Uint8List.fromList(
      coinlib.sha256DoubleHash(bytes).reversed.toList(),
    ).toHex;
  }

  final Uint8List bytes;
  late final int version;
  late final int locktime;
  late final int weight;
  late final String txid;
  late final String wtxid;
  final List<({String txid, int vout, Uint8List scriptSig, int sequence})>
  inputs = [];
  final List<({int value, Uint8List script})> outputs = [];
  final List<List<Uint8List>> witnesses = [];

  int get vSize => (weight + 3) ~/ 4;
}
