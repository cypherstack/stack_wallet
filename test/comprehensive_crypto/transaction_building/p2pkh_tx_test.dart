/// P2PKH transaction building tests exercising the sign-then-assemble
/// pattern used by buildTransaction in electrumx_interface.dart.
///
/// Requires secp256k1 native library:
///   LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib flutter test test/comprehensive_crypto/transaction_building/p2pkh_tx_test.dart
///
/// Satisfies: TEST-02, TEST-04 (P2PKH signing + assembly).
import 'dart:typed_data';

import 'package:coin/coin.dart' as coin;
import 'package:flutter_test/flutter_test.dart';

import '../../bitcoindart_coverage/test_vectors.dart';

void main() {
  setUpAll(() async {
    await coin.VaultKeeper.initialize();
  });

  group('P2PKH transaction building', () {
    late coin.SecretKey sk;
    late Uint8List pubKeyBytes;
    late Uint8List pubKeyHash;
    late Uint8List p2pkhScript;
    late Uint8List txidInternal;

    setUp(() {
      sk = coin.SecretKey(hexToBytes(kTestPrivKeyHex1));
      pubKeyBytes = sk.publicKey.bytes;
      pubKeyHash = coin.hash160(pubKeyBytes);
      p2pkhScript = coin.PayToPubKeyHash(pubKeyHash).compiled;
      // Use the deterministic test txid (internal byte order).
      txidInternal = Uint8List.fromList(
        hexToBytes(kTestTxId1).reversed.toList(),
      );
    });

    test(
        'single input, single output P2PKH tx round-trips through hex '
        'serialization', () {
      // Build unsigned tx.
      final unsignedTx = coin.Tx(
        version: 2,
        inputs: [
          coin.RawInput(
            prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
          ),
        ],
        outputs: [
          coin.TxOutput(
            value: BigInt.from(50000),
            scriptPubKey: p2pkhScript,
          ),
        ],
      );

      // Compute legacy sighash.
      final hasher = coin.LegacySigHasher();
      final digest = hasher.hash(
        unsignedTx,
        0,
        coin.SigHashType.all,
        prevScript: p2pkhScript,
      );

      // Sign with ECDSA.
      final sig = coin.EcdsaSig.sign(digest, sk.bytes);
      final inputSig = coin.InputSig(
        derSig: sig.toDer(),
        hashType: coin.SigHashType.all,
      );

      // Build signed tx.
      final signedTx = coin.Tx(
        version: 2,
        inputs: [
          coin.P2pkhInput(
            prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
            inputSig: inputSig,
            publicKey: pubKeyBytes,
          ),
        ],
        outputs: [
          coin.TxOutput(
            value: BigInt.from(50000),
            scriptPubKey: p2pkhScript,
          ),
        ],
      );

      // Round-trip through hex serialization.
      final hex = signedTx.toHex();
      final parsed = coin.Tx.fromHex(hex);
      expect(parsed.toHex(), equals(hex), reason: 'Hex round-trip failed');
      expect(parsed.inputs.length, equals(1));
      expect(parsed.outputs.length, equals(1));
      expect(parsed.outputs[0].value, equals(BigInt.from(50000)));

      // P2PKH is non-witness: isWitness should be false.
      expect(signedTx.isWitness, isFalse);
    });

    test('multi-input P2PKH tx (2 inputs, 2 outputs)', () {
      // Second fake txid.
      final txid2 = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        txid2[i] = 0x02;
      }

      // Build unsigned tx with 2 inputs and 2 outputs.
      final unsignedTx = coin.Tx(
        version: 2,
        inputs: [
          coin.RawInput(
            prevOut: coin.Outpoint(txid: txidInternal, vout: 0),
          ),
          coin.RawInput(
            prevOut: coin.Outpoint(txid: txid2, vout: 1),
          ),
        ],
        outputs: [
          coin.TxOutput(
            value: BigInt.from(40000),
            scriptPubKey: p2pkhScript,
          ),
          coin.TxOutput(
            value: BigInt.from(30000),
            scriptPubKey: p2pkhScript,
          ),
        ],
      );

      final hasher = coin.LegacySigHasher();

      // Sign input 0.
      final digest0 = hasher.hash(
        unsignedTx,
        0,
        coin.SigHashType.all,
        prevScript: p2pkhScript,
      );
      final sig0 = coin.EcdsaSig.sign(digest0, sk.bytes);
      final inputSig0 = coin.InputSig(
        derSig: sig0.toDer(),
        hashType: coin.SigHashType.all,
      );

      // Sign input 1.
      final digest1 = hasher.hash(
        unsignedTx,
        1,
        coin.SigHashType.all,
        prevScript: p2pkhScript,
      );
      final sig1 = coin.EcdsaSig.sign(digest1, sk.bytes);
      final inputSig1 = coin.InputSig(
        derSig: sig1.toDer(),
        hashType: coin.SigHashType.all,
      );

      // Build signed tx.
      final signedTx = coin.Tx(
        version: 2,
        inputs: [
          coin.P2pkhInput(
            prevOut: coin.Outpoint(txid: txidInternal, vout: 0),
            inputSig: inputSig0,
            publicKey: pubKeyBytes,
          ),
          coin.P2pkhInput(
            prevOut: coin.Outpoint(txid: txid2, vout: 1),
            inputSig: inputSig1,
            publicKey: pubKeyBytes,
          ),
        ],
        outputs: [
          coin.TxOutput(
            value: BigInt.from(40000),
            scriptPubKey: p2pkhScript,
          ),
          coin.TxOutput(
            value: BigInt.from(30000),
            scriptPubKey: p2pkhScript,
          ),
        ],
      );

      // Round-trip.
      final hex = signedTx.toHex();
      final parsed = coin.Tx.fromHex(hex);
      expect(parsed.toHex(), equals(hex), reason: 'Multi-input round-trip');
      expect(parsed.inputs.length, equals(2));
      expect(parsed.outputs.length, equals(2));
      expect(parsed.outputs[0].value, equals(BigInt.from(40000)));
      expect(parsed.outputs[1].value, equals(BigInt.from(30000)));
    });

    test('P2PKH signature verification', () {
      final unsignedTx = coin.Tx(
        version: 2,
        inputs: [
          coin.RawInput(
            prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
          ),
        ],
        outputs: [
          coin.TxOutput(
            value: BigInt.from(kTestSendAmount1),
            scriptPubKey: p2pkhScript,
          ),
        ],
      );

      final hasher = coin.LegacySigHasher();
      final digest = hasher.hash(
        unsignedTx,
        0,
        coin.SigHashType.all,
        prevScript: p2pkhScript,
      );

      final sig = coin.EcdsaSig.sign(digest, sk.bytes);

      // Verify the signature is valid against the sighash and public key.
      expect(
        sig.verify(digest, pubKeyBytes),
        isTrue,
        reason: 'ECDSA signature should verify against sighash digest',
      );

      // Verify with a round-tripped DER encoding.
      final derBytes = sig.toDer();
      final restored = coin.EcdsaSig.fromDer(derBytes);
      expect(
        restored.verify(digest, pubKeyBytes),
        isTrue,
        reason: 'DER round-tripped signature should verify',
      );

      // Verify against wrong pubkey fails.
      final sk2 = coin.SecretKey(hexToBytes(kTestPrivKeyHex2));
      expect(
        sig.verify(digest, sk2.publicKey.bytes),
        isFalse,
        reason: 'Signature should not verify with wrong public key',
      );
    });
  });
}
