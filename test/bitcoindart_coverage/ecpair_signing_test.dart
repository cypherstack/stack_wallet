// Coverage tests for bitcoindart ECPair construction and ECDSA signing API.
// Commented out: bitcoindart is no longer a direct dependency.
// Kept as historical reference for the original API patterns.
// See equivalence test files (*_equiv_test.dart) for the active coin regression suite.

/*
import 'dart:typed_data';

import 'package:bitcoindart/bitcoindart.dart' as bitcoindart;
import 'package:flutter_test/flutter_test.dart';

import 'test_vectors.dart';

void main() {
  group('ECPair.fromPrivateKey construction', () {
    test('creates key pair with 33-byte compressed public key', () {
      final pair = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        compressed: true,
      );
      expect(pair.publicKey, isNotNull);
      expect(pair.publicKey!.length, equals(33));
      // Compressed pubkey starts with 0x02 or 0x03
      expect(pair.publicKey![0], anyOf(equals(0x02), equals(0x03)));
    });

    test('produces expected public key for kTestPrivKeyHex1', () {
      final pair = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        compressed: true,
      );
      expect(bytesToHex(pair.publicKey!), equals(kTestPubKeyHex1));
    });

    test('produces expected public key for kTestPrivKeyHex2', () {
      final pair = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex2),
        compressed: true,
      );
      expect(bytesToHex(pair.publicKey!), equals(kTestPubKeyHex2));
    });

    test('different private keys produce different public keys', () {
      final pair1 = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        compressed: true,
      );
      final pair2 = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex2),
        compressed: true,
      );
      expect(pair1.publicKey, isNot(equals(pair2.publicKey)));
    });

    test('compressed=true is default behavior (33-byte pubkey)', () {
      final pairExplicit = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        compressed: true,
      );
      final pairDefault = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
      );
      expect(pairDefault.publicKey!.length, equals(33));
      expect(pairDefault.publicKey, equals(pairExplicit.publicKey));
    });

    test('network param does not affect key or signing', () {
      final pairNoNet = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        compressed: true,
      );
      final particlNet = bitcoindart.NetworkType(
        messagePrefix: kParticlMessagePrefix,
        bech32: kParticlBech32,
        bip32: bitcoindart.Bip32Type(
          public: kParticlPubHD,
          private: kParticlPrivHD,
        ),
        pubKeyHash: kParticlP2pkh,
        scriptHash: kParticlP2sh,
        wif: kParticlWif,
      );
      final pairWithNet = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        network: particlNet,
        compressed: true,
      );
      expect(pairNoNet.publicKey, equals(pairWithNet.publicKey));
      expect(
        pairNoNet.sign(kTestHash32),
        equals(pairWithNet.sign(kTestHash32)),
      );
    });
  });

  group('ECPair.sign', () {
    // NOTE: bitcoindart ECPair.sign returns a 64-byte compact signature
    // (r || s), NOT DER-encoded. This is because bip32's ecurve.sign()
    // returns raw (r, s) as 32+32 bytes. The plan incorrectly assumed DER.
    test('produces 64-byte compact signature (r||s)', () {
      final pair = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        compressed: true,
      );
      final sig = pair.sign(kTestHash32);
      expect(sig, isNotNull);
      // Compact signature is exactly 64 bytes (32-byte r + 32-byte s)
      expect(sig.length, equals(64));
    });

    test('signing is deterministic (RFC 6979)', () {
      final pair = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        compressed: true,
      );
      final sig1 = pair.sign(kTestHash32);
      final sig2 = pair.sign(kTestHash32);
      expect(sig1, equals(sig2));
    });

    test('produces expected signature for key1 and test hash', () {
      final pair = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        compressed: true,
      );
      final sig = pair.sign(kTestHash32);
      // Golden reference: must match kExpectedCompactSigHex1 exactly
      expect(bytesToHex(sig), equals(kExpectedCompactSigHex1));
    });

    test('different hashes produce different signatures', () {
      final pair = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        compressed: true,
      );
      final hash2 = Uint8List(32)..fillRange(0, 32, 0x01);
      final sig1 = pair.sign(kTestHash32);
      final sig2 = pair.sign(hash2);
      expect(sig1, isNot(equals(sig2)));
    });

    test('different keys produce different signatures for same hash', () {
      final pair1 = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        compressed: true,
      );
      final pair2 = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex2),
        compressed: true,
      );
      final sig1 = pair1.sign(kTestHash32);
      final sig2 = pair2.sign(kTestHash32);
      expect(sig1, isNot(equals(sig2)));
    });

    test('third key also produces valid 64-byte compact signature', () {
      final pair = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex3),
        compressed: true,
      );
      final sig = pair.sign(kTestHash32);
      expect(sig.length, equals(64));
    });

    test('s value is low (canonical per BIP-62/BIP-146)', () {
      // bitcoindart enforces low-s normalization in its sign() function.
      // Verify the s component (bytes 32-63) is in the lower half of the
      // curve order by checking that the first byte of s is <= 0x7f.
      final pair = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        compressed: true,
      );
      final sig = pair.sign(kTestHash32);
      // The s value occupies bytes [32..63]. For low-s, s < n/2.
      // A quick necessary (not sufficient) check: first byte of s <= 0x7f.
      expect(sig[32] & 0x80, equals(0),
          reason: 'High bit of s should be 0 for low-s canonical form');
    });
  });
}
*/
