/// P2WPKH transaction building tests exercising the BIP-143 witness sighash
/// pattern used by buildTransaction in electrumx_interface.dart.
///
/// Requires secp256k1 native library:
///   LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib flutter test test/comprehensive_crypto/transaction_building/p2wpkh_tx_test.dart
///
/// Satisfies: TEST-02, TEST-04 (P2WPKH signing + assembly).
import 'dart:typed_data';

import 'package:coin/coin.dart' as coin;
import 'package:flutter_test/flutter_test.dart';

import '../../bitcoindart_coverage/test_vectors.dart';

void main() {
  setUpAll(() async {
    await coin.VaultKeeper.initialize();
  });

  group('P2WPKH transaction building', () {
    late coin.SecretKey sk;
    late Uint8List pubKeyBytes;
    late Uint8List pubKeyHash;
    late Uint8List scriptCode;
    late Uint8List p2wpkhScript;
    late Uint8List txidInternal;

    setUp(() {
      sk = coin.SecretKey(hexToBytes(kTestPrivKeyHex1));
      pubKeyBytes = sk.publicKey.bytes;
      pubKeyHash = coin.hash160(pubKeyBytes);
      // BIP-143: P2WPKH scriptCode is P2PKH of the pubkey hash.
      scriptCode = coin.PayToPubKeyHash(pubKeyHash).compiled;
      p2wpkhScript = coin.PayToWitnessPubKey(pubKeyHash).compiled;
      txidInternal = Uint8List.fromList(
        hexToBytes(kTestTxId1).reversed.toList(),
      );
    });

    test('single input P2WPKH tx with BIP-143 witness sighash', () {
      final inputValue = BigInt.from(100000);

      // Build unsigned tx.
      final unsignedTx = coin.Tx(
        version: 1,
        inputs: [
          coin.RawInput(
            prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
          ),
        ],
        outputs: [
          coin.TxOutput(
            value: BigInt.from(40000),
            scriptPubKey: p2wpkhScript,
          ),
        ],
      );

      // Compute BIP-143 witness sighash.
      final hasher = coin.WitnessSigHasher();
      final digest = hasher.hash(
        unsignedTx,
        0,
        coin.SigHashType.all,
        prevScript: scriptCode,
        amount: inputValue,
      );

      // Sign with ECDSA.
      final sig = coin.EcdsaSig.sign(digest, sk.bytes);
      final inputSig = coin.InputSig(
        derSig: sig.toDer(),
        hashType: coin.SigHashType.all,
      );

      // Build signed tx with witness input.
      final signedTx = coin.Tx(
        version: 1,
        inputs: [
          coin.P2wpkhInput(
            prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
            inputSig: inputSig,
            publicKey: pubKeyBytes,
          ),
        ],
        outputs: [
          coin.TxOutput(
            value: BigInt.from(40000),
            scriptPubKey: p2wpkhScript,
          ),
        ],
      );

      // P2WPKH is witness tx.
      expect(signedTx.isWitness, isTrue);

      // Serialize to hex and verify structure.
      final hex = signedTx.toHex();

      // Witness marker (0x0001) should be present after version bytes.
      expect(hex.contains('0001'), isTrue,
          reason: 'Witness tx should contain segwit marker');

      // Parse back - note: Tx.fromHex reads witness data but stores
      // inputs as RawInput (which drops witness on re-serialization).
      // We verify the parse succeeds and has correct structure.
      final parsed = coin.Tx.fromHex(hex);
      expect(parsed.inputs.length, equals(1));
      expect(parsed.outputs.length, equals(1));
      expect(parsed.outputs[0].value, equals(BigInt.from(40000)));

      // Verify total serialized size is substantial (includes witness).
      final totalBytes = signedTx.toBytes().length;
      expect(
        totalBytes,
        greaterThan(100),
        reason: 'Witness tx should have substantial byte count',
      );
    });

    test('multi-input P2WPKH tx', () {
      final inputValue0 = BigInt.from(100000);
      final inputValue1 = BigInt.from(200000);

      final txid2 = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        txid2[i] = 0x03;
      }

      // Build unsigned tx with 2 inputs.
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
            value: BigInt.from(250000),
            scriptPubKey: p2wpkhScript,
          ),
        ],
      );

      final hasher = coin.WitnessSigHasher();

      // Sign input 0 with its amount.
      final digest0 = hasher.hash(
        unsignedTx,
        0,
        coin.SigHashType.all,
        prevScript: scriptCode,
        amount: inputValue0,
      );
      final sig0 = coin.EcdsaSig.sign(digest0, sk.bytes);
      final inputSig0 = coin.InputSig(
        derSig: sig0.toDer(),
        hashType: coin.SigHashType.all,
      );

      // Sign input 1 with different amount.
      final digest1 = hasher.hash(
        unsignedTx,
        1,
        coin.SigHashType.all,
        prevScript: scriptCode,
        amount: inputValue1,
      );
      final sig1 = coin.EcdsaSig.sign(digest1, sk.bytes);
      final inputSig1 = coin.InputSig(
        derSig: sig1.toDer(),
        hashType: coin.SigHashType.all,
      );

      // Verify different amounts produce different sighashes.
      expect(
        bytesToHex(digest0),
        isNot(equals(bytesToHex(digest1))),
        reason: 'Different input amounts must produce different sighashes',
      );

      // Build signed tx.
      final signedTx = coin.Tx(
        version: 2,
        inputs: [
          coin.P2wpkhInput(
            prevOut: coin.Outpoint(txid: txidInternal, vout: 0),
            inputSig: inputSig0,
            publicKey: pubKeyBytes,
          ),
          coin.P2wpkhInput(
            prevOut: coin.Outpoint(txid: txid2, vout: 1),
            inputSig: inputSig1,
            publicKey: pubKeyBytes,
          ),
        ],
        outputs: [
          coin.TxOutput(
            value: BigInt.from(250000),
            scriptPubKey: p2wpkhScript,
          ),
        ],
      );

      // Verify witness tx and structure.
      expect(signedTx.isWitness, isTrue);
      final hex = signedTx.toHex();

      // Parse back and verify input/output counts.
      final parsed = coin.Tx.fromHex(hex);
      expect(parsed.inputs.length, equals(2));
      expect(parsed.outputs.length, equals(1));
      expect(parsed.outputs[0].value, equals(BigInt.from(250000)));
    });

    test('P2WPKH witness signature verification', () {
      final inputValue = BigInt.from(kTestUtxoValue1);

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
            scriptPubKey: p2wpkhScript,
          ),
        ],
      );

      final hasher = coin.WitnessSigHasher();
      final digest = hasher.hash(
        unsignedTx,
        0,
        coin.SigHashType.all,
        prevScript: scriptCode,
        amount: inputValue,
      );

      final sig = coin.EcdsaSig.sign(digest, sk.bytes);

      // Verify signature.
      expect(
        sig.verify(digest, pubKeyBytes),
        isTrue,
        reason: 'ECDSA witness signature should verify',
      );

      // Verify against wrong key fails.
      final sk2 = coin.SecretKey(hexToBytes(kTestPrivKeyHex2));
      expect(
        sig.verify(digest, sk2.publicKey.bytes),
        isFalse,
        reason: 'Signature should not verify with wrong key',
      );
    });
  });
}
