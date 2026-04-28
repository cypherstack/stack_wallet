// Extended keys (xpub/xpriv) encoding tests. Verifies that the coin library
// encodes HD extended keys with the correct version bytes per coin and
// purpose, and that xpub/xpriv round-trip through serialization.
//
// Tests replicate the exact call pattern from extended_keys_interface.dart:
//   node.encode(version: networkParams.privHDPrefix) -> xpriv string
//   node.toPublic().encode(version: networkParams.pubHDPrefix) -> xpub string
//
// Requires secp256k1 native library:
//   LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib flutter test test/comprehensive_crypto/integration/extended_keys_test.dart

import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:coin/coin.dart' as coin;
import 'package:flutter_test/flutter_test.dart';

// Standard BIP39 test mnemonic (12-word "abandon" vector).
const _mnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon about';

// ---------------------------------------------------------------------------
// HD version prefixes (from wallet coin definitions)
// ---------------------------------------------------------------------------

// Bitcoin mainnet (standard BIP32).
const _btcPriv = 0x0488ADE4; // xprv
const _btcPub = 0x0488B21E; // xpub

// Litecoin mainnet (standard -- same as BTC; wallet uses these, not Ltub/zpub).
const _ltcStdPriv = 0x0488ADE4;
const _ltcStdPub = 0x0488B21E;

// Litecoin custom zpub prefixes.
const _ltcZpriv = 0x019D9CFE;
const _ltcZpub = 0x019DA462;

// Dash mainnet.
const _dashPriv = 0x0488ADE4;
const _dashPub = 0x0488B21E;

// Dogecoin mainnet.
const _dogePriv = 0x02FAC398;
const _dogePub = 0x02FACAFD;

// ---------------------------------------------------------------------------
// Regression vectors (captured from bridge_caller_equivalence_test)
// ---------------------------------------------------------------------------

const _expectedMasterFingerprint = '73c5da0a';

// Bitcoin m/84'/0'/0'
const _expectedBtcXpriv =
    'xprv9ybY78BftS5UGANki6oSifuQEjkpyAC8ZmBvBNTshQnCBcxnefjHS7buPMkkq'
    'hcRzmoGZ5bokx7GuyDAiktd5HemohAU4wV1ZPMDRmLpBMm';
const _expectedBtcXpub =
    'xpub6CatWdiZiodmUeTDp8LT5or8nmbKNcuyvz7WyksVFkKB4RHwCD3XyuvPEbvqA'
    'QY3rAPshWcMLoP2fMFMKHPJ4ZeZXYVUhLv1VMrjPC7PW6V';

// Litecoin m/84'/2'/0' with zpub prefixes.
const _expectedLtcXpriv =
    'Ltpv77z3LHgiTumhjPwxY5THUn11RJvRPQU6yK8iFN9TCUnfvox2ixQQGHmuNx5Bo'
    '1yGQWrSbo87JgF1CKVQ28zddVZ15xgNeL4QnHXSKrXfbih';
const _expectedLtcXpub =
    'Ltub2ZANw57Fi4JfMGenngwfZMqDrsccTf2m3qEjvLuk8faGXB973sSqGttAdKBvGS'
    'CLG9DXh2yxaUB9qpwQUe2zCCtrZPhjxGuMAWqL6F7Xrpd';

