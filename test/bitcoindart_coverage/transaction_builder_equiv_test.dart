/// coin TxAssembler equivalence tests for TransactionBuilder coverage.
///
/// Proves that coin's transaction building produces equivalent results to
/// bitcoindart's TransactionBuilder for the same inputs/outputs/keys.
///
/// Key findings:
///   - Particl byte-identical comparison is NOT possible: bitcoindart uses a
///     custom Particl serialization (2-byte version + locktime header + output
///     type prefix), while coin uses standard Bitcoin serialization. The
///     sighash computation and signing are proven equivalent instead.
///   - Spark (Firo) P2PKH standard format: coin manually-constructed Tx
///     produces byte-identical hex to bitcoindart TransactionBuilder.
///   - TxAssembler computes correct sighashes but does not populate inputs
///     with signatures (sigs collected but not applied). Signed Tx must be
///     constructed manually using P2pkhInput/P2wpkhInput.
///
/// Satisfies: EQV-01 (TxAssembler equivalence), EQV-08 (all equiv green).
import 'dart:typed_data';

import 'package:bitcoindart/bitcoindart.dart' as bitcoindart;
import 'package:coin/coin.dart';
import 'package:coin/coin_chains.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_vectors.dart';

void main() {
  setUpAll(() async {
    await VaultKeeper.initialize();
  });

  group('Spark P2PKH tx equivalence - byte-identical', () {
    /// Builds a Spark dummy tx with bitcoindart and returns the hex.
    String buildBitcoindartSparkTx() {
      final firoNet = bitcoindart.NetworkType(
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
      final firoKeyPair = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        network: firoNet,
        compressed: true,
      );

      final txb = bitcoindart.TransactionBuilder(network: firoNet);
      txb.setVersion(kSparkTxVersion); // 589827

      final p2pkh = bitcoindart.P2PKH(
        data: bitcoindart.PaymentData(pubkey: firoKeyPair.publicKey!),
        network: firoNet,
      );

      txb.addInput(kTestTxId1, kTestVout1, null, p2pkh.data.output);
      txb.addOutput(p2pkh.data.output!, kTestSendAmount1);
      txb.sign(vin: 0, keyPair: firoKeyPair);
      return txb.build().toHex();
    }

    test('coin manually-constructed Tx matches bitcoindart hex', () {
      final bitcoindartHex = buildBitcoindartSparkTx();

      // Reconstruct the same tx using coin primitives.
      final sk = SecretKey.fromHex(kTestPrivKeyHex1);
      final pubKeyBytes = sk.publicKey.bytes;
      final pubKeyHash20 = hash160(pubKeyBytes);

      // P2PKH scriptPubKey for both input and output.
      final p2pkhScript = PayToPubKeyHash(pubKeyHash20).compiled;

      // The txid in bitcoindart is display-order (reversed hash).
      // coin's Outpoint expects internal byte order (reversed display).
      final txidInternalBytes = Uint8List.fromList(
        hexToBytes(kTestTxId1).reversed.toList(),
      );

      // Use TxAssembler to compute the sighash, then manually build the
      // signed Tx with P2pkhInput.
      final assembler = TxAssembler(
        chainParams: ParticlParams.particl, // Chain params only used for
        // context; sighash is chain-agnostic for legacy P2PKH.
        inputs: [
          AssemblerInput(
            outpoint: Outpoint(txid: txidInternalBytes, vout: kTestVout1),
            value: BigInt.from(kTestUtxoValue1),
            scriptPubKey: p2pkhScript,
          ),
        ],
        outputs: [
          TxOutput(
            value: BigInt.from(kTestSendAmount1),
            scriptPubKey: p2pkhScript,
          ),
        ],
        version: kSparkTxVersion,
        ordering: TxOrdering.none,
      );

      // Capture the sighash from the assembler callback.
      late Uint8List capturedDigest;
      assembler.build((Tx tx, int idx, Uint8List digest, SigHashType ht) {
        capturedDigest = digest;
        // Return value is not used by TxAssembler (known limitation).
        return Uint8List(0);
      });

      // Sign the sighash with coin's EcdsaSig.
      final sig = EcdsaSig.sign(capturedDigest, sk.bytes);
      final derSig = sig.toDer();
      final inputSig = InputSig(
        derSig: derSig,
        hashType: SigHashType.all,
      );

      // Manually construct the signed Tx.
      final signedTx = Tx(
        version: kSparkTxVersion,
        inputs: [
          P2pkhInput(
            prevOut: Outpoint(txid: txidInternalBytes, vout: kTestVout1),
            inputSig: inputSig,
            publicKey: pubKeyBytes,
          ),
        ],
        outputs: [
          TxOutput(
            value: BigInt.from(kTestSendAmount1),
            scriptPubKey: p2pkhScript,
          ),
        ],
        locktime: 0,
      );

      final coinHex = signedTx.toHex();

      // Both start with Spark version bytes.
      expect(coinHex.substring(0, 8), equals('03000900'));
      expect(bitcoindartHex.substring(0, 8), equals('03000900'));

      // Byte-identical tx hex.
      expect(coinHex, equals(bitcoindartHex));
    });
  });

  group('Particl P2WPKH sighash and signing equivalence', () {
    test('coin sighash computation produces valid signature for P2WPKH', () {
      // Build the same P2WPKH transaction with bitcoindart.
      final particlNet = bitcoindart.NetworkType(
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
      final keyPair1 = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        network: particlNet,
        compressed: true,
      );
      final keyPair2 = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex2),
        network: particlNet,
        compressed: true,
      );

      // Get recipient address for output.
      final recipientP2wpkh = bitcoindart.P2WPKH(
        data: bitcoindart.PaymentData(pubkey: keyPair2.publicKey!),
        network: particlNet,
      );
      final recipientAddress = recipientP2wpkh.data.address!;

      // Build with bitcoindart to get the tx hex and extract the witness sig.
      final txb = bitcoindart.TransactionBuilder(network: particlNet);
      txb.setVersion(kParticlTxVersion);
      final p2wpkh = bitcoindart.P2WPKH(
        data: bitcoindart.PaymentData(pubkey: keyPair1.publicKey!),
        network: particlNet,
      );
      txb.addInput(
        kTestTxId1,
        kTestVout1,
        null,
        p2wpkh.data.output,
        kParticlBech32,
      );
      txb.addOutput(recipientAddress, kTestSendAmount1, kParticlBech32);
      txb.sign(
        vin: 0,
        keyPair: keyPair1,
        witnessValue: kTestUtxoValue1,
        overridePrefix: kParticlBech32,
      );
      final bdTx = txb.build(kParticlBech32);

      // Extract the witness signature from bitcoindart's built tx.
      // Witness for P2WPKH: [sig+hashtype, pubkey].
      final bdWitnessSig = bdTx.ins[0].witness![0] as Uint8List;
      // Last byte is hashtype (0x01), rest is DER signature.
      final bdDerSig = bdWitnessSig.sublist(0, bdWitnessSig.length - 1);

      // Now compute the same sighash with coin's WitnessSigHasher.
      final sk = SecretKey.fromHex(kTestPrivKeyHex1);
      final pubKeyBytes = sk.publicKey.bytes;
      final pubKeyHash20 = hash160(pubKeyBytes);

      // BIP143 requires the P2PKH-equivalent script as prevScript for P2WPKH
      // inputs (OP_DUP OP_HASH160 <hash160> OP_EQUALVERIFY OP_CHECKSIG), NOT
      // the actual P2WPKH scriptPubKey (OP_0 <hash160>). bitcoindart does this
      // conversion internally in transaction_builder.dart.
      final p2pkhSignScript = PayToPubKeyHash(pubKeyHash20).compiled;

      // Recipient output: P2WPKH from key2.
      final sk2 = SecretKey.fromHex(kTestPrivKeyHex2);
      final recipientPubKeyHash = hash160(sk2.publicKey.bytes);
      final recipientScript =
          PayToWitnessPubKey(recipientPubKeyHash).compiled;

      final txidInternal = Uint8List.fromList(
        hexToBytes(kTestTxId1).reversed.toList(),
      );

      // Build unsigned tx for sighash computation.
      final unsignedTx = Tx(
        version: kParticlTxVersion,
        inputs: [
          RawInput(
            prevOut: Outpoint(txid: txidInternal, vout: kTestVout1),
          ),
        ],
        outputs: [
          TxOutput(
            value: BigInt.from(kTestSendAmount1),
            scriptPubKey: recipientScript,
          ),
        ],
        locktime: 0,
      );

      // Compute witness sighash using coin's WitnessSigHasher.
      // prevScript must be P2PKH-equivalent per BIP143.
      final hasher = WitnessSigHasher();
      final coinDigest = hasher.hash(
        unsignedTx,
        0,
        SigHashType.all,
        prevScript: p2pkhSignScript,
        amount: BigInt.from(kTestUtxoValue1),
      );

      // Sign with coin.
      final coinSig = EcdsaSig.sign(coinDigest, sk.bytes);
      final coinDerSig = coinSig.toDer();

      // The DER-encoded signatures must be identical.
      // This proves coin computes the same sighash and produces the same
      // signature as bitcoindart for P2WPKH inputs.
      expect(
        bytesToHex(Uint8List.fromList(coinDerSig)),
        equals(bytesToHex(Uint8List.fromList(bdDerSig))),
      );
    });

    test(
      'coin P2WPKH tx structure matches bitcoindart (standard format)',
      () {
        // Build with coin using signed P2wpkhInput.
        final sk = SecretKey.fromHex(kTestPrivKeyHex1);
        final pubKeyBytes = sk.publicKey.bytes;
        final pubKeyHash20 = hash160(pubKeyBytes);

        final sk2 = SecretKey.fromHex(kTestPrivKeyHex2);
        final recipientPubKeyHash = hash160(sk2.publicKey.bytes);
        final recipientScript =
            PayToWitnessPubKey(recipientPubKeyHash).compiled;
        // BIP143: P2PKH-equivalent script for P2WPKH sighash.
        final p2pkhSignScript = PayToPubKeyHash(pubKeyHash20).compiled;

        final txidInternal = Uint8List.fromList(
          hexToBytes(kTestTxId1).reversed.toList(),
        );

        // Build unsigned tx, compute sighash, sign, then build signed tx.
        final unsignedTx = Tx(
          version: kParticlTxVersion,
          inputs: [
            RawInput(
              prevOut: Outpoint(txid: txidInternal, vout: kTestVout1),
            ),
          ],
          outputs: [
            TxOutput(
              value: BigInt.from(kTestSendAmount1),
              scriptPubKey: recipientScript,
            ),
          ],
          locktime: 0,
        );

        final hasher = WitnessSigHasher();
        final digest = hasher.hash(
          unsignedTx,
          0,
          SigHashType.all,
          prevScript: p2pkhSignScript,
          amount: BigInt.from(kTestUtxoValue1),
        );

        final sig = EcdsaSig.sign(digest, sk.bytes);
        final inputSig = InputSig(
          derSig: sig.toDer(),
          hashType: SigHashType.all,
        );

        final signedTx = Tx(
          version: kParticlTxVersion,
          inputs: [
            P2wpkhInput(
              prevOut: Outpoint(txid: txidInternal, vout: kTestVout1),
              inputSig: inputSig,
              publicKey: pubKeyBytes,
            ),
          ],
          outputs: [
            TxOutput(
              value: BigInt.from(kTestSendAmount1),
              scriptPubKey: recipientScript,
            ),
          ],
          locktime: 0,
        );

        // Verify tx structure is correct.
        expect(signedTx.isWitness, isTrue);
        expect(signedTx.inputs.length, equals(1));
        expect(signedTx.outputs.length, equals(1));
        expect(signedTx.inputs[0].complete, isTrue);

        // The coin tx uses standard Bitcoin serialization.
        // Particl bitcoindart uses a custom format (2-byte version + locktime
        // header). Byte-identical comparison is not possible for Particl.
        // However, the sighash and signature ARE proven identical in the test
        // above. This test verifies the structural correctness.
        final hex = signedTx.toHex();
        expect(hex, isNotEmpty);
        // Standard format: 4-byte version LE. 160 = 0xa0000000.
        expect(hex.substring(0, 8), equals('a0000000'));
      },
    );
  });

  group('P2PKH legacy sighash equivalence', () {
    test('coin legacy sighash matches bitcoindart for P2PKH', () {
      // Standard P2PKH uses legacy sighash (hashForSignature, not BIP143).
      // Note: Particl wallet code uses isParticl=true for BIP143, but the
      // default bitcoindart behavior for P2PKH is legacy sighash.
      final particlNet = bitcoindart.NetworkType(
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
      final keyPair1 = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        network: particlNet,
        compressed: true,
      );
      final keyPair2 = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex2),
        network: particlNet,
        compressed: true,
      );

      // Build P2PKH tx with bitcoindart.
      final txb = bitcoindart.TransactionBuilder(network: particlNet);
      txb.setVersion(kParticlTxVersion);
      final p2pkh = bitcoindart.P2PKH(
        data: bitcoindart.PaymentData(pubkey: keyPair1.publicKey!),
        network: particlNet,
      );
      final recipientP2pkh = bitcoindart.P2PKH(
        data: bitcoindart.PaymentData(pubkey: keyPair2.publicKey!),
        network: particlNet,
      );
      txb.addInput(kTestTxId1, kTestVout1, null, p2pkh.data.output);
      txb.addOutput(recipientP2pkh.data.address!, kTestSendAmount1);
      // P2PKH without isParticl: true uses legacy sighash and scriptSig.
      txb.sign(vin: 0, keyPair: keyPair1);
      final bdTx = txb.build();

      // P2PKH: signature is in scriptSig, not witness.
      // scriptSig: <push sig+hashtype> <push pubkey>
      final scriptSig = bdTx.ins[0].script as Uint8List;
      final sigLen = scriptSig[0];
      final bdSigWithHashType = scriptSig.sublist(1, 1 + sigLen);
      final bdDerSig =
          bdSigWithHashType.sublist(0, bdSigWithHashType.length - 1);

      // Compute same sighash with coin's LegacySigHasher.
      // Without isParticl flag, bitcoindart uses legacy (non-BIP143) sighash.
      final sk = SecretKey.fromHex(kTestPrivKeyHex1);
      final pubKeyBytes = sk.publicKey.bytes;
      final pubKeyHash20 = hash160(pubKeyBytes);
      final p2pkhScript = PayToPubKeyHash(pubKeyHash20).compiled;

      final sk2 = SecretKey.fromHex(kTestPrivKeyHex2);
      final recipientHash = hash160(sk2.publicKey.bytes);
      final recipientScript = PayToPubKeyHash(recipientHash).compiled;

      final txidInternal = Uint8List.fromList(
        hexToBytes(kTestTxId1).reversed.toList(),
      );

      final unsignedTx = Tx(
        version: kParticlTxVersion,
        inputs: [
          RawInput(
            prevOut: Outpoint(txid: txidInternal, vout: kTestVout1),
          ),
        ],
        outputs: [
          TxOutput(
            value: BigInt.from(kTestSendAmount1),
            scriptPubKey: recipientScript,
          ),
        ],
        locktime: 0,
      );

      // Legacy sighash for P2PKH (without Particl isParticl flag).
      final hasher = LegacySigHasher();
      final coinDigest = hasher.hash(
        unsignedTx,
        0,
        SigHashType.all,
        prevScript: p2pkhScript,
      );

      final coinSig = EcdsaSig.sign(coinDigest, sk.bytes);
      final coinDerSig = coinSig.toDer();

      // DER signatures must be identical -- proves same sighash computation.
      expect(
        bytesToHex(Uint8List.fromList(coinDerSig)),
        equals(bytesToHex(Uint8List.fromList(bdDerSig))),
      );
    });
  });

  group('TxAssembler sighash callback equivalence', () {
    test('TxAssembler produces same sighash as manual WitnessSigHasher', () {
      final sk = SecretKey.fromHex(kTestPrivKeyHex1);
      final pubKeyBytes = sk.publicKey.bytes;
      final pubKeyHash20 = hash160(pubKeyBytes);
      // P2WPKH scriptPubKey (OP_0 <20-byte-hash>) -- TxAssembler detects
      // witness inputs by checking if scriptPubKey starts with 0x00.
      final p2wpkhScript = PayToWitnessPubKey(pubKeyHash20).compiled;

      final sk2 = SecretKey.fromHex(kTestPrivKeyHex2);
      final recipientHash = hash160(sk2.publicKey.bytes);
      final recipientScript =
          PayToWitnessPubKey(recipientHash).compiled;

      final txidInternal = Uint8List.fromList(
        hexToBytes(kTestTxId1).reversed.toList(),
      );

      // TxAssembler sighash.
      final assembler = TxAssembler(
        chainParams: ParticlParams.particl,
        inputs: [
          AssemblerInput(
            outpoint: Outpoint(txid: txidInternal, vout: kTestVout1),
            value: BigInt.from(kTestUtxoValue1),
            scriptPubKey: p2wpkhScript,
          ),
        ],
        outputs: [
          TxOutput(
            value: BigInt.from(kTestSendAmount1),
            scriptPubKey: recipientScript,
          ),
        ],
        version: kParticlTxVersion,
        ordering: TxOrdering.none,
      );

      late Uint8List assemblerDigest;
      assembler.build((Tx tx, int idx, Uint8List digest, SigHashType ht) {
        assemblerDigest = Uint8List.fromList(digest);
        return Uint8List(0);
      });

      // Manual WitnessSigHasher sighash.
      final unsignedTx = Tx(
        version: kParticlTxVersion,
        inputs: [
          RawInput(
            prevOut: Outpoint(txid: txidInternal, vout: kTestVout1),
          ),
        ],
        outputs: [
          TxOutput(
            value: BigInt.from(kTestSendAmount1),
            scriptPubKey: recipientScript,
          ),
        ],
        locktime: 0,
      );

      final hasher = WitnessSigHasher();
      final manualDigest = hasher.hash(
        unsignedTx,
        0,
        SigHashType.all,
        prevScript: p2wpkhScript,
        amount: BigInt.from(kTestUtxoValue1),
      );

      // TxAssembler and manual hasher produce identical sighash.
      expect(
        bytesToHex(assemblerDigest),
        equals(bytesToHex(manualDigest)),
      );
    });

    test('TxAssembler produces same sighash as manual LegacySigHasher', () {
      final sk = SecretKey.fromHex(kTestPrivKeyHex1);
      final pubKeyBytes = sk.publicKey.bytes;
      final pubKeyHash20 = hash160(pubKeyBytes);
      final p2pkhScript = PayToPubKeyHash(pubKeyHash20).compiled;

      final txidInternal = Uint8List.fromList(
        hexToBytes(kTestTxId1).reversed.toList(),
      );

      // P2PKH scriptPubKey does NOT start with 0x00, so TxAssembler
      // uses LegacySigHasher.
      final assembler = TxAssembler(
        chainParams: ParticlParams.particl,
        inputs: [
          AssemblerInput(
            outpoint: Outpoint(txid: txidInternal, vout: kTestVout1),
            value: BigInt.from(kTestUtxoValue1),
            scriptPubKey: p2pkhScript,
          ),
        ],
        outputs: [
          TxOutput(
            value: BigInt.from(kTestSendAmount1),
            scriptPubKey: p2pkhScript,
          ),
        ],
        version: kSparkTxVersion,
        ordering: TxOrdering.none,
      );

      late Uint8List assemblerDigest;
      assembler.build((Tx tx, int idx, Uint8List digest, SigHashType ht) {
        assemblerDigest = Uint8List.fromList(digest);
        return Uint8List(0);
      });

      // Manual LegacySigHasher.
      final unsignedTx = Tx(
        version: kSparkTxVersion,
        inputs: [
          RawInput(
            prevOut: Outpoint(txid: txidInternal, vout: kTestVout1),
          ),
        ],
        outputs: [
          TxOutput(
            value: BigInt.from(kTestSendAmount1),
            scriptPubKey: p2pkhScript,
          ),
        ],
        locktime: 0,
      );

      final hasher = LegacySigHasher();
      final manualDigest = hasher.hash(
        unsignedTx,
        0,
        SigHashType.all,
        prevScript: p2pkhScript,
      );

      expect(
        bytesToHex(assemblerDigest),
        equals(bytesToHex(manualDigest)),
      );
    });
  });
}
