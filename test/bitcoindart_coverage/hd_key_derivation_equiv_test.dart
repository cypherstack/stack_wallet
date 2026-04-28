// Regression tests for HD key derivation using coin library.
// Equivalence/regression tests for coin HD key derivation.
// against BIP-32 Test Vector 1 and known-correct expected values.
//
// Run with:
//   LD_LIBRARY_PATH=/path/to/libsecp256k1 dart test test/bitcoindart_coverage/hd_key_derivation_equiv_test.dart

import 'dart:typed_data';

import 'package:coin/coin.dart' as coin;
import 'package:test/test.dart';

// BIP-32 Test Vector 1 seed (16 bytes)
final _bip32Seed = Uint8List.fromList([
  0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
  0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
]);

// HD prefix version constants
const _btcMainPriv = 0x0488ADE4;
const _btcMainPub = 0x0488B21E;
const _btcTestPriv = 0x04358394;
const _btcTestPub = 0x043587CF;
const _dogePriv = 0x02FAC398;
const _dogePub = 0x02FACAFD;
const _partPriv = 0x8F1DAEB8;
const _partPub = 0x696E82D1;

// BIP-32 Test Vector 1 expected values (Bitcoin mainnet, chain m)
const _expectedXprv =
    'xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvN'
    'KmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi';
const _expectedXpub =
    'xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESF'
    'jqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8';

