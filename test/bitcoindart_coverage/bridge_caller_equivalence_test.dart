// Regression tests for bridge caller derivation paths.
// Regression tests for coin bridge-caller behaviour.
// against hardcoded expected values captured from coinlib reference run.
//
// Requires secp256k1 native library:
//   LD_LIBRARY_PATH=/home/user/src/stack_wallet/stack_wallet-refactor-bitcoindart/build/linux/x64/debug/bundle/lib flutter test test/bitcoindart_coverage/bridge_caller_equivalence_test.dart

import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:coin/coin.dart' as coin;
import 'package:flutter_test/flutter_test.dart';

/// Convert hex string to Uint8List.
Uint8List _unhex(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}

// Standard BIP39 test mnemonic (12-word "abandon" vector).
const _mnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon about';

// HD version prefixes.
const _btcPriv = 0x0488ADE4;
const _btcPub = 0x0488B21E;
const _ltcPriv = 0x019D9CFE; // Litecoin zpub
const _ltcPub = 0x019DA462;

// ============================================================================
// Hardcoded expected values (captured from coinlib reference run).
// ============================================================================

// --- Master fingerprint ---
const _expectedMasterFingerprint = '73c5da0a';

// --- MWEB paths ---
const _expectedMwebScanSecretHex =
    'e1520f2a744b77b15fab8f476241543328499a2ae88caeb5b65110caa8a73959';
const _expectedMwebSpendSecretHex =
    'ed8edcdab8e485bc0342e4c01441b759e8b5d5a9641cafe65cba63af09576021';
const _expectedMwebSpendPubHex =
    '0265ea63e132fa775931af5e5e8d03eb0a851d4a406d9bab18f6a2e1155df5698e';

// --- Spark paths ---
const _expectedSparkMainnetPrivHex =
    'a70a0fe03c7281763a291f4a9d536ef1088154df92bb563ea123533356ceb8bb';
const _expectedSparkTestnetPrivHex =
    'ee366a3139230d813c4225f5ac4db71612044be32b07b32446457e8ba3f8c706';

// --- Extended keys (Bitcoin m/84'/0'/0') ---
const _expectedBtcXpriv =
    'xprv9ybY78BftS5UGANki6oSifuQEjkpyAC8ZmBvBNTshQnCBcxnefjHS7buPMkkq'
    'hcRzmoGZ5bokx7GuyDAiktd5HemohAU4wV1ZPMDRmLpBMm';
const _expectedBtcXpub =
    'xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XyuvPEbvqA'
    'QY3rAPshWcMLoP2fMFMKHPJ4ZeZXYVUhLv1VMrjPC7PW6V';

// --- Extended keys (Litecoin m/84'/2'/0' with zpub prefixes) ---
const _expectedLtcXpriv =
    'Ltpv77z3LHgiTumhjPwxY5THUn11RJvRPQU6yK8iFN9TCUnfvox2ixQQGHmuNx5Bo'
    '1yGQWrSbo87JgF1CKVQ28zddVZ15xgNeL4QnHXSKrXfbih';
const _expectedLtcXpub =
    'Ltub2ZANw57Fi4JfMGenngwfZMqDrsccTf2m3qEjvLuk8faGXB973sSqGttAdKBvGS'
    'CLG9DXh2yxaUB9qpwQUe2zCCtrZPhjxGuMAWqL6F7Xrpd';

// --- CashFusion/BCH path (m/44'/145'/0'/0/0) ---
const _expectedBchPrivHex =
    '28e9c4f61f735a059af93e0d9aca0b640126c827975841ad83723ccef295e659';

