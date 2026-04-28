import 'dart:typed_data';

import 'package:coin/coin.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_vectors.dart';

void main() {
  setUpAll(() async {
    await VaultKeeper.initialize();
  });

  group('SecretKey construction equivalence', () {
    test('produces same compressed public key as ECPair for key1', () {
      final sk = SecretKey.fromHex(kTestPrivKeyHex1);
      final pubKey = sk.publicKey;
      // Must be 33 bytes, compressed
      expect(pubKey.bytes.length, equals(33));
      // First byte 0x02 or 0x03
      expect(pubKey.bytes[0], anyOf(equals(0x02), equals(0x03)));
      // Must match the expected pubkey from test_vectors
      expect(pubKey.toHex(), equals(kTestPubKeyHex1));
    });

    test('produces same compressed public key as ECPair for key2', () {
      final sk = SecretKey.fromHex(kTestPrivKeyHex2);
      final pubKey = sk.publicKey;
      expect(pubKey.bytes.length, equals(33));
      expect(pubKey.toHex(), equals(kTestPubKeyHex2));
    });

    test('produces same compressed public key as ECPair for key3', () {
      final sk = SecretKey.fromHex(kTestPrivKeyHex3);
      final pubKey = sk.publicKey;
      expect(pubKey.bytes.length, equals(33));
      expect(pubKey.toHex(), equals(kTestPubKeyHex3));
    });

    test('different keys produce different public keys', () {
      final sk1 = SecretKey.fromHex(kTestPrivKeyHex1);
      final sk2 = SecretKey.fromHex(kTestPrivKeyHex2);
      expect(sk1.publicKey, isNot(equals(sk2.publicKey)));
    });
  });

  group('EcdsaSig.sign equivalence', () {
    test(
        'produces byte-identical compact signature to ECPair.sign',
        () {
      final sk = SecretKey.fromHex(kTestPrivKeyHex1);
      final sig = EcdsaSig.sign(kTestHash32, sk.bytes);

      // Compact is 64 bytes (r||s) -- same format as bitcoindart
      final compact = sig.bytes;
      expect(compact.length, equals(64));

      // THE critical equivalence check: must match the golden reference
      // captured from bitcoindart ECPair.sign for the same key+hash.
      expect(bytesToHex(compact), equals(kExpectedCompactSigHex1));
    });

    test('toDer() produces valid DER encoding of the same signature', () {
      final sk = SecretKey.fromHex(kTestPrivKeyHex1);
      final sig = EcdsaSig.sign(kTestHash32, sk.bytes);

      // DER encoding of the compact signature
      final der = sig.toDer();
      // DER signature starts with 0x30 (SEQUENCE tag)
      expect(der[0], equals(0x30));
      // DER length varies 70-72 bytes for secp256k1
      expect(der.length, inInclusiveRange(70, 72));
    });

    test('signing is deterministic (RFC 6979)', () {
      final sk = SecretKey.fromHex(kTestPrivKeyHex1);
      final sig1 = EcdsaSig.sign(kTestHash32, sk.bytes);
      final sig2 = EcdsaSig.sign(kTestHash32, sk.bytes);
      expect(sig1.bytes, equals(sig2.bytes));
      expect(sig1.toDer(), equals(sig2.toDer()));
    });

    test('different keys produce different signatures', () {
      final sk1 = SecretKey.fromHex(kTestPrivKeyHex1);
      final sk2 = SecretKey.fromHex(kTestPrivKeyHex2);
      final sig1 = EcdsaSig.sign(kTestHash32, sk1.bytes);
      final sig2 = EcdsaSig.sign(kTestHash32, sk2.bytes);
      expect(sig1.bytes, isNot(equals(sig2.bytes)));
    });

    test('different hashes produce different signatures', () {
      final sk = SecretKey.fromHex(kTestPrivKeyHex1);
      final hash2 = Uint8List(32)..fillRange(0, 32, 0x01);
      final sig1 = EcdsaSig.sign(kTestHash32, sk.bytes);
      final sig2 = EcdsaSig.sign(hash2, sk.bytes);
      expect(sig1.bytes, isNot(equals(sig2.bytes)));
    });

    test('compact format is 64 bytes, DER round-trips through fromDer', () {
      final sk = SecretKey.fromHex(kTestPrivKeyHex1);
      final sig = EcdsaSig.sign(kTestHash32, sk.bytes);

      final der = sig.toDer();
      final restored = EcdsaSig.fromDer(der);
      expect(restored.bytes, equals(sig.bytes));
    });

    test('signature verifies against the correct public key', () {
      final sk = SecretKey.fromHex(kTestPrivKeyHex1);
      final sig = EcdsaSig.sign(kTestHash32, sk.bytes);
      final verified = sig.verify(kTestHash32, sk.publicKey.bytes);
      expect(verified, isTrue);
    });

    test('signature does not verify against wrong public key', () {
      final sk1 = SecretKey.fromHex(kTestPrivKeyHex1);
      final sk2 = SecretKey.fromHex(kTestPrivKeyHex2);
      final sig = EcdsaSig.sign(kTestHash32, sk1.bytes);
      final verified = sig.verify(kTestHash32, sk2.publicKey.bytes);
      expect(verified, isFalse);
    });
  });
}