void main() {
  setUpAll(() async {
    await coin.VaultKeeper.initialize();
  });

  // =========================================================================
  // Group 1: fromSeed (BIP-32 Test Vector 1)
  // =========================================================================
  group('fromSeed regression', () {
    late coin.DerivedSecretKey coinMaster;

    setUp(() {
      coinMaster =
          coin.DerivedKey.fromSeed(_bip32Seed) as coin.DerivedSecretKey;
    });

    test('xprv encoding matches BIP-32 Test Vector 1', () {
      final coinXprv = coinMaster.encode(version: _btcMainPriv);
      expect(coinXprv, equals(_expectedXprv));
    });

    test('xpub encoding matches BIP-32 Test Vector 1', () {
      final coinXpub = coinMaster.toPublic().encode(version: _btcMainPub);
      expect(coinXpub, equals(_expectedXpub));
    });

    test('compressed public key is 33 bytes', () {
      expect(coinMaster.publicKey.bytes.length, equals(33));
    });

    test('chain code is 32 bytes', () {
      expect(coinMaster.chainCode.length, equals(32));
    });

    test('depth is 0 for master', () {
      expect(coinMaster.depth, equals(0));
    });

    test('index is 0 for master', () {
      expect(coinMaster.index, equals(0));
    });

    test('parentFingerprint is 0 for master', () {
      expect(coinMaster.parentFingerprint, equals(0));
    });
  });

  // =========================================================================
  // Group 2: derivePath (m/44'/0'/0'/0/0 - Bitcoin first receive)
  // =========================================================================
  group('derivePath regression', () {
    const path = "m/44'/0'/0'/0/0";

    late coin.DerivedSecretKey coinDerived;

    setUp(() {
      final coinMaster =
          coin.DerivedKey.fromSeed(_bip32Seed) as coin.DerivedSecretKey;
      coinDerived = coinMaster.derivePath(path) as coin.DerivedSecretKey;
    });

    test('derived depth is 5', () {
      expect(coinDerived.depth, equals(5));
    });

    test('derived compressed public key is 33 bytes', () {
      expect(coinDerived.publicKey.bytes.length, equals(33));
    });

    test('derived chain code is 32 bytes', () {
      expect(coinDerived.chainCode.length, equals(32));
    });

    test('derived xprv round-trip decode matches', () {
      final xprv = coinDerived.encode(version: _btcMainPriv);
      final decoded =
          coin.DerivedSecretKey.decode(xprv, expectedVersion: _btcMainPriv);
      expect(decoded.encode(version: _btcMainPriv), equals(xprv));
    });

    test('derived xpub round-trip decode matches', () {
      final xpub = coinDerived.toPublic().encode(version: _btcMainPub);
      final decoded =
          coin.DerivedPublicKey.decode(xpub, expectedVersion: _btcMainPub);
      expect(decoded.encode(version: _btcMainPub), equals(xpub));
    });
  });

  // =========================================================================
  // Group 3: Multi-coin HD prefix encoding
  // =========================================================================
  group('Multi-coin HD prefix encoding', () {
    late coin.DerivedSecretKey coinMaster;

    setUp(() {
      coinMaster =
          coin.DerivedKey.fromSeed(_bip32Seed) as coin.DerivedSecretKey;
    });

    test('Dogecoin xprv encoding starts with dgpv', () {
      final coinXprv = coinMaster.encode(version: _dogePriv);
      expect(coinXprv.startsWith('dgpv'), isTrue,
          reason: 'Dogecoin xprv should start with dgpv');
    });

    test('Dogecoin xpub encoding starts with dgub', () {
      final coinXpub = coinMaster.toPublic().encode(version: _dogePub);
      expect(coinXpub.startsWith('dgub'), isTrue,
          reason: 'Dogecoin xpub should start with dgub');
    });

    test('Dogecoin xprv round-trip decode produces same key bytes', () {
      final coinXprv = coinMaster.encode(version: _dogePriv);
      final decoded =
          coin.DerivedSecretKey.decode(coinXprv, expectedVersion: _dogePriv);
      final reEncoded = decoded.encode(version: _dogePriv);
      expect(reEncoded, equals(coinXprv));
    });

    test('Particl xprv round-trip decode produces same key bytes', () {
      final coinXprv = coinMaster.encode(version: _partPriv);
      final decoded =
          coin.DerivedSecretKey.decode(coinXprv, expectedVersion: _partPriv);
      final reEncoded = decoded.encode(version: _partPriv);
      expect(reEncoded, equals(coinXprv));
    });

    test('Bitcoin testnet xprv starts with tprv', () {
      final coinXprv = coinMaster.encode(version: _btcTestPriv);
      expect(coinXprv.startsWith('tprv'), isTrue);
    });

    test('Bitcoin testnet xpub starts with tpub', () {
      final coinXpub = coinMaster.toPublic().encode(version: _btcTestPub);
      expect(coinXpub.startsWith('tpub'), isTrue);
    });

    test('different version prefixes produce different encodings', () {
      final btcXprv = coinMaster.encode(version: _btcMainPriv);
      final dogeXprv = coinMaster.encode(version: _dogePriv);
      final partXprv = coinMaster.encode(version: _partPriv);
      expect(btcXprv, isNot(equals(dogeXprv)));
      expect(btcXprv, isNot(equals(partXprv)));
      expect(dogeXprv, isNot(equals(partXprv)));
    });
  });

  // =========================================================================
  // Group 4: View-only xpub derivation (decode xpub, derive child,
  //          compare against private-key-derived child public key)
  // =========================================================================
  group('View-only xpub derivation', () {
    const accountPath = "m/44'/0'/0'";

    late coin.DerivedSecretKey coinAccount;

    setUp(() {
      final coinMaster =
          coin.DerivedKey.fromSeed(_bip32Seed) as coin.DerivedSecretKey;
      coinAccount =
          coinMaster.derivePath(accountPath) as coin.DerivedSecretKey;
    });

    test('decode xpub and derive child 0/0 matches private derivation', () {
      final xpubStr = coinAccount.toPublic().encode(version: _btcMainPub);

      // Decode xpub (view-only)
      final decoded =
          coin.DerivedPublicKey.decode(xpubStr, expectedVersion: _btcMainPub);

      // Derive child 0/0 from decoded xpub (non-hardened)
      final viewOnlyChild = decoded.derive(0).derive(0);

      // Derive child 0/0 from private key (for comparison)
      final privateChild =
          coinAccount.derive(0).derive(0) as coin.DerivedSecretKey;

      // Public keys must match
      expect(
        viewOnlyChild.publicKey.bytes,
        equals(privateChild.publicKey.bytes),
      );
    });

    test('xpub round-trip preserves all fields', () {
      final coinPub = coinAccount.toPublic();
      final xpubStr = coinPub.encode(version: _btcMainPub);
      final decoded =
          coin.DerivedPublicKey.decode(xpubStr, expectedVersion: _btcMainPub);

      expect(decoded.depth, equals(coinPub.depth));
      expect(decoded.index, equals(coinPub.index));
      expect(decoded.parentFingerprint, equals(coinPub.parentFingerprint));
      expect(decoded.chainCode, equals(coinPub.chainCode));
      expect(decoded.publicKey.bytes, equals(coinPub.publicKey.bytes));
    });
  });
}
