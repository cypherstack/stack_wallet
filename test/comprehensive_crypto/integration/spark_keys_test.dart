// Spark key derivation tests.
// Verifies that the coin library produces deterministic keys at the exact
// derivation paths used by spark_interface.dart:
//   Mainnet: m/44'/136'/0'/1  (kDefaultSparkIndex = 1)
//   Testnet: m/44'/1'/0'/1
//
// Requires secp256k1 native library:
//   LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib flutter test test/comprehensive_crypto/integration/spark_keys_test.dart

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
const _expectedSparkMainnetPrivHex =
    'a70a0fe03c7281763a291f4a9d536ef1088154df92bb563ea123533356ceb8bb';
const _expectedSparkTestnetPrivHex =
    'ee366a3139230d813c4225f5ac4db71612044be32b07b32446457e8ba3f8c706';

void main() {
  late coin.DerivedSecretKey root;

  setUpAll(() async {
    await coin.VaultKeeper.initialize();

    final seed = bip39.mnemonicToSeed(_mnemonic);
    root = coin.DerivedKey.fromSeed(seed) as coin.DerivedSecretKey;
  });

  group('Spark key derivation', () {
    // =========================================================================
    // Mainnet: m/44'/136'/0'/1
    // =========================================================================
    test('Spark mainnet key at m/44h/136h/0h/1 is deterministic', () {
      final sparkNode =
          root.derivePath("m/44'/136'/0'/1") as coin.DerivedSecretKey;
      final privateKey = sparkNode.secretKey.bytes;

      // 256-bit private key.
      expect(privateKey.length, equals(32));

      // Matches known regression vector.
      expect(
        _hex(privateKey),
        equals(_expectedSparkMainnetPrivHex),
        reason: 'Spark mainnet private key does not match regression vector',
      );

      // Determinism: derive a second time and compare.
      final sparkNode2 =
          root.derivePath("m/44'/136'/0'/1") as coin.DerivedSecretKey;
      expect(
        sparkNode2.secretKey.bytes,
        equals(privateKey),
        reason: 'Second derivation of Spark mainnet key differs from first',
      );
    });

    // =========================================================================
    // Testnet: m/44'/1'/0'/1
    // =========================================================================
    test('Spark testnet key at m/44h/1h/0h/1 is deterministic', () {
      final sparkTestNode =
          root.derivePath("m/44'/1'/0'/1") as coin.DerivedSecretKey;
      final privateKey = sparkTestNode.secretKey.bytes;

      // 256-bit private key.
      expect(privateKey.length, equals(32));

      // Matches known regression vector.
      expect(
        _hex(privateKey),
        equals(_expectedSparkTestnetPrivHex),
        reason: 'Spark testnet private key does not match regression vector',
      );

      // Determinism: derive a second time and compare.
      final sparkTestNode2 =
          root.derivePath("m/44'/1'/0'/1") as coin.DerivedSecretKey;
      expect(
        sparkTestNode2.secretKey.bytes,
        equals(privateKey),
        reason: 'Second derivation of Spark testnet key differs from first',
      );
    });

    // =========================================================================
    // Mainnet and testnet keys differ
    // =========================================================================
    test('Spark mainnet and testnet keys differ', () {
      final mainnetKey =
          (root.derivePath("m/44'/136'/0'/1") as coin.DerivedSecretKey)
              .secretKey
              .bytes;
      final testnetKey =
          (root.derivePath("m/44'/1'/0'/1") as coin.DerivedSecretKey)
              .secretKey
              .bytes;

      expect(
        _hex(mainnetKey),
        isNot(equals(_hex(testnetKey))),
        reason: 'Mainnet and testnet keys should differ (different coinType)',
      );
    });

    // =========================================================================
    // Spark key public key derivation
    // =========================================================================
    test('Spark key public key derivation is deterministic', () {
      final sparkNode =
          root.derivePath("m/44'/136'/0'/1") as coin.DerivedSecretKey;
      final pubKey = sparkNode.publicKey.bytes;

      // Compressed public key is 33 bytes.
      expect(pubKey.length, equals(33));

      // First byte must be 0x02 or 0x03 (compressed point prefix).
      expect(
        pubKey[0] == 0x02 || pubKey[0] == 0x03,
        isTrue,
        reason: 'Compressed public key must start with 0x02 or 0x03',
      );

      // Determinism.
      final pubKey2 =
          (root.derivePath("m/44'/136'/0'/1") as coin.DerivedSecretKey)
              .publicKey
              .bytes;
      expect(pubKey2, equals(pubKey));
    });

    // =========================================================================
    // Path depth metadata
    // =========================================================================
    test('Spark path depth is correct (4 levels below master)', () {
      final sparkNode =
          root.derivePath("m/44'/136'/0'/1") as coin.DerivedSecretKey;

      // m / 44' / 136' / 0' / 1 = depth 4
      expect(sparkNode.depth, equals(4));

      // Last component is non-hardened index 1.
      expect(sparkNode.index, equals(1));
    });
  });
}
