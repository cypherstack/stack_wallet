// Coverage tests for bitcoindart NetworkType/Bip32Type API.
// Commented out: bitcoindart is no longer a direct dependency.
// Kept as historical reference for the original API patterns.
// See equivalence test files (*_equiv_test.dart) for the active coin regression suite.

/*
import 'package:bitcoindart/bitcoindart.dart' as bitcoindart;
import 'package:flutter_test/flutter_test.dart';

import 'test_vectors.dart';

void main() {
  group('Particl NetworkType', () {
    late bitcoindart.NetworkType particlNet;

    setUp(() {
      particlNet = bitcoindart.NetworkType(
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
    });

    test('has correct pubKeyHash', () {
      expect(particlNet.pubKeyHash, equals(0x38));
    });

    test('has correct scriptHash', () {
      expect(particlNet.scriptHash, equals(0x3c));
    });

    test('has correct wif', () {
      expect(particlNet.wif, equals(0x6c));
    });

    test('has correct bech32', () {
      expect(particlNet.bech32, equals('pw'));
    });

    test('has correct messagePrefix', () {
      expect(particlNet.messagePrefix, equals('\x18Bitcoin Signed Message:\n'));
    });

    test('has correct bip32 public HD prefix', () {
      expect(particlNet.bip32.public, equals(0x696e82d1));
    });

    test('has correct bip32 private HD prefix', () {
      expect(particlNet.bip32.private, equals(0x8f1daeb8));
    });
  });

  group('Firo NetworkType', () {
    late bitcoindart.NetworkType firoNet;

    setUp(() {
      firoNet = bitcoindart.NetworkType(
        messagePrefix: kFiroMessagePrefix,
        bech32: kFiroBech32,
        bip32: bitcoindart.Bip32Type(
          public: kFiroPubHD,
          private: kFiroPrivHD,
        ),
        pubKeyHash: kFiroP2pkh,
        scriptHash: kFiroP2sh,
        wif: kFiroWif,
      );
    });

    test('has correct pubKeyHash', () {
      expect(firoNet.pubKeyHash, equals(0x52));
    });

    test('has correct scriptHash', () {
      expect(firoNet.scriptHash, equals(0x07));
    });

    test('has correct wif', () {
      expect(firoNet.wif, equals(0xd2));
    });

    test('has correct bech32', () {
      expect(firoNet.bech32, equals('bc'));
    });

    test('has correct messagePrefix', () {
      expect(firoNet.messagePrefix, equals('\x16Zcoin Signed Message:\n'));
    });

    test('has correct bip32 public HD prefix', () {
      expect(firoNet.bip32.public, equals(0x0488b21e));
    });

    test('has correct bip32 private HD prefix', () {
      expect(firoNet.bip32.private, equals(0x0488ade4));
    });
  });

  group('Bitcoin mainnet NetworkType', () {
    test('has correct pubKeyHash', () {
      expect(bitcoindart.bitcoin.pubKeyHash, equals(0x00));
    });

    test('has correct scriptHash', () {
      expect(bitcoindart.bitcoin.scriptHash, equals(0x05));
    });

    test('has correct wif', () {
      expect(bitcoindart.bitcoin.wif, equals(0x80));
    });

    test('has correct bech32', () {
      expect(bitcoindart.bitcoin.bech32, equals('bc'));
    });

    test('has correct bip32 public HD prefix', () {
      expect(bitcoindart.bitcoin.bip32.public, equals(0x0488b21e));
    });

    test('has correct bip32 private HD prefix', () {
      expect(bitcoindart.bitcoin.bip32.private, equals(0x0488ade4));
    });
  });
}
*/
