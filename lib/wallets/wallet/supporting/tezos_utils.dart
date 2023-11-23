import 'dart:convert';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:coinlib_flutter/coinlib_flutter.dart';
import 'package:tezart/src/crypto/crypto.dart';
import 'package:tezart/tezart.dart';

class _Node {
  final Uint8List privateKey;
  final Uint8List chainCode;

  _Node(this.privateKey, this.chainCode);
}

_Node _deriveRootNode(Uint8List seed) {
  return _deriveNode(seed, Uint8List.fromList(utf8.encode("ed25519 seed")));
}

_Node _deriveNode(Uint8List msg, Uint8List key) {
  final hMac = hmacSha512(key, msg);
  final privateKey = hMac.sublist(0, 32);
  final chainCode = hMac.sublist(32);
  return _Node(privateKey, chainCode);
}

_Node _deriveChildNode(_Node node, int index) {
  Uint8List indexBuf = Uint8List(4);
  ByteData.view(indexBuf.buffer).setUint32(0, index, Endian.big);

  Uint8List message = Uint8List.fromList([
    Uint8List(1)[0],
    ...node.privateKey,
    ...indexBuf,
  ]);

  return _deriveNode(message, Uint8List.fromList(node.chainCode));
}

List<int> _derivationPathToArray(String derivationPath) {
  if (derivationPath.isEmpty) {
    return [];
  }

  derivationPath = derivationPath.replaceAll('m/', '').replaceAll("'", 'h');

  return derivationPath.split('/').map((level) {
    if (level.endsWith("h")) {
      level = level.substring(0, level.length - 1);
    }
    final int levelNumber = int.parse(level);
    if (levelNumber >= 0x80000000) {
      throw ArgumentError('Invalid derivation path. Out of bound.');
    }
    return levelNumber + 0x80000000;
  }).toList();
}

Keystore mnemonicToKeyStore({
  required String mnemonic,
  String mnemonicPassphrase = "",
  String derivationPath = "",
}) {
  if (derivationPath.isEmpty) {
    return Keystore.fromMnemonic(mnemonic, password: mnemonicPassphrase);
  }

  final pathArray = _derivationPathToArray(derivationPath);
  final seed = bip39.mnemonicToSeed(mnemonic, passphrase: mnemonicPassphrase);
  _Node node = _deriveRootNode(seed);
  for (final index in pathArray) {
    node = _deriveChildNode(node, index);
  }

  final encoded = encodeWithPrefix(
    prefix: Prefixes.edsk2,
    bytes: node.privateKey,
  );

  return Keystore.fromSeed(encoded);
}
