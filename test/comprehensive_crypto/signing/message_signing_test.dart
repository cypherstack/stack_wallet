/// Bitcoin message signing round-trip tests exercising the
/// coin.MessageSig API used by SignVerifyInterface implementations.
///
/// Requires secp256k1 native library:
///   LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib flutter test test/comprehensive_crypto/signing/message_signing_test.dart
///
/// Satisfies: TEST-02, TEST-04 (message signing round-trip).
import 'dart:typed_data';

import 'package:coin/coin.dart' as coin;
import 'package:flutter_test/flutter_test.dart';

import '../../bitcoindart_coverage/test_vectors.dart';

void main() {
  setUpAll(() async {
    await coin.VaultKeeper.initialize();
  });

  group('Bitcoin message signing', () {
    const bitcoinPrefix = '\x18Bitcoin Signed Message:\n';

    late Uint8List privKeyBytes;
    late Uint8List pubKeyBytes;

    setUp(() {
      privKeyBytes = hexToBytes(kTestPrivKeyHex1);
      final sk = coin.SecretKey(privKeyBytes);
      pubKeyBytes = sk.publicKey.bytes;
    });

    test('signMessage produces verifiable signature for P2PKH address', () {
      const message = 'Hello Stack Wallet';

      final msgSig = coin.MessageSig.sign(
        message,
        privKeyBytes,
        messagePrefix: bitcoinPrefix,
      );

      // Verify with public key.
      expect(
        msgSig.verify(message, pubKeyBytes, messagePrefix: bitcoinPrefix),
        isTrue,
        reason: 'MessageSig should verify with correct key and message',
      );

      // Recover public key and verify it matches.
      final recovered = msgSig.recoverPublicKey(
        message,
        messagePrefix: bitcoinPrefix,
      );
      expect(
        bytesToHex(recovered),
        equals(bytesToHex(pubKeyBytes)),
        reason: 'Recovered public key should match signing key',
      );
    });

    test('signMessage produces verifiable signature for P2WPKH address', () {
      const message = 'Hello Stack Wallet SegWit';

      // The message signing algorithm is address-agnostic; it signs
      // with a private key. The address type only determines how the
      // address is encoded for display. The signature itself verifies
      // against the public key directly.
      final msgSig = coin.MessageSig.sign(
        message,
        privKeyBytes,
        messagePrefix: bitcoinPrefix,
      );

      expect(
        msgSig.verify(message, pubKeyBytes, messagePrefix: bitcoinPrefix),
        isTrue,
        reason: 'MessageSig should verify regardless of address type',
      );

      // Round-trip through bytes serialization.
      final bytes65 = msgSig.toBytes();
      expect(bytes65.length, equals(65));
      final restored = coin.MessageSig.fromBytes(bytes65);
      expect(
        restored.verify(message, pubKeyBytes, messagePrefix: bitcoinPrefix),
        isTrue,
        reason: 'Round-tripped MessageSig should verify',
      );
    });

    test('verifyMessage rejects tampered message', () {
      const original = 'Hello';
      const tampered = 'Goodbye';

      final msgSig = coin.MessageSig.sign(
        original,
        privKeyBytes,
        messagePrefix: bitcoinPrefix,
      );

      // Verify with correct message.
      expect(
        msgSig.verify(original, pubKeyBytes, messagePrefix: bitcoinPrefix),
        isTrue,
      );

      // Verify with tampered message should fail.
      expect(
        msgSig.verify(tampered, pubKeyBytes, messagePrefix: bitcoinPrefix),
        isFalse,
        reason: 'MessageSig should NOT verify with tampered message',
      );
    });

    test('verifyMessage rejects wrong address', () {
      const message = 'Hello Stack Wallet';

      final msgSig = coin.MessageSig.sign(
        message,
        privKeyBytes,
        messagePrefix: bitcoinPrefix,
      );

      // Sign with key A, verify with key B's public key.
      final skB = coin.SecretKey(hexToBytes(kTestPrivKeyHex2));
      final pubKeyBytesB = skB.publicKey.bytes;

      expect(
        msgSig.verify(message, pubKeyBytesB, messagePrefix: bitcoinPrefix),
        isFalse,
        reason: 'MessageSig should NOT verify with wrong public key',
      );

      // Also verify that recovery gives key A, not key B.
      final recovered = msgSig.recoverPublicKey(
        message,
        messagePrefix: bitcoinPrefix,
      );
      expect(
        bytesToHex(recovered),
        isNot(equals(bytesToHex(pubKeyBytesB))),
        reason: 'Recovered key should not match key B',
      );
    });
  });
}
