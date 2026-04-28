/// P2TR (taproot) transaction building tests exercising the BIP-341
/// sighash and Schnorr signing pattern used by buildTransaction in
/// electrumx_interface.dart.
///
/// Requires secp256k1 native library:
///   LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib flutter test test/comprehensive_crypto/transaction_building/p2tr_tx_test.dart
///
/// Satisfies: TEST-02, TEST-04 (P2TR Schnorr signing + assembly).
import 'dart:typed_data';

import 'package:coin/coin.dart' as coin;
import 'package:flutter_test/flutter_test.dart';

import '../../bitcoindart_coverage/test_vectors.dart';

void main() {
  setUpAll(() async {
    await coin.VaultKeeper.initialize();
  });

  group('P2TR transaction building', () {
    late coin.SecretKey sk;
    late coin.PublicKey pubKey;
    late coin.Taproot taproot;
    late coin.SecretKey tweakedKey;
    late Uint8List tweakedPubKey;
    late Uint8List taprootScript;
    late Uint8List txidInternal;

    setUp(() {
      sk = coin.SecretKey(hexToBytes(kTestPrivKeyHex1));
      pubKey = sk.publicKey;

      // Key-path only taproot (no script tree).
      taproot = coin.Taproot(internalKey: pubKey);
      tweakedKey = taproot.tweakSecretKey(sk);
      tweakedPubKey = taproot.tweakedKey;

      // P2TR output script: OP_1 <32-byte-tweaked-x-only-pubkey>.
      taprootScript = coin.PayToTaproot(tweakedPubKey).compiled;

      txidInternal = Uint8List.fromList(
        hexToBytes(kTestTxId1).reversed.toList(),
      );
    });

    test('P2TR key-path spend with tweaked Schnorr signature', () {
      final inputValue = BigInt.from(kTestUtxoValue1);

      // Build prevOuts for TaprootSigHasher.
      final prevOuts = [
        coin.TxOutput(
          value: inputValue,
          scriptPubKey: taprootScript,
        ),
      ];

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
            value: BigInt.from(kTestSendAmount1),
            scriptPubKey: taprootScript,
          ),
        ],
      );

      // Compute BIP-341 taproot sighash.
      final hasher = coin.TaprootSigHasher(prevOuts: prevOuts);
      final digest = hasher.hash(
        unsignedTx,
        0,
        coin.SigHashType.all,
      );

      // Sign with Schnorr using the tweaked key.
      final sig = coin.SchnorrSig.sign(digest, tweakedKey.bytes);

      // Build SchnorrInputSig and TaprootKeyInput.
      final inputSig = coin.SchnorrInputSig(
        sig: sig.bytes,
        hashType: coin.SigHashType.all,
      );

      final signedTx = coin.Tx(
        version: 2,
        inputs: [
          coin.TaprootKeyInput(
            prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
            inputSig: inputSig,
          ),
        ],
        outputs: [
          coin.TxOutput(
            value: BigInt.from(kTestSendAmount1),
            scriptPubKey: taprootScript,
          ),
        ],
      );

      // Verify tx is witness.
      expect(signedTx.isWitness, isTrue);

      // Serialize and parse back.
      final hex = signedTx.toHex();
      final parsed = coin.Tx.fromHex(hex);
      expect(parsed.inputs.length, equals(1));
      expect(parsed.outputs.length, equals(1));
      expect(parsed.outputs[0].value, equals(BigInt.from(kTestSendAmount1)));

      // Verify the Schnorr signature against the tweaked public key.
      expect(
        sig.verify(digest, tweakedPubKey),
        isTrue,
        reason: 'Schnorr signature should verify against tweaked x-only key',
      );
    });

    test(
        'P2TR Schnorr signature is 64 bytes', () {
      final inputValue = BigInt.from(kTestUtxoValue1);
      final prevOuts = [
        coin.TxOutput(value: inputValue, scriptPubKey: taprootScript),
      ];

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
            scriptPubKey: taprootScript,
          ),
        ],
      );

      final hasher = coin.TaprootSigHasher(prevOuts: prevOuts);
      final digest = hasher.hash(unsignedTx, 0, coin.SigHashType.all);
      final sig = coin.SchnorrSig.sign(digest, tweakedKey.bytes);

      // Schnorr signatures are always 64 bytes.
      expect(sig.bytes.length, equals(64));

      // When using SigHashType.all (0x01), SchnorrInputSig.toBytes() is
      // 64 bytes (no suffix byte appended) for SIGHASH_ALL.
      final inputSig = coin.SchnorrInputSig(
        sig: sig.bytes,
        hashType: coin.SigHashType.all,
      );
      // SigHashType.all is the "default" for taproot; 64-byte encoding.
      expect(inputSig.toBytes().length, equals(64));
    });

    test('P2TR Schnorr signature verification', () {
      final inputValue = BigInt.from(kTestUtxoValue1);
      final prevOuts = [
        coin.TxOutput(value: inputValue, scriptPubKey: taprootScript),
      ];

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
            scriptPubKey: taprootScript,
          ),
        ],
      );

      final hasher = coin.TaprootSigHasher(prevOuts: prevOuts);
      final digest = hasher.hash(unsignedTx, 0, coin.SigHashType.all);
      final sig = coin.SchnorrSig.sign(digest, tweakedKey.bytes);

      // Verify against correct tweaked key.
      expect(
        sig.verify(digest, tweakedPubKey),
        isTrue,
        reason: 'Schnorr sig should verify against tweaked public key',
      );

      // Verify against un-tweaked key should fail.
      expect(
        sig.verify(digest, pubKey.xOnly),
        isFalse,
        reason: 'Schnorr sig should NOT verify against un-tweaked key',
      );

      // Verify against wrong digest should fail.
      final wrongDigest = Uint8List(32);
      expect(
        sig.verify(wrongDigest, tweakedPubKey),
        isFalse,
        reason: 'Schnorr sig should NOT verify against wrong digest',
      );
    });
  });
}
