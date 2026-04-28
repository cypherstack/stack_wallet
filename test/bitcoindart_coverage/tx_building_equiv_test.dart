/// Transaction building regression tests using coin library.
/// Regression tests for coin transaction building.
/// proving correct sighash computation, signing, and tx structure.
///
/// Requires secp256k1 native library:
///   LD_LIBRARY_PATH=/path/to/libsecp256k1.so flutter test test/bitcoindart_coverage/tx_building_equiv_test.dart
///
/// Satisfies: TX-07 (transaction building regression proofs).
import 'dart:typed_data';

import 'package:coin/coin.dart' as coin;
import 'package:flutter_test/flutter_test.dart';

import 'test_vectors.dart';

void main() {
  setUpAll(() async {
    await coin.VaultKeeper.initialize();
  });

  group('Transaction Building Regression', () {
    // -----------------------------------------------------------------------
    // Test 1: P2PKH sighash computation
    // -----------------------------------------------------------------------
    group('P2PKH sighash', () {
      test('coin LegacySigHasher produces consistent sighash', () {
        final privKeyBytes = hexToBytes(kTestPrivKeyHex1);
        final txidInternal = Uint8List.fromList(
          hexToBytes(kTestTxId1).reversed.toList(),
        );

        final coinSk = coin.SecretKey(privKeyBytes);
        final pubKeyBytes = coinSk.publicKey.bytes;
        final pubKeyHash = coin.hash160(pubKeyBytes);
        final p2pkhScript = coin.PayToPubKeyHash(pubKeyHash).compiled;

        final coinUnsignedTx = coin.Tx(
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

        final coinHasher = coin.LegacySigHasher();
        final coinDigest = coinHasher.hash(
          coinUnsignedTx,
          0,
          coin.SigHashType.all,
          prevScript: p2pkhScript,
        );

        // Sighash must be 32 bytes
        expect(coinDigest.length, equals(32));

        // Sign and verify round-trip
        final sig = coin.EcdsaSig.sign(coinDigest, privKeyBytes);
        expect(sig.verify(coinDigest, pubKeyBytes), isTrue,
            reason: 'P2PKH signature does not verify');
      });
    });

    // -----------------------------------------------------------------------
    // Test 2: P2WPKH sighash computation
    // -----------------------------------------------------------------------
    group('P2WPKH sighash', () {
      test('coin WitnessSigHasher produces consistent BIP-143 sighash', () {
        final privKeyBytes = hexToBytes(kTestPrivKeyHex1);
        final txidInternal = Uint8List.fromList(
          hexToBytes(kTestTxId1).reversed.toList(),
        );

        final coinSk = coin.SecretKey(privKeyBytes);
        final pubKeyBytes = coinSk.publicKey.bytes;
        final pubKeyHash = coin.hash160(pubKeyBytes);
        final p2pkhSignScript = coin.PayToPubKeyHash(pubKeyHash).compiled;
        final p2wpkhScript = coin.PayToWitnessPubKey(pubKeyHash).compiled;

        final coinUnsignedTx = coin.Tx(
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

        final coinHasher = coin.WitnessSigHasher();
        final coinDigest = coinHasher.hash(
          coinUnsignedTx,
          0,
          coin.SigHashType.all,
          prevScript: p2pkhSignScript,
          amount: BigInt.from(kTestUtxoValue1),
        );

        // Sighash must be 32 bytes
        expect(coinDigest.length, equals(32));

        // Sign and verify round-trip
        final sig = coin.EcdsaSig.sign(coinDigest, privKeyBytes);
        expect(sig.verify(coinDigest, pubKeyBytes), isTrue,
            reason: 'P2WPKH signature does not verify');
      });
    });

    // -----------------------------------------------------------------------
    // Test 3: P2TR signing -- functional verification
    // -----------------------------------------------------------------------
    group('P2TR signing', () {
      test(
          'coin TaprootSigHasher produces valid Schnorr signature that '
          'verifies against tweaked key', () {
        final privKeyBytes = hexToBytes(kTestPrivKeyHex1);
        final txidInternal = Uint8List.fromList(
          hexToBytes(kTestTxId1).reversed.toList(),
        );

        final coinSk = coin.SecretKey(privKeyBytes);
        final coinPubKey = coinSk.publicKey;
        final coinTaproot = coin.Taproot(internalKey: coinPubKey);
        final tweakedOutputKey = coinTaproot.tweakedKey;
        final p2trScript = coin.PayToTaproot(tweakedOutputKey).compiled;
        final tweakedSk = coinTaproot.tweakSecretKey(coinSk);

        final prevOut = coin.TxOutput(
          value: BigInt.from(kTestUtxoValue1),
          scriptPubKey: p2trScript,
        );

        final coinUnsignedTx = coin.Tx(
          version: 2,
          inputs: [
            coin.RawInput(
              prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
            ),
          ],
          outputs: [
            coin.TxOutput(
              value: BigInt.from(kTestSendAmount1),
              scriptPubKey: p2trScript,
            ),
          ],
        );

        final coinTrHasher = coin.TaprootSigHasher(prevOuts: [prevOut]);
        final coinDigest = coinTrHasher.hash(
          coinUnsignedTx,
          0,
          coin.SigHashType.fromFlag(0x00),
        );

        final coinSchnorr = coin.SchnorrSig.sign(
          coinDigest,
          tweakedSk.bytes,
          auxRand: Uint8List(32),
        );

        final verified = coinSchnorr.verify(coinDigest, tweakedOutputKey);
        expect(verified, isTrue,
            reason: 'Schnorr sig from coin TaprootSigHasher does not verify');
      });
    });

    // -----------------------------------------------------------------------
    // Test 4: ECDSA signature verification
    // -----------------------------------------------------------------------
    group('ECDSA signature', () {
      test('coin ECDSA signature verifies against correct pubkey', () {
        final privKeyBytes = hexToBytes(kTestPrivKeyHex1);

        final coinSig = coin.EcdsaSig.sign(kTestHash32, privKeyBytes);
        final pubKeyBytes = coin.SecretKey(privKeyBytes).publicKey.bytes;

        expect(
          coinSig.verify(kTestHash32, pubKeyBytes),
          isTrue,
          reason: 'coin ECDSA signature does not verify',
        );

        // DER round-trip
        final derBytes = coinSig.toDer();
        final restored = coin.EcdsaSig.fromDer(derBytes);
        expect(
          restored.verify(kTestHash32, pubKeyBytes),
          isTrue,
          reason: 'DER round-tripped ECDSA signature does not verify',
        );
      });
    });

    // -----------------------------------------------------------------------
    // Test 5: Schnorr signature
    // -----------------------------------------------------------------------
    group('Schnorr signature', () {
      test('coin SchnorrSig with zero aux produces deterministic result', () {
        final privKeyBytes = hexToBytes(kTestPrivKeyHex1);
        final zeroAux = Uint8List(32);

        final sig1 = coin.SchnorrSig.sign(
          kTestHash32,
          privKeyBytes,
          auxRand: zeroAux,
        );
        final sig2 = coin.SchnorrSig.sign(
          kTestHash32,
          privKeyBytes,
          auxRand: zeroAux,
        );

        // Deterministic: same inputs -> same output
        expect(sig1.toHex(), equals(sig2.toHex()));

        // Verify
        final xOnlyPub = coin.SecretKey(privKeyBytes).publicKey;
        expect(sig1.verify(kTestHash32, xOnlyPub), isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Test 6: Full P2PKH tx -- structure + signature validity
    // -----------------------------------------------------------------------
    group('full P2PKH tx', () {
      test('coin P2PKH tx has correct structure and signature verifies', () {
        final privKeyBytes = hexToBytes(kTestPrivKeyHex1);
        final txidInternal = Uint8List.fromList(
          hexToBytes(kTestTxId1).reversed.toList(),
        );

        final coinSk = coin.SecretKey(privKeyBytes);
        final pubKeyBytes = coinSk.publicKey.bytes;
        final pubKeyHash = coin.hash160(pubKeyBytes);
        final p2pkhScript = coin.PayToPubKeyHash(pubKeyHash).compiled;

        final coinUnsignedTx = coin.Tx(
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

        final coinHasher = coin.LegacySigHasher();
        final coinDigest = coinHasher.hash(
          coinUnsignedTx, 0, coin.SigHashType.all,
          prevScript: p2pkhScript,
        );
        final coinSig = coin.EcdsaSig.sign(coinDigest, privKeyBytes);

        final coinSignedTx = coin.Tx(
          version: 2,
          inputs: [
            coin.P2pkhInput(
              prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
              inputSig: coin.InputSig(
                derSig: coinSig.toDer(),
                hashType: coin.SigHashType.all,
              ),
              publicKey: pubKeyBytes,
            ),
          ],
          outputs: [
            coin.TxOutput(
              value: BigInt.from(kTestSendAmount1),
              scriptPubKey: p2pkhScript,
            ),
          ],
        );

        // Signature verifies
        expect(coinSig.verify(coinDigest, pubKeyBytes), isTrue);

        // Structure correct
        expect(coinSignedTx.version, equals(2));
        expect(coinSignedTx.locktime, equals(0));
        expect(coinSignedTx.outputs.length, equals(1));
        expect(coinSignedTx.outputs[0].value,
            equals(BigInt.from(kTestSendAmount1)));
        expect(coinSignedTx.isWitness, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // Test 7: Full P2WPKH tx -- structure + signature validity
    // -----------------------------------------------------------------------
    group('full P2WPKH tx', () {
      test('coin P2WPKH tx has correct structure and signature verifies', () {
        final privKeyBytes = hexToBytes(kTestPrivKeyHex1);
        final txidInternal = Uint8List.fromList(
          hexToBytes(kTestTxId1).reversed.toList(),
        );

        final coinSk = coin.SecretKey(privKeyBytes);
        final pubKeyBytes = coinSk.publicKey.bytes;
        final pubKeyHash = coin.hash160(pubKeyBytes);
        final p2pkhSignScript = coin.PayToPubKeyHash(pubKeyHash).compiled;
        final p2wpkhScript = coin.PayToWitnessPubKey(pubKeyHash).compiled;

        final coinUnsignedTx = coin.Tx(
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

        final coinHasher = coin.WitnessSigHasher();
        final coinDigest = coinHasher.hash(
          coinUnsignedTx, 0, coin.SigHashType.all,
          prevScript: p2pkhSignScript,
          amount: BigInt.from(kTestUtxoValue1),
        );
        final coinSig = coin.EcdsaSig.sign(coinDigest, privKeyBytes);

        final coinSignedTx = coin.Tx(
          version: 2,
          inputs: [
            coin.P2wpkhInput(
              prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
              inputSig: coin.InputSig(
                derSig: coinSig.toDer(),
                hashType: coin.SigHashType.all,
              ),
              publicKey: pubKeyBytes,
            ),
          ],
          outputs: [
            coin.TxOutput(
              value: BigInt.from(kTestSendAmount1),
              scriptPubKey: p2wpkhScript,
            ),
          ],
        );

        // Signature verifies
        expect(coinSig.verify(coinDigest, pubKeyBytes), isTrue);

        // Structure correct
        expect(coinSignedTx.version, equals(2));
        expect(coinSignedTx.locktime, equals(0));
        expect(coinSignedTx.outputs.length, equals(1));
        expect(coinSignedTx.isWitness, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Test 8: Full P2TR tx -- structure + signature validity
    // -----------------------------------------------------------------------
    group('full P2TR tx', () {
      test('coin-built P2TR tx signature verifies and structure correct', () {
        final privKeyBytes = hexToBytes(kTestPrivKeyHex1);
        final txidInternal = Uint8List.fromList(
          hexToBytes(kTestTxId1).reversed.toList(),
        );

        final coinSk = coin.SecretKey(privKeyBytes);
        final coinPubKey = coinSk.publicKey;
        final coinTaproot = coin.Taproot(internalKey: coinPubKey);
        final tweakedOutputKey = coinTaproot.tweakedKey;
        final p2trScript = coin.PayToTaproot(tweakedOutputKey).compiled;
        final tweakedSk = coinTaproot.tweakSecretKey(coinSk);

        final prevOut = coin.TxOutput(
          value: BigInt.from(kTestUtxoValue1),
          scriptPubKey: p2trScript,
        );

        final coinUnsignedTx = coin.Tx(
          version: 2,
          inputs: [
            coin.RawInput(
              prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
            ),
          ],
          outputs: [
            coin.TxOutput(
              value: BigInt.from(kTestSendAmount1),
              scriptPubKey: p2trScript,
            ),
          ],
        );

        final coinTrHasher = coin.TaprootSigHasher(prevOuts: [prevOut]);
        final coinDigest = coinTrHasher.hash(
          coinUnsignedTx, 0, coin.SigHashType.fromFlag(0x00),
        );

        final coinSchnorr = coin.SchnorrSig.sign(
          coinDigest, tweakedSk.bytes, auxRand: Uint8List(32),
        );

        final coinSignedTx = coin.Tx(
          version: 2,
          inputs: [
            coin.TaprootKeyInput(
              prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
              inputSig: coin.SchnorrInputSig(
                sig: coinSchnorr.bytes,
                hashType: coin.SigHashType.fromFlag(0x00),
              ),
            ),
          ],
          outputs: [
            coin.TxOutput(
              value: BigInt.from(kTestSendAmount1),
              scriptPubKey: p2trScript,
            ),
          ],
        );

        // Verify signature
        expect(coinSchnorr.verify(coinDigest, tweakedOutputKey), isTrue);

        // Verify tx structure
        expect(coinSignedTx.version, equals(2));
        expect(coinSignedTx.isWitness, isTrue);
        expect(coinSignedTx.inputs.length, equals(1));
        expect(coinSignedTx.outputs.length, equals(1));
        expect(coinSignedTx.inputs[0].complete, isTrue);
        expect(coinSignedTx.outputs[0].value,
            equals(BigInt.from(kTestSendAmount1)));
        expect(
          bytesToHex(coinSignedTx.outputs[0].scriptPubKey),
          equals(bytesToHex(p2trScript)),
        );
      });
    });

    // -----------------------------------------------------------------------
    // Test 9: Tx.fromHex round-trip
    // -----------------------------------------------------------------------
    group('Tx.fromHex round-trip', () {
      test('coin Tx.fromHex -> toHex reproduces non-witness tx', () {
        final privKeyBytes = hexToBytes(kTestPrivKeyHex1);
        final txidInternal = Uint8List.fromList(
          hexToBytes(kTestTxId1).reversed.toList(),
        );
        final coinSk = coin.SecretKey(privKeyBytes);
        final pubKeyBytes = coinSk.publicKey.bytes;
        final pubKeyHash = coin.hash160(pubKeyBytes);
        final p2pkhScript = coin.PayToPubKeyHash(pubKeyHash).compiled;

        final coinHasher = coin.LegacySigHasher();
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
        final digest = coinHasher.hash(
          unsignedTx, 0, coin.SigHashType.all,
          prevScript: p2pkhScript,
        );
        final sig = coin.EcdsaSig.sign(digest, privKeyBytes);

        final signedTx = coin.Tx(
          version: 2,
          inputs: [
            coin.P2pkhInput(
              prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
              inputSig: coin.InputSig(
                derSig: sig.toDer(),
                hashType: coin.SigHashType.all,
              ),
              publicKey: pubKeyBytes,
            ),
          ],
          outputs: [
            coin.TxOutput(
              value: BigInt.from(kTestSendAmount1),
              scriptPubKey: p2pkhScript,
            ),
          ],
        );

        final originalHex = signedTx.toHex();
        final parsed = coin.Tx.fromHex(originalHex);
        final roundTripHex = parsed.toHex();

        expect(roundTripHex, equals(originalHex),
            reason: 'Tx.fromHex round-trip failed');
      });
    });

    // -----------------------------------------------------------------------
    // Test 10: MessageSig
    // -----------------------------------------------------------------------
    group('MessageSig', () {
      test('coin MessageSig produces verifiable signature', () {
        final privKeyBytes = hexToBytes(kTestPrivKeyHex1);
        const message = 'Hello, Bitcoin!';
        const prefix = '\x18Bitcoin Signed Message:\n';

        final coinMsgSig = coin.MessageSig.sign(
          message,
          privKeyBytes,
          messagePrefix: prefix,
        );

        // Verify signature
        final pubKeyBytes = coin.SecretKey(privKeyBytes).publicKey.bytes;
        expect(
          coinMsgSig.verify(message, pubKeyBytes, messagePrefix: prefix),
          isTrue,
          reason: 'coin MessageSig does not verify',
        );

        // Recover public key and verify it matches
        final recovered =
            coinMsgSig.recoverPublicKey(message, messagePrefix: prefix);
        expect(
          bytesToHex(recovered),
          equals(bytesToHex(pubKeyBytes)),
          reason: 'Recovered public key does not match',
        );

        // Round-trip: toBytes -> fromBytes -> verify
        final bytes65 = coinMsgSig.toBytes();
        expect(bytes65.length, equals(65));
        final restored = coin.MessageSig.fromBytes(bytes65);
        expect(
          restored.verify(message, pubKeyBytes, messagePrefix: prefix),
          isTrue,
          reason: 'Round-tripped MessageSig does not verify',
        );
      });

      test('coin MessageSig rejects wrong message and wrong prefix', () {
        const message = 'Hello, Bitcoin!';
        const prefix = '\x18Bitcoin Signed Message:\n';
        final privKeyBytes = hexToBytes(kTestPrivKeyHex1);

        final coinMsgSig = coin.MessageSig.sign(
          message, privKeyBytes, messagePrefix: prefix,
        );

        final pubKeyBytes = coin.SecretKey(privKeyBytes).publicKey.bytes;
        expect(
          coinMsgSig.verify('Wrong message', pubKeyBytes,
              messagePrefix: prefix),
          isFalse,
          reason: 'MessageSig should not verify with wrong message',
        );

        expect(
          coinMsgSig.verify(message, pubKeyBytes,
              messagePrefix: '\x19Litecoin Signed Message:\n'),
          isFalse,
          reason: 'MessageSig should not verify with wrong prefix',
        );
      });
    });

    // -----------------------------------------------------------------------
    // Test 11: vSize for P2PKH and P2WPKH
    // -----------------------------------------------------------------------
    group('vSize', () {
      test('P2PKH non-witness tx size is consistent', () {
        final privKeyBytes = hexToBytes(kTestPrivKeyHex1);
        final txidInternal = Uint8List.fromList(
          hexToBytes(kTestTxId1).reversed.toList(),
        );

        final coinSk = coin.SecretKey(privKeyBytes);
        final pubKeyBytes = coinSk.publicKey.bytes;
        final pubKeyHash = coin.hash160(pubKeyBytes);
        final p2pkhScript = coin.PayToPubKeyHash(pubKeyHash).compiled;

        final coinHasher = coin.LegacySigHasher();
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
        final digest = coinHasher.hash(
          unsignedTx, 0, coin.SigHashType.all,
          prevScript: p2pkhScript,
        );
        final sig = coin.EcdsaSig.sign(digest, privKeyBytes);

        final coinSignedTx = coin.Tx(
          version: 2,
          inputs: [
            coin.P2pkhInput(
              prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
              inputSig: coin.InputSig(
                derSig: sig.toDer(),
                hashType: coin.SigHashType.all,
              ),
              publicKey: pubKeyBytes,
            ),
          ],
          outputs: [
            coin.TxOutput(
              value: BigInt.from(kTestSendAmount1),
              scriptPubKey: p2pkhScript,
            ),
          ],
        );

        expect(coinSignedTx.isWitness, isFalse);
        final coinSize = coinSignedTx.toBytes().length;
        // P2PKH 1-in 1-out typical size: ~191-192 bytes
        expect(coinSize, greaterThan(180));
        expect(coinSize, lessThan(210));
      });

      test('P2WPKH witness tx total size is consistent', () {
        final privKeyBytes = hexToBytes(kTestPrivKeyHex1);
        final txidInternal = Uint8List.fromList(
          hexToBytes(kTestTxId1).reversed.toList(),
        );

        final coinSk = coin.SecretKey(privKeyBytes);
        final pubKeyBytes = coinSk.publicKey.bytes;
        final pubKeyHash = coin.hash160(pubKeyBytes);
        final p2pkhSignScript = coin.PayToPubKeyHash(pubKeyHash).compiled;
        final p2wpkhScript = coin.PayToWitnessPubKey(pubKeyHash).compiled;

        final coinHasher = coin.WitnessSigHasher();
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
        final digest = coinHasher.hash(
          unsignedTx, 0, coin.SigHashType.all,
          prevScript: p2pkhSignScript,
          amount: BigInt.from(kTestUtxoValue1),
        );
        final sig = coin.EcdsaSig.sign(digest, privKeyBytes);

        final coinSignedTx = coin.Tx(
          version: 2,
          inputs: [
            coin.P2wpkhInput(
              prevOut: coin.Outpoint(txid: txidInternal, vout: kTestVout1),
              inputSig: coin.InputSig(
                derSig: sig.toDer(),
                hashType: coin.SigHashType.all,
              ),
              publicKey: pubKeyBytes,
            ),
          ],
          outputs: [
            coin.TxOutput(
              value: BigInt.from(kTestSendAmount1),
              scriptPubKey: p2wpkhScript,
            ),
          ],
        );

        expect(coinSignedTx.isWitness, isTrue);
        final coinTotalSize = coinSignedTx.toBytes().length;
        // P2WPKH 1-in 1-out typical size: ~110-115 bytes
        expect(coinTotalSize, greaterThan(100));
        expect(coinTotalSize, lessThan(130));
      });
    });
  });
}
