// Equivalence tests for coin library enhancements (COIN-01 through COIN-04).
//
// Requires secp256k1 native library:
//   LD_LIBRARY_PATH=/path/to/libsecp256k1.so dart test test/bitcoindart_coverage/coin_enhancements_equiv_test.dart

import 'dart:typed_data';

import 'package:coin/coin.dart';
import 'package:flutter_test/flutter_test.dart';

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

// BIP-32 Test Vector 1 expected xpub/xprv for Bitcoin mainnet (chain m)
const _expectedXprv =
    'xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvN'
    'KmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi';
const _expectedXpub =
    'xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESF'
    'jqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8';

// Message prefix constants
const _bitcoinPrefix = '\x18Bitcoin Signed Message:\n';
const _litecoinPrefix = '\x19Litecoin Signed Message:\n';
const _dogecoinPrefix = '\x19Dogecoin Signed Message:\n';
const _dashPrefix = '\x18Dash Signed Message:\n';
const _namecoinPrefix = '\x19Namecoin Signed Message:\n';
const _firoPrefix = '\x16Zcoin Signed Message:\n';

void main() {
  setUpAll(() async {
    await VaultKeeper.initialize();
  });

  // =========================================================================
  // Group 1: HD Prefix Encode/Decode Round-Trip (COIN-01 + COIN-02)
  // =========================================================================
  group('HD prefix encode/decode round-trip', () {
    late DerivedSecretKey masterSecret;
    late DerivedPublicKey masterPublic;

    setUp(() {
      final master = DerivedKey.fromSeed(_bip32Seed) as DerivedSecretKey;
      masterSecret = master;
      masterPublic = DerivedPublicKey(
        publicKey: master.publicKey,
        chainCode: master.chainCode,
        depth: master.depth,
        index: master.index,
        parentFingerprint: master.parentFingerprint,
      );
    });

    test('Bitcoin mainnet xprv matches BIP-32 Test Vector 1', () {
      final encoded = masterSecret.encode(version: _btcMainPriv);
      expect(encoded, equals(_expectedXprv));
    });

    test('Bitcoin mainnet xpub matches BIP-32 Test Vector 1', () {
      final encoded = masterPublic.encode(version: _btcMainPub);
      expect(encoded, equals(_expectedXpub));
    });

    test('Bitcoin mainnet xprv encode->decode->encode round-trip', () {
      final encoded = masterSecret.encode(version: _btcMainPriv);
      final decoded = DerivedSecretKey.decode(
        encoded,
        expectedVersion: _btcMainPriv,
      );
      final reEncoded = decoded.encode(version: _btcMainPriv);
      expect(reEncoded, equals(encoded));
    });

    test('Bitcoin mainnet xpub encode->decode->encode round-trip', () {
      final encoded = masterPublic.encode(version: _btcMainPub);
      final decoded = DerivedPublicKey.decode(
        encoded,
        expectedVersion: _btcMainPub,
      );
      final reEncoded = decoded.encode(version: _btcMainPub);
      expect(reEncoded, equals(encoded));
    });

    test('Bitcoin testnet xprv encode->decode round-trip', () {
      final encoded = masterSecret.encode(version: _btcTestPriv);
      expect(encoded.startsWith('tprv'), isTrue);
      final decoded = DerivedSecretKey.decode(
        encoded,
        expectedVersion: _btcTestPriv,
      );
      final reEncoded = decoded.encode(version: _btcTestPriv);
      expect(reEncoded, equals(encoded));
    });

    test('Bitcoin testnet xpub encode->decode round-trip', () {
      final encoded = masterPublic.encode(version: _btcTestPub);
      expect(encoded.startsWith('tpub'), isTrue);
      final decoded = DerivedPublicKey.decode(
        encoded,
        expectedVersion: _btcTestPub,
      );
      final reEncoded = decoded.encode(version: _btcTestPub);
      expect(reEncoded, equals(encoded));
    });

    test('Dogecoin xprv encode->decode round-trip', () {
      final encoded = masterSecret.encode(version: _dogePriv);
      final decoded = DerivedSecretKey.decode(
        encoded,
        expectedVersion: _dogePriv,
      );
      final reEncoded = decoded.encode(version: _dogePriv);
      expect(reEncoded, equals(encoded));
    });

    test('Dogecoin xpub encode->decode round-trip', () {
      final encoded = masterPublic.encode(version: _dogePub);
      final decoded = DerivedPublicKey.decode(
        encoded,
        expectedVersion: _dogePub,
      );
      final reEncoded = decoded.encode(version: _dogePub);
      expect(reEncoded, equals(encoded));
    });

    test('Particl xprv encode->decode round-trip', () {
      final encoded = masterSecret.encode(version: _partPriv);
      final decoded = DerivedSecretKey.decode(
        encoded,
        expectedVersion: _partPriv,
      );
      final reEncoded = decoded.encode(version: _partPriv);
      expect(reEncoded, equals(encoded));
    });

    test('Particl xpub encode->decode round-trip', () {
      final encoded = masterPublic.encode(version: _partPub);
      final decoded = DerivedPublicKey.decode(
        encoded,
        expectedVersion: _partPub,
      );
      final reEncoded = decoded.encode(version: _partPub);
      expect(reEncoded, equals(encoded));
    });

    test('different version prefixes produce different base58 strings', () {
      final btcXprv = masterSecret.encode(version: _btcMainPriv);
      final dogeXprv = masterSecret.encode(version: _dogePriv);
      final partXprv = masterSecret.encode(version: _partPriv);
      expect(btcXprv, isNot(equals(dogeXprv)));
      expect(btcXprv, isNot(equals(partXprv)));
      expect(dogeXprv, isNot(equals(partXprv)));
    });
  });

  // =========================================================================
  // Group 2: DerivedKey.decode version validation (COIN-02)
  // =========================================================================
  group('DerivedKey.decode version validation', () {
    late String btcXprv;
    late String btcXpub;

    setUp(() {
      final master = DerivedKey.fromSeed(_bip32Seed) as DerivedSecretKey;
      btcXprv = master.encode(version: _btcMainPriv);
      btcXpub = DerivedPublicKey(
        publicKey: master.publicKey,
        chainCode: master.chainCode,
        depth: master.depth,
        index: master.index,
        parentFingerprint: master.parentFingerprint,
      ).encode(version: _btcMainPub);
    });

    test(
        'DerivedSecretKey.decode throws FormatException on version mismatch',
        () {
      expect(
        () => DerivedSecretKey.decode(btcXprv, expectedVersion: _dogePriv),
        throwsA(isA<FormatException>()),
      );
    });

    test(
        'DerivedPublicKey.decode throws FormatException on version mismatch',
        () {
      expect(
        () => DerivedPublicKey.decode(btcXpub, expectedVersion: _dogePub),
        throwsA(isA<FormatException>()),
      );
    });

    test('DerivedSecretKey.decode without expectedVersion succeeds', () {
      final decoded = DerivedSecretKey.decode(btcXprv);
      expect(decoded.secretKey.bytes.length, equals(32));
    });

    test('DerivedPublicKey.decode without expectedVersion succeeds', () {
      final decoded = DerivedPublicKey.decode(btcXpub);
      expect(decoded.publicKey.bytes.length, equals(33));
    });

    test('decoded key preserves depth, index, parentFingerprint', () {
      final master = DerivedKey.fromSeed(_bip32Seed) as DerivedSecretKey;
      final child = master.deriveHardened(44) as DerivedSecretKey;
      final childXprv = child.encode(version: _btcMainPriv);
      final decoded = DerivedSecretKey.decode(
        childXprv,
        expectedVersion: _btcMainPriv,
      );
      expect(decoded.depth, equals(child.depth));
      expect(decoded.index, equals(child.index));
      expect(decoded.parentFingerprint, equals(child.parentFingerprint));
    });
  });

  // =========================================================================
  // Group 3: MWEB Address (COIN-03)
  // =========================================================================
  group('MWEB address', () {
    final ltcChain = const Chain(
      wifPrefix: 0xb0,
      p2pkhPrefix: 0x30,
      p2shPrefix: 0x32,
      bech32Hrp: 'ltc',
      name: 'Litecoin',
      bip44CoinType: 2,
      supportsSegwit: true,
      supportsTaproot: true,
      privHDPrefix: 0x0488ade4,
      pubHDPrefix: 0x0488b21e,
      mwebBech32Hrp: 'ltcmweb',
    );

    // 66-byte MWEB program (deterministic test data)
    final mwebProgram = Uint8List.fromList(
      List.generate(66, (i) => i & 0xff),
    );

    test('MwebAddr constructor requires exactly 66 bytes', () {
      expect(
        () => MwebAddr(Uint8List(65)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => MwebAddr(Uint8List(67)),
        throwsA(isA<ArgumentError>()),
      );
      final addr = MwebAddr(mwebProgram);
      expect(addr.hash.length, equals(66));
    });

    test('MwebAddr encode->fromString round-trip', () {
      final addr = MwebAddr(mwebProgram);
      final encoded = addr.encode(ltcChain);
      expect(encoded.startsWith('ltcmweb1'), isTrue);

      final decoded = MwebAddr.fromString(encoded, ltcChain);
      expect(decoded.hash, equals(mwebProgram));

      final reEncoded = decoded.encode(ltcChain);
      expect(reEncoded, equals(encoded));
    });

    test('MwebAddr.fromString throws FormatException on wrong HRP', () {
      final addr = MwebAddr(mwebProgram);
      final encoded = addr.encode(ltcChain);

      final wrongChain = const Chain(
        wifPrefix: 0xb0,
        p2pkhPrefix: 0x30,
        p2shPrefix: 0x32,
        bech32Hrp: 'ltc',
        name: 'Wrong',
        bip44CoinType: 2,
        privHDPrefix: 0x0488ade4,
        pubHDPrefix: 0x0488b21e,
        mwebBech32Hrp: 'wronghrp',
      );

      expect(
        () => MwebAddr.fromString(encoded, wrongChain),
        throwsA(isA<FormatException>()),
      );
    });

    test('MwebAddr.toLocking throws UnsupportedError', () {
      final addr = MwebAddr(mwebProgram);
      expect(() => addr.toLocking(), throwsA(isA<UnsupportedError>()));
    });

    test('MwebAddr.scriptPubKey throws UnsupportedError', () {
      final addr = MwebAddr(mwebProgram);
      expect(() => addr.scriptPubKey, throwsA(isA<UnsupportedError>()));
    });

    test('MwebAddr.encode throws StateError when chain has no mwebBech32Hrp',
        () {
      final noMwebChain = const Chain(
        wifPrefix: 0x80,
        p2pkhPrefix: 0x00,
        p2shPrefix: 0x05,
        bech32Hrp: 'bc',
        name: 'Bitcoin',
        bip44CoinType: 0,
        privHDPrefix: 0x0488ade4,
        pubHDPrefix: 0x0488b21e,
      );
      final addr = MwebAddr(mwebProgram);
      expect(
        () => addr.encode(noMwebChain),
        throwsA(isA<StateError>()),
      );
    });

    test('Addr.fromString dispatches to MwebAddr for MWEB addresses', () {
      final addr = MwebAddr(mwebProgram);
      final encoded = addr.encode(ltcChain);

      final parsed = Addr.fromString(encoded, ltcChain);
      expect(parsed, isA<MwebAddr>());
      expect(parsed.hash, equals(mwebProgram));
    });

    test(
        'Addr.fromString still returns SegwitAddr for normal '
        'bech32 addresses on chain with mwebBech32Hrp', () {
      // Create a P2WPKH address with the ltc HRP
      final hash20 = Uint8List(20);
      final p2wpkh = P2wpkhAddr(hash20);
      final encoded = p2wpkh.encode(ltcChain);
      expect(encoded.startsWith('ltc1'), isTrue);

      final parsed = Addr.fromString(encoded, ltcChain);
      expect(parsed, isA<SegwitAddr>());
    });

    test(
        'Addr.fromString returns LegacyAddr for base58 addresses '
        'on chain without mwebBech32Hrp', () {
      final noMwebChain = const Chain(
        wifPrefix: 0x80,
        p2pkhPrefix: 0x00,
        p2shPrefix: 0x05,
        bech32Hrp: 'bc',
        name: 'Bitcoin',
        bip44CoinType: 0,
        privHDPrefix: 0x0488ade4,
        pubHDPrefix: 0x0488b21e,
      );
      // P2PKH address for Bitcoin mainnet (prefix 0x00)
      final hash20 = Uint8List(20);
      final p2pkh = P2pkhAddr(hash20);
      final encoded = p2pkh.encode(noMwebChain);

      final parsed = Addr.fromString(encoded, noMwebChain);
      expect(parsed, isA<LegacyAddr>());
    });
  });

  // =========================================================================
  // Group 4: Message Signing (COIN-04)
  // =========================================================================
  group('message signing with custom prefix', () {
    // Fixed test private key (BIP-32 Test Vector 1 seed -> master key)
    late SecretKey testPrivKey;
    late PublicKey testPubKey;
    const testMessage = 'Hello World';

    setUp(() {
      final master = DerivedKey.fromSeed(_bip32Seed) as DerivedSecretKey;
      testPrivKey = master.secretKey;
      testPubKey = master.publicKey;
    });

    test('sign with default prefix (Bitcoin) and verify round-trip', () {
      final sig = MessageSig.sign(testMessage, testPrivKey.bytes);
      expect(sig.verify(testMessage, testPubKey.bytes), isTrue);
    });

    test('sign with explicit Bitcoin prefix matches default', () {
      final sigDefault = MessageSig.sign(testMessage, testPrivKey.bytes);
      final sigExplicit = MessageSig.sign(
        testMessage,
        testPrivKey.bytes,
        messagePrefix: _bitcoinPrefix,
      );
      // Both should produce valid signatures
      expect(sigDefault.verify(testMessage, testPubKey.bytes), isTrue);
      expect(
        sigExplicit.verify(
          testMessage,
          testPubKey.bytes,
          messagePrefix: _bitcoinPrefix,
        ),
        isTrue,
      );
    });

    test('verify with no messagePrefix param (backward compat)', () {
      final sig = MessageSig.sign(testMessage, testPrivKey.bytes);
      // Verify without prefix param should use Bitcoin default
      expect(sig.verify(testMessage, testPubKey.bytes), isTrue);
    });

    test('Litecoin prefix sign->verify round-trip', () {
      final sig = MessageSig.sign(
        testMessage,
        testPrivKey.bytes,
        messagePrefix: _litecoinPrefix,
      );
      expect(
        sig.verify(
          testMessage,
          testPubKey.bytes,
          messagePrefix: _litecoinPrefix,
        ),
        isTrue,
      );
    });

    test('Dogecoin prefix sign->verify round-trip', () {
      final sig = MessageSig.sign(
        testMessage,
        testPrivKey.bytes,
        messagePrefix: _dogecoinPrefix,
      );
      expect(
        sig.verify(
          testMessage,
          testPubKey.bytes,
          messagePrefix: _dogecoinPrefix,
        ),
        isTrue,
      );
    });

    test('Dash prefix sign->verify round-trip', () {
      final sig = MessageSig.sign(
        testMessage,
        testPrivKey.bytes,
        messagePrefix: _dashPrefix,
      );
      expect(
        sig.verify(
          testMessage,
          testPubKey.bytes,
          messagePrefix: _dashPrefix,
        ),
        isTrue,
      );
    });

    test('Namecoin prefix sign->verify round-trip', () {
      final sig = MessageSig.sign(
        testMessage,
        testPrivKey.bytes,
        messagePrefix: _namecoinPrefix,
      );
      expect(
        sig.verify(
          testMessage,
          testPubKey.bytes,
          messagePrefix: _namecoinPrefix,
        ),
        isTrue,
      );
    });

    test('Firo (Zcoin) prefix sign->verify round-trip', () {
      final sig = MessageSig.sign(
        testMessage,
        testPrivKey.bytes,
        messagePrefix: _firoPrefix,
      );
      expect(
        sig.verify(
          testMessage,
          testPubKey.bytes,
          messagePrefix: _firoPrefix,
        ),
        isTrue,
      );
    });

    test('different prefixes produce different signature bytes', () {
      final sigBtc = MessageSig.sign(testMessage, testPrivKey.bytes);
      final sigLtc = MessageSig.sign(
        testMessage,
        testPrivKey.bytes,
        messagePrefix: _litecoinPrefix,
      );
      // The signature bytes should differ because the hash input differs
      expect(sigBtc.toBytes(), isNot(equals(sigLtc.toBytes())));
    });

    test('verify fails with wrong prefix', () {
      final sig = MessageSig.sign(
        testMessage,
        testPrivKey.bytes,
        messagePrefix: _litecoinPrefix,
      );
      // Verify with Bitcoin (default) prefix should fail
      expect(sig.verify(testMessage, testPubKey.bytes), isFalse);
    });

    test('recoverPublicKey with matching prefix returns correct key', () {
      final sig = MessageSig.sign(
        testMessage,
        testPrivKey.bytes,
        messagePrefix: _dogecoinPrefix,
      );
      final recovered = sig.recoverPublicKey(
        testMessage,
        messagePrefix: _dogecoinPrefix,
      );
      expect(recovered, equals(testPubKey.bytes));
    });

    test('recoverPublicKey with wrong prefix returns different key', () {
      final sig = MessageSig.sign(
        testMessage,
        testPrivKey.bytes,
        messagePrefix: _litecoinPrefix,
      );
      final recovered = sig.recoverPublicKey(testMessage);
      // Recovered with default (Bitcoin) prefix should not match
      expect(recovered, isNot(equals(testPubKey.bytes)));
    });
  });
}
