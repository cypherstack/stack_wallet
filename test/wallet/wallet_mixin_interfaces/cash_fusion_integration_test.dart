// Run with: LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib flutter test test/wallet/wallet_mixin_interfaces/cash_fusion_integration_test.dart

import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:coin/coin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    await VaultKeeper.initialize();
  });

  group('CashFusion coin API integration', () {
    late DerivedSecretKey root;

    setUp(() {
      final mnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon '
          'abandon abandon abandon about';
      final seed = bip39.mnemonicToSeed(mnemonic);
      root = DerivedKey.fromSeed(seed) as DerivedSecretKey;
    });

    test('derives valid 32-byte private key at BCH path', () {
      final derived =
          root.derivePath("m/44'/145'/0'/0/0") as DerivedSecretKey;
      expect(derived.secretKey.bytes.length, equals(32));
    });

    test('derives valid 33-byte compressed public key at BCH path', () {
      final derived =
          root.derivePath("m/44'/145'/0'/0/0") as DerivedSecretKey;
      expect(derived.publicKey.bytes.length, equals(33));
      // Compressed pubkey starts with 0x02 or 0x03
      expect(derived.publicKey.bytes[0], anyOf(equals(0x02), equals(0x03)));
    });

    test('sign and verify roundtrip with derived key', () {
      final derived =
          root.derivePath("m/44'/145'/0'/0/0") as DerivedSecretKey;
      final message = Uint8List.fromList(List.generate(32, (i) => i));
      // Use coin EcdsaSig to sign and verify
      final sig = EcdsaSig.sign(message, derived.secretKey.bytes);
      expect(sig.bytes.length, equals(64)); // compact signature
      final valid = sig.verify(message, derived.publicKey.bytes);
      expect(valid, isTrue);
    });

    test('signature does not verify with wrong public key', () {
      final derived0 =
          root.derivePath("m/44'/145'/0'/0/0") as DerivedSecretKey;
      final derived1 =
          root.derivePath("m/44'/145'/0'/0/1") as DerivedSecretKey;
      final message = Uint8List.fromList(List.generate(32, (i) => i));
      final sig = EcdsaSig.sign(message, derived0.secretKey.bytes);
      final valid = sig.verify(message, derived1.publicKey.bytes);
      expect(valid, isFalse);
    });

    test('multiple BCH derivation paths produce unique keys', () {
      final paths = [
        "m/44'/145'/0'/0/0",
        "m/44'/145'/0'/0/1",
        "m/44'/145'/0'/1/0",
      ];
      final keys = paths
          .map(
            (p) => (root.derivePath(p) as DerivedSecretKey).secretKey.bytes,
          )
          .toList();
      // All keys should be unique
      expect(keys[0], isNot(equals(keys[1])));
      expect(keys[0], isNot(equals(keys[2])));
      expect(keys[1], isNot(equals(keys[2])));
    });

    test('derived keys from change path differ from receive path', () {
      final receive =
          root.derivePath("m/44'/145'/0'/0/0") as DerivedSecretKey;
      final change =
          root.derivePath("m/44'/145'/0'/1/0") as DerivedSecretKey;
      expect(receive.secretKey.bytes, isNot(equals(change.secretKey.bytes)));
      expect(
        receive.publicKey.bytes,
        isNot(equals(change.publicKey.bytes)),
      );
    });
  });
}
