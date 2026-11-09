import 'dart:typed_data';

import 'package:bls_dart/bls_dart.dart';

abstract final class FiroLegacyBls {
  static Future<void>? _initialization;

  static Future<void> _ensureInitialized() =>
      _initialization ??= RustLib.init();

  static Uint8List _decodeHex(String keyHex) {
    final normalized = keyHex.trim().replaceFirst(RegExp(r'^0x'), '');
    if (normalized.length != 64 ||
        !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(normalized)) {
      throw const FormatException(
        'Operator BLS private key must be 64 hexadecimal characters.',
      );
    }
    return Uint8List.fromList([
      for (var i = 0; i < normalized.length; i += 2)
        int.parse(normalized.substring(i, i + 2), radix: 16),
    ]);
  }

  static Future<Uint8List> publicKeyFromPrivateKey(String keyHex) async {
    await _ensureInitialized();
    final key = _decodeHex(keyHex);
    try {
      final publicKey = firoLegacyBlsPublicKey(secretKey: key);
      if (publicKey.length != 48) {
        throw StateError('BLS library returned an invalid public key.');
      }
      return publicKey;
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }

  static Future<Uint8List> signDigest({
    required String privateKeyHex,
    required Uint8List digest,
  }) async {
    if (digest.length != 32) {
      throw ArgumentError.value(digest.length, 'digest.length', 'must be 32');
    }
    await _ensureInitialized();
    final key = _decodeHex(privateKeyHex);
    try {
      final signature = firoLegacyBlsSignDigest(secretKey: key, digest: digest);
      if (signature.length != 96) {
        throw StateError('BLS library returned an invalid signature.');
      }
      return signature;
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }
}