void main() {
  late coin.DerivedSecretKey coinMaster;

  setUpAll(() async {
    await coin.VaultKeeper.initialize();

    final seed = bip39.mnemonicToSeed(_mnemonic);
    coinMaster = coin.DerivedKey.fromSeed(seed) as coin.DerivedSecretKey;
  });

  // ===========================================================================
  // Group 1: MWEB paths (mweb_interface.dart)
  // Paths: m/1000'/0' (scanSecret), m/1000'/1' (spendSecret + spendPub)
  // ===========================================================================
  group('MWEB derivation paths', () {
    test('m/1000\'/0\' scanSecret private key bytes', () {
      final coinNode =
          coinMaster.derivePath("m/1000'/0'") as coin.DerivedSecretKey;
      final expected = _unhex(_expectedMwebScanSecretHex);

      expect(
        Uint8List.fromList(coinNode.secretKey.bytes),
        equals(expected),
      );
    });

    test('m/1000\'/1\' spendSecret private key bytes', () {
      final coinNode =
          coinMaster.derivePath("m/1000'/1'") as coin.DerivedSecretKey;
      final expected = _unhex(_expectedMwebSpendSecretHex);

      expect(
        Uint8List.fromList(coinNode.secretKey.bytes),
        equals(expected),
      );
    });

    test('m/1000\'/1\' spendPub public key bytes', () {
      final coinNode =
          coinMaster.derivePath("m/1000'/1'") as coin.DerivedSecretKey;
      final expected = _unhex(_expectedMwebSpendPubHex);

      expect(
        Uint8List.fromList(coinNode.publicKey.bytes),
        equals(expected),
      );
    });
  });

  // ===========================================================================
  // Group 2: Spark derivation paths (spark_interface.dart)
  // Firo mainnet: m/44'/136'/0'/1, testnet: m/44'/1'/0'/1
  // (kDefaultSparkIndex = 1)
  // ===========================================================================
  group('Spark derivation paths', () {
    test('m/44\'/136\'/0\'/1 mainnet spark private key bytes', () {
      final coinNode =
          coinMaster.derivePath("m/44'/136'/0'/1") as coin.DerivedSecretKey;
      final expected = _unhex(_expectedSparkMainnetPrivHex);

      expect(
        Uint8List.fromList(coinNode.secretKey.bytes),
        equals(expected),
      );
    });

    test('m/44\'/1\'/0\'/1 testnet spark private key bytes', () {
      final coinNode =
          coinMaster.derivePath("m/44'/1'/0'/1") as coin.DerivedSecretKey;
      final expected = _unhex(_expectedSparkTestnetPrivHex);

      expect(
        Uint8List.fromList(coinNode.secretKey.bytes),
        equals(expected),
      );
    });
  });

  // ===========================================================================
  // Group 3: Extended keys (extended_keys_interface.dart)
  // Fingerprint, xpriv/xpub encoding with Bitcoin + Litecoin prefixes
  // ===========================================================================
  group('Extended keys encoding', () {
    test('master fingerprint matches', () {
      final coinFp = coinMaster.fingerprint.toRadixString(16);

      expect(
        coinFp,
        equals(_expectedMasterFingerprint),
      );
    });

    test('Bitcoin m/84\'/0\'/0\' xpriv encoding', () {
      final coinNode =
          coinMaster.derivePath("m/84'/0'/0'") as coin.DerivedSecretKey;

      final coinXpriv = coinNode.encode(version: _btcPriv);

      expect(
        coinXpriv,
        equals(_expectedBtcXpriv),
      );
    });

    test('Bitcoin m/84\'/0\'/0\' xpub encoding via toPublic()', () {
      final coinNode =
          coinMaster.derivePath("m/84'/0'/0'") as coin.DerivedSecretKey;

      final coinXpub = coinNode.toPublic().encode(version: _btcPub);

      expect(
        coinXpub,
        equals(_expectedBtcXpub),
      );
    });

    test('Litecoin m/84\'/2\'/0\' xpriv encoding with zpub prefix', () {
      final coinNode =
          coinMaster.derivePath("m/84'/2'/0'") as coin.DerivedSecretKey;

      final coinXpriv = coinNode.encode(version: _ltcPriv);

      expect(
        coinXpriv,
        equals(_expectedLtcXpriv),
      );
    });

    test('Litecoin m/84\'/2\'/0\' xpub encoding via toPublic()', () {
      final coinNode =
          coinMaster.derivePath("m/84'/2'/0'") as coin.DerivedSecretKey;

      final coinXpub = coinNode.toPublic().encode(version: _ltcPub);

      expect(
        coinXpub,
        equals(_expectedLtcXpub),
      );
    });
  });

  // ===========================================================================
  // Group 4: CashFusion/BCH derivation (cash_fusion_interface.dart)
  // BIP44 path: m/44'/145'/0'/0/0
  // ===========================================================================
  group('CashFusion/BCH derivation paths', () {
    test('m/44\'/145\'/0\'/0/0 BCH private key bytes', () {
      final coinNode =
          coinMaster.derivePath("m/44'/145'/0'/0/0") as coin.DerivedSecretKey;
      final expected = _unhex(_expectedBchPrivHex);

      expect(
        Uint8List.fromList(coinNode.secretKey.bytes),
        equals(expected),
      );
    });
  });
}
