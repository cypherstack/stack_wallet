// MWEB key derivation tests.
// Verifies that the coin library produces deterministic keys at the exact
// derivation paths used by mweb_interface.dart:
//   _scanSecret:  m/1000'/0'  (privateKey bytes)
//   _spendSecret: m/1000'/1'  (privateKey bytes)
//   _spendPub:    m/1000'/1'  (publicKey bytes)
//
// Requires secp256k1 native library:
//   LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib flutter test test/comprehensive_crypto/integration/mweb_keys_test.dart

import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:coin/coin.dart' as coin;
import 'package:flutter_test/flutter_test.dart';

/// Convert bytes to lowercase hex string.
String _hex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

// Standard BIP39 test mnemonic (12-word "abandon" vector).
const _mnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon about';

// Regression vectors captured from bridge_caller_equivalence_test.
const _expectedScanSecretHex =
    'e1520f2a744b77b15fab8f476241543328499a2ae88caeb5b65110caa8a73959';
const _expectedSpendSecretHex =
    'ed8edcdab8e485bc0342e4c01441b759e8b5d5a9641cafe65cba63af09576021';
const _expectedSpendPubHex =
    '0265ea63e132fa775931af5e5e8d03eb0a851d4a406d9bab18f6a2e1155df5698e';

void main() {
  late coin.DerivedSecretKey root;

  setUpAll(() async {
    await coin.VaultKeeper.initialize();

    final seed = bip39.mnemonicToSeed(_mnemonic);
    root = coin.DerivedKey.fromSeed(seed) as coin.DerivedSecretKey;
  });

  group('MWEB key derivation', () {
    // =========================================================================
    // scanSecret at m/1000'/0'
    // =========================================================================
    test('scanSecret at m/1000h/0h is deterministic and matches regression vector', () {
      final scanSecretNode =
          root.derivePath("m/1000'/0'") as coin.DerivedSecretKey;
      final scanSecret = scanSecretNode.secretKey.bytes;

      // 256-bit private key.
      expect(scanSecret.length, equals(32));

      // Matches known regression vector.
      expect(
        _hex(scanSecret),
        equals(_expectedScanSecretHex),
        reason: 'scanSecret hex does not match regression vector',
      );

      // Determinism: derive a second time and compare.
      final scanSecretNode2 =
          root.derivePath("m/1000'/0'") as coin.DerivedSecretKey;
      expect(
        scanSecretNode2.secretKey.bytes,
        equals(scanSecret),
        reason: 'Second derivation of scanSecret differs from first',
      );
    });

    // =========================================================================
    // spendSecret at m/1000'/1'
    // =========================================================================
    test('spendSecret at m/1000h/1h is deterministic and matches regression vector', () {
      final spendSecretNode =
          root.derivePath("m/1000'/1'") as coin.DerivedSecretKey;
      final spendSecret = spendSecretNode.secretKey.bytes;

      // 256-bit private key.
      expect(spendSecret.length, equals(32));

      // Matches known regression vector.
      expect(
        _hex(spendSecret),
        equals(_expectedSpendSecretHex),
        reason: 'spendSecret hex does not match regression vector',
      );

      // Determinism: derive a second time and compare.
      final spendSecretNode2 =
          root.derivePath("m/1000'/1'") as coin.DerivedSecretKey;
      expect(
        spendSecretNode2.secretKey.bytes,
        equals(spendSecret),
        reason: 'Second derivation of spendSecret differs from first',
      );
    });

    // =========================================================================
    // spendSecret differs from scanSecret (different paths)
    // =========================================================================
    test('spendSecret and scanSecret are different (different paths)', () {
      final scanSecret =
          (root.derivePath("m/1000'/0'") as coin.DerivedSecretKey)
              .secretKey
              .bytes;
      final spendSecret =
          (root.derivePath("m/1000'/1'") as coin.DerivedSecretKey)
              .secretKey
              .bytes;

      expect(
        _hex(spendSecret),
        isNot(equals(_hex(scanSecret))),
        reason: 'scanSecret and spendSecret should differ (different paths)',
      );
    });

    // =========================================================================
    // spendPub is the compressed public key of spendSecret
    // =========================================================================
    test('spendPub is the public key of spendSecret (33 bytes compressed)', () {
      final spendSecretNode =
          root.derivePath("m/1000'/1'") as coin.DerivedSecretKey;
      final spendPub = spendSecretNode.publicKey.bytes;

      // Compressed public key is 33 bytes.
      expect(spendPub.length, equals(33));

      // First byte must be 0x02 or 0x03 (compressed point prefix).
      expect(
        spendPub[0] == 0x02 || spendPub[0] == 0x03,
        isTrue,
        reason: 'Compressed public key must start with 0x02 or 0x03',
      );

      // Matches known regression vector.
      expect(
        _hex(spendPub),
        equals(_expectedSpendPubHex),
        reason: 'spendPub hex does not match regression vector',
      );

      // Determinism: derive again and compare.
      final spendPub2 =
          (root.derivePath("m/1000'/1'") as coin.DerivedSecretKey)
              .publicKey
              .bytes;
      expect(
        spendPub2,
        equals(spendPub),
        reason: 'Second derivation of spendPub differs from first',
      );
    });

    // =========================================================================
    // MWEB paths use hardened derivation (apostrophe notation)
    // =========================================================================
    test('MWEB paths use hardened derivation', () {
      // Verify the hardened derivation by checking depth and index metadata.
      final scanNode =
          root.derivePath("m/1000'/0'") as coin.DerivedSecretKey;
      final spendNode =
          root.derivePath("m/1000'/1'") as coin.DerivedSecretKey;

      // Both should be at depth 2 (m / 1000' / 0' or 1').
      expect(scanNode.depth, equals(2));
      expect(spendNode.depth, equals(2));

      // Index should include the harden bit (0x80000000).
      const hardenBit = 0x80000000;
      expect(scanNode.index, equals(0 | hardenBit));
      expect(spendNode.index, equals(1 | hardenBit));
    });
  });
}
