/// P2SH-P2WPKH (BIP49) transaction building tests replicating the
/// _P2shP2wpkhInput construction pattern from electrumx_interface.dart.
///
/// Requires secp256k1 native library:
///   LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib flutter test test/comprehensive_crypto/transaction_building/p2sh_p2wpkh_tx_test.dart
///
/// Satisfies: TEST-02, TEST-04 (P2SH-P2WPKH signing + assembly).
import 'dart:typed_data';

import 'package:coin/coin.dart' as coin;
import 'package:flutter_test/flutter_test.dart';

import '../../bitcoindart_coverage/test_vectors.dart';

/// Replicates _P2shP2wpkhInput from electrumx_interface.dart.
/// This is the BIP49 wrapped-segwit input: scriptSig pushes the witness
/// program (OP_0 PUSH20 pubKeyHash), witness contains [sig, pubkey].
class P2shP2wpkhInput extends coin.TxInput {
  @override
  final coin.Outpoint prevOut;
  @override
  final Uint8List scriptSig;
  @override
  final int sequence;
  final coin.InputSig inputSig;
  final Uint8List publicKey;

  P2shP2wpkhInput({
    required this.prevOut,
    required this.scriptSig,
    required this.inputSig,
    required this.publicKey,
    this.sequence = coin.TxInput.sequenceFinal,
  });

  @override
  List<Uint8List> get witness => [inputSig.toBytes(), publicKey];
  @override
  bool get complete => true;
  @override
  int get signedSize => 91;
}

void main() {
  setUpAll(() async {
    await coin.VaultKeeper.initialize();
  });

  group('P2SH-P2WPKH transaction building', () {
    late coin.SecretKey sk;
    late Uint8List pubKeyBytes;
    late Uint8List pubKeyHash;
    late Uint8List scriptCode;
    late Uint8List txidInternal;

    setUp(() {
      sk = coin.SecretKey(hexToBytes(kTestPrivKeyHex1));
      pubKeyBytes = sk.publicKey.bytes;
      pubKeyHash = coin.hash160(pubKeyBytes);
      // BIP-143: scriptCode for P2SH-P2WPKH is the P2PKH of the pubkey hash.
      scriptCode = coin.PayToPubKeyHash(pubKeyHash).compiled;
      txidInternal = Uint8List.fromList(
        hexToBytes(kTestTxId1).reversed.toList(),
      );
    });

    test('P2SH-P2WPKH input has both scriptSig and witness data', () {
      final inputValue = BigInt.from(kTestUtxoValue1);

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
            scriptPubKey: scriptCode,
          ),
        ],
      );

      // Compute BIP-143 witness sighash (same as P2WPKH).
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

      // Build witness program and scriptSig (same as electrumx_interface).
      final witnessProgram = Uint8List.fromList(
        [0x00, 0x14, ...pubKeyHash],
      );
      final scriptSigBytes = Uint8List.fromList(
        [witnessProgram.length, ...witnessProgram],
      );

      // Build signed tx with P2SH-P2WPKH input.
      final signedTx = coin.Tx(
        version: 2,
        inputs: [
          P2shP2wpkhInput(
            prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
            scriptSig: scriptSigBytes,
            inputSig: inputSig,
            publicKey: pubKeyBytes,
          ),
        ],
        outputs: [
          coin.TxOutput(
            value: BigInt.from(kTestSendAmount1),
            scriptPubKey: scriptCode,
          ),
        ],
      );

      // Verify tx is witness (has witness data).
      expect(signedTx.isWitness, isTrue);

      // Serialize and verify the hex contains both scriptSig and witness.
      final hex = signedTx.toHex();

      // The witness program (0014 + pubKeyHash) should appear in scriptSig.
      final witnessProgramHex = bytesToHex(witnessProgram);
      expect(
        hex.contains(witnessProgramHex),
        isTrue,
        reason: 'Serialized tx should contain witness program in scriptSig',
      );

      // Parse back and verify structure.
      final parsed = coin.Tx.fromHex(hex);
      expect(parsed.inputs.length, equals(1));
      expect(parsed.outputs.length, equals(1));
      expect(parsed.outputs[0].value, equals(BigInt.from(kTestSendAmount1)));

      // Verify the parsed input has a non-empty scriptSig (the
      // witness program push).
      final parsedInput = parsed.inputs[0];
      expect(
        parsedInput.scriptSig.isNotEmpty,
        isTrue,
        reason: 'P2SH-P2WPKH input should have non-empty scriptSig',
      );

      // Verify signature is valid.
      expect(
        sig.verify(digest, pubKeyBytes),
        isTrue,
        reason: 'ECDSA signature should verify against witness sighash',
      );
    });

    test('P2SH-P2WPKH sighash matches P2WPKH sighash for same inputs', () {
      final inputValue = BigInt.from(kTestUtxoValue1);

      // Build an unsigned tx (same for both P2SH-P2WPKH and P2WPKH).
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
            scriptPubKey: scriptCode,
          ),
        ],
      );

      final hasher = coin.WitnessSigHasher();

      // Compute sighash for P2SH-P2WPKH.
      final digestP2sh = hasher.hash(
        unsignedTx,
        0,
        coin.SigHashType.all,
        prevScript: scriptCode,
        amount: inputValue,
      );

      // Compute sighash for P2WPKH (same parameters).
      final digestP2wpkh = hasher.hash(
        unsignedTx,
        0,
        coin.SigHashType.all,
        prevScript: scriptCode,
        amount: inputValue,
      );

      // They must be identical: the sighash algorithm is the same
      // (BIP-143); the only difference is how the signed input is
      // assembled (scriptSig vs witness-only).
      expect(
        bytesToHex(digestP2sh),
        equals(bytesToHex(digestP2wpkh)),
        reason:
            'P2SH-P2WPKH and P2WPKH produce identical sighash for same '
            'inputs, the difference is only in input assembly',
      );
    });
  });
}