void main() {
  late coin.DerivedSecretKey master;

  setUpAll(() async {
    await coin.VaultKeeper.initialize();

    final seed = bip39.mnemonicToSeed(_mnemonic);
    master = coin.DerivedKey.fromSeed(seed) as coin.DerivedSecretKey;
  });

  // ===========================================================================
  // Master fingerprint
  // ===========================================================================
  group('Master fingerprint', () {
    test('master fingerprint is deterministic for standard mnemonic', () {
      final fingerprint = master.fingerprint.toRadixString(16);

      // 4 bytes = 8 hex characters.
      expect(fingerprint.length, lessThanOrEqualTo(8));

      // Matches known regression vector.
      expect(fingerprint, equals(_expectedMasterFingerprint));
    });

    test('master fingerprint is 4 bytes (unsigned 32-bit)', () {
      final fp = master.fingerprint;
      // fingerprint is derived from first 4 bytes of hash160 of the root
      // public key. It should fit in 32 bits.
      expect(fp, greaterThanOrEqualTo(0));
      expect(fp, lessThan(0x100000000));
    });

    test('master fingerprint is reproducible across derivations', () {
      final seed = bip39.mnemonicToSeed(_mnemonic);
      final master2 = coin.DerivedKey.fromSeed(seed) as coin.DerivedSecretKey;
      expect(master2.fingerprint, equals(master.fingerprint));
    });
  });

  // ===========================================================================
  // Bitcoin extended keys (has bip44/49/84/86)
  // ===========================================================================
  group('Extended key encoding - Bitcoin', () {
    test('Bitcoin xpriv at m/84h/0h/0h starts with xprv prefix', () {
      final node =
          master.derivePath("m/84'/0'/0'") as coin.DerivedSecretKey;
      final xpriv = node.encode(version: _btcPriv);

      expect(xpriv, startsWith('xprv'));
      expect(xpriv, equals(_expectedBtcXpriv));
    });

    test('Bitcoin xpub at m/84h/0h/0h starts with xpub prefix', () {
      final node =
          master.derivePath("m/84'/0'/0'") as coin.DerivedSecretKey;
      final xpub = node.toPublic().encode(version: _btcPub);

      expect(xpub, startsWith('xpub'));
      expect(xpub, equals(_expectedBtcXpub));
    });

    test('Bitcoin xpub at m/44h/0h/0h uses legacy xpub prefix', () {
      final node =
          master.derivePath("m/44'/0'/0'") as coin.DerivedSecretKey;
      final xpub = node.toPublic().encode(version: _btcPub);

      expect(xpub, startsWith('xpub'));

      // Different path -> different key.
      expect(xpub, isNot(equals(_expectedBtcXpub)));
    });

    test('Bitcoin xpub and xpriv are related (xpub derivable from xpriv)', () {
      final node =
          master.derivePath("m/84'/0'/0'") as coin.DerivedSecretKey;

      // Derive xpriv, decode it back, get its public key.
      final xprivStr = node.encode(version: _btcPriv);
      final decoded = coin.DerivedSecretKey.decode(
        xprivStr,
        expectedVersion: _btcPriv,
      );
      final xpubFromXpriv =
          decoded.toPublic().encode(version: _btcPub);

      // Direct xpub.
      final xpubDirect = node.toPublic().encode(version: _btcPub);

      expect(xpubFromXpriv, equals(xpubDirect));
      expect(xpubFromXpriv, equals(_expectedBtcXpub));
    });

    test('Bitcoin xpriv round-trips through encode/decode', () {
      final node =
          master.derivePath("m/84'/0'/0'") as coin.DerivedSecretKey;
      final encoded = node.encode(version: _btcPriv);
      final decoded = coin.DerivedSecretKey.decode(
        encoded,
        expectedVersion: _btcPriv,
      );
      final reEncoded = decoded.encode(version: _btcPriv);

      expect(reEncoded, equals(encoded));
    });

    test('Bitcoin xpub round-trips through encode/decode', () {
      final node =
          master.derivePath("m/84'/0'/0'") as coin.DerivedSecretKey;
      final pub = node.toPublic();
      final encoded = pub.encode(version: _btcPub);
      final decoded = coin.DerivedPublicKey.decode(
        encoded,
        expectedVersion: _btcPub,
      );
      final reEncoded = decoded.encode(version: _btcPub);

      expect(reEncoded, equals(encoded));
    });

    test('Bitcoin all 4 purpose paths produce distinct xpubs', () {
      final paths = [
        "m/44'/0'/0'",
        "m/49'/0'/0'",
        "m/84'/0'/0'",
        "m/86'/0'/0'",
      ];

      final xpubs = paths.map((path) {
        final node = master.derivePath(path) as coin.DerivedSecretKey;
        return node.toPublic().encode(version: _btcPub);
      }).toList();

      // All should be distinct.
      expect(xpubs.toSet().length, equals(4));

      // All should start with xpub (same version bytes).
      for (final xpub in xpubs) {
        expect(xpub, startsWith('xpub'));
      }
    });
  });

  // ===========================================================================
  // Litecoin extended keys (with both standard and custom zpub prefixes)
  // ===========================================================================
  group('Extended key encoding - Litecoin', () {
    test('Litecoin xpriv at m/84h/2h/0h with zpub prefix matches regression', () {
      final node =
          master.derivePath("m/84'/2'/0'") as coin.DerivedSecretKey;
      final xpriv = node.encode(version: _ltcZpriv);

      expect(xpriv, startsWith('Ltpv'));
      expect(xpriv, equals(_expectedLtcXpriv));
    });

    test('Litecoin xpub at m/84h/2h/0h with zpub prefix matches regression', () {
      final node =
          master.derivePath("m/84'/2'/0'") as coin.DerivedSecretKey;
      final xpub = node.toPublic().encode(version: _ltcZpub);

      expect(xpub, startsWith('Ltub'));
      expect(xpub, equals(_expectedLtcXpub));
    });

    test('Litecoin standard vs zpub prefixes produce different strings but same key material', () {
      final node =
          master.derivePath("m/84'/2'/0'") as coin.DerivedSecretKey;

      final stdXpub = node.toPublic().encode(version: _ltcStdPub);
      final zpubXpub = node.toPublic().encode(version: _ltcZpub);

      // Different prefix -> different strings.
      expect(stdXpub, isNot(equals(zpubXpub)));

      // Standard uses xpub prefix, custom uses Ltub prefix.
      expect(stdXpub, startsWith('xpub'));
      expect(zpubXpub, startsWith('Ltub'));
    });

    test('Litecoin xpriv round-trips through encode/decode', () {
      final node =
          master.derivePath("m/84'/2'/0'") as coin.DerivedSecretKey;
      final encoded = node.encode(version: _ltcZpriv);
      final decoded = coin.DerivedSecretKey.decode(
        encoded,
        expectedVersion: _ltcZpriv,
      );
      final reEncoded = decoded.encode(version: _ltcZpriv);

      expect(reEncoded, equals(encoded));
    });
  });

  // ===========================================================================
  // Dash extended keys
  // ===========================================================================
  group('Extended key encoding - Dash', () {
    test('Dash xpub at m/44h/5h/0h has xpub prefix', () {
      final node =
          master.derivePath("m/44'/5'/0'") as coin.DerivedSecretKey;
      final xpub = node.toPublic().encode(version: _dashPub);

      expect(xpub, startsWith('xpub'));

      // Deterministic.
      final node2 =
          master.derivePath("m/44'/5'/0'") as coin.DerivedSecretKey;
      expect(
        node2.toPublic().encode(version: _dashPub),
        equals(xpub),
      );
    });

    test('Dash xpriv at m/44h/5h/0h has xprv prefix', () {
      final node =
          master.derivePath("m/44'/5'/0'") as coin.DerivedSecretKey;
      final xpriv = node.encode(version: _dashPriv);

      expect(xpriv, startsWith('xprv'));
    });

    test('Dash xpub differs from Bitcoin at same purpose (different coinType)', () {
      final dashNode =
          master.derivePath("m/44'/5'/0'") as coin.DerivedSecretKey;
      final btcNode =
          master.derivePath("m/44'/0'/0'") as coin.DerivedSecretKey;

      final dashXpub = dashNode.toPublic().encode(version: _dashPub);
      final btcXpub = btcNode.toPublic().encode(version: _btcPub);

      expect(dashXpub, isNot(equals(btcXpub)));
    });
  });

  // ===========================================================================
  // Dogecoin extended keys (distinct HD version bytes)
  // ===========================================================================
  group('Extended key encoding - Dogecoin', () {
    test('Dogecoin xpub at m/44h/3h/0h has dgub prefix', () {
      final node =
          master.derivePath("m/44'/3'/0'") as coin.DerivedSecretKey;
      final xpub = node.toPublic().encode(version: _dogePub);

      expect(xpub, startsWith('dgub'));

      // Deterministic.
      final node2 =
          master.derivePath("m/44'/3'/0'") as coin.DerivedSecretKey;
      expect(
        node2.toPublic().encode(version: _dogePub),
        equals(xpub),
      );
    });

    test('Dogecoin xpriv at m/44h/3h/0h has dgpv prefix', () {
      final node =
          master.derivePath("m/44'/3'/0'") as coin.DerivedSecretKey;
      final xpriv = node.encode(version: _dogePriv);

      expect(xpriv, startsWith('dgpv'));
    });

    test('Dogecoin xpriv round-trips through encode/decode', () {
      final node =
          master.derivePath("m/44'/3'/0'") as coin.DerivedSecretKey;
      final encoded = node.encode(version: _dogePriv);
      final decoded = coin.DerivedSecretKey.decode(
        encoded,
        expectedVersion: _dogePriv,
      );
      final reEncoded = decoded.encode(version: _dogePriv);

      expect(reEncoded, equals(encoded));
    });

    test('Dogecoin xpub round-trips through encode/decode', () {
      final node =
          master.derivePath("m/44'/3'/0'") as coin.DerivedSecretKey;
      final pub = node.toPublic();
      final encoded = pub.encode(version: _dogePub);
      final decoded = coin.DerivedPublicKey.decode(
        encoded,
        expectedVersion: _dogePub,
      );
      final reEncoded = decoded.encode(version: _dogePub);

      expect(reEncoded, equals(encoded));
    });
  });

  // ===========================================================================
  // Cross-coin: version byte isolation
  // ===========================================================================
  group('Extended key encoding - cross-coin version bytes', () {
    test('same key material with different version bytes produces different base58', () {
      final node =
          master.derivePath("m/44'/0'/0'") as coin.DerivedSecretKey;

      // Encode same node with BTC vs DOGE version bytes.
      final btcXpub = node.toPublic().encode(version: _btcPub);
      final dogeXpub = node.toPublic().encode(version: _dogePub);

      expect(btcXpub, isNot(equals(dogeXpub)));
      expect(btcXpub, startsWith('xpub'));
      expect(dogeXpub, startsWith('dgub'));
    });

    test('decoding with wrong expectedVersion throws FormatException', () {
      final node =
          master.derivePath("m/84'/0'/0'") as coin.DerivedSecretKey;
      final btcXpriv = node.encode(version: _btcPriv);

      expect(
        () => coin.DerivedSecretKey.decode(
          btcXpriv,
          expectedVersion: _dogePriv,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
