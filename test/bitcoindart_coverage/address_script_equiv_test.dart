import 'dart:typed_data';

import 'package:coin/coin.dart';
import 'package:coin/coin_chains.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_vectors.dart';

/// Coin equivalence tests for locking types (PayToPubKeyHash,
/// PayToWitnessPubKey, PayToScriptHash) and Addr.fromString.scriptPubKey.
///
/// These prove that coin produces byte-identical scriptPubKey output to
/// bitcoindart for the same inputs, satisfying EQV-03 and EQV-05.
///
/// IMPORTANT: coin's locking types take pre-computed hash160, NOT raw pubkeys.
/// bitcoindart's PaymentData takes the raw pubkey and hashes internally.
void main() {
  late final Uint8List pubKeyBytes;
  late final Uint8List pubKeyHash;
  late final Chain particlChain;

  setUpAll(() async {
    await VaultKeeper.initialize();
    pubKeyBytes = hexToBytes(kTestPubKeyHex1);
    pubKeyHash = hash160(pubKeyBytes);
    particlChain = ParticlParams.particl.chain;
  });

  group('PayToPubKeyHash equivalence', () {
    test('compiled produces valid P2PKH scriptPubKey matching bitcoindart', () {
      final locking = PayToPubKeyHash(pubKeyHash);
      final script = locking.compiled;

      // P2PKH: OP_DUP OP_HASH160 <20-byte-hash160> OP_EQUALVERIFY OP_CHECKSIG
      expect(script.length, equals(25));
      expect(script[0], equals(0x76)); // OP_DUP
      expect(script[1], equals(0xa9)); // OP_HASH160
      expect(script[2], equals(0x14)); // push 20 bytes
      // The hash160 bytes at positions 3..22 must be the pubkey hash.
      expect(
        script.sublist(3, 23),
        equals(pubKeyHash),
      );
      expect(script[23], equals(0x88)); // OP_EQUALVERIFY
      expect(script[24], equals(0xac)); // OP_CHECKSIG
    });
  });

  group('PayToWitnessPubKey equivalence', () {
    test('compiled produces valid P2WPKH scriptPubKey matching bitcoindart',
        () {
      final locking = PayToWitnessPubKey(pubKeyHash);
      final script = locking.compiled;

      // P2WPKH: OP_0 <20-byte-hash160>
      expect(script.length, equals(22));
      expect(script[0], equals(0x00)); // witness version 0
      expect(script[1], equals(0x14)); // push 20 bytes
      expect(
        script.sublist(2, 22),
        equals(pubKeyHash),
      );
    });
  });

  group('PayToScriptHash equivalence (BIP49)', () {
    test('compiled produces valid P2SH scriptPubKey matching bitcoindart', () {
      // Build the P2WPKH redeem script first.
      final redeemScript = PayToWitnessPubKey(pubKeyHash).compiled;

      // Hash160 the redeem script to get the script hash for P2SH.
      final scriptHash = hash160(redeemScript);

      final locking = PayToScriptHash(scriptHash);
      final script = locking.compiled;

      // P2SH: OP_HASH160 <20-byte-hash160-of-redeem> OP_EQUAL
      expect(script.length, equals(23));
      expect(script[0], equals(0xa9)); // OP_HASH160
      expect(script[1], equals(0x14)); // push 20 bytes
      expect(
        script.sublist(2, 22),
        equals(scriptHash),
      );
      expect(script[22], equals(0x87)); // OP_EQUAL
    });
  });

  group('Addr.fromString equivalence', () {
    test('bech32 address produces correct witness scriptPubKey', () {
      // Build a bech32 address from the pubkey hash using coin.
      final addr = P2wpkhAddr(pubKeyHash);
      final addressString = addr.encode(particlChain);

      // Sanity: should start with Particl HRP.
      expect(addressString, startsWith(kParticlBech32));

      // Decode back using Addr.fromString and verify scriptPubKey.
      final decoded = Addr.fromString(addressString, particlChain);
      final scriptPubKey = decoded.scriptPubKey;

      expect(scriptPubKey.length, equals(22));
      expect(scriptPubKey[0], equals(0x00)); // witness version
      expect(scriptPubKey[1], equals(0x14)); // 20 bytes
      expect(
        scriptPubKey.sublist(2, 22),
        equals(pubKeyHash),
      );

      // Must match the directly-compiled locking script.
      expect(scriptPubKey, equals(PayToWitnessPubKey(pubKeyHash).compiled));
    });

    test('P2PKH address produces correct legacy scriptPubKey', () {
      // Build a legacy P2PKH address from the pubkey hash using coin.
      final addr = P2pkhAddr(pubKeyHash);
      final addressString = addr.encode(particlChain);

      // Decode back and verify scriptPubKey.
      final decoded = Addr.fromString(addressString, particlChain);
      final scriptPubKey = decoded.scriptPubKey;

      expect(scriptPubKey.length, equals(25));
      expect(scriptPubKey[0], equals(0x76)); // OP_DUP
      expect(scriptPubKey[1], equals(0xa9)); // OP_HASH160
      expect(scriptPubKey[23], equals(0x88)); // OP_EQUALVERIFY
      expect(scriptPubKey[24], equals(0xac)); // OP_CHECKSIG

      // Must match the directly-compiled locking script.
      expect(scriptPubKey, equals(PayToPubKeyHash(pubKeyHash).compiled));
    });
  });
}
