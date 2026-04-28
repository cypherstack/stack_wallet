// Coverage tests for bitcoindart TransactionBuilder API.
// Commented out: bitcoindart is no longer a direct dependency.
// Kept as historical reference for the original API patterns.
// See equivalence test files (*_equiv_test.dart) for the active coin regression suite.

/*
/// bitcoindart TransactionBuilder coverage tests for Particl and Spark
/// transaction building patterns.
///
/// Covers:
///   - Particl P2WPKH (BIP84) tx with version=160
///   - Particl P2PKH (BIP44) legacy tx
///   - Particl P2SH-P2WPKH (BIP49) wrapped witness tx
///   - Spark dummy tx for fee estimation with version=589827
///   - Deterministic tx building (same inputs produce identical hex)
///
/// Satisfies: TEST-01 (Particl TransactionBuilder), TEST-02 (Spark
/// TransactionBuilder).
import 'dart:typed_data';

import 'package:bitcoindart/bitcoindart.dart' as bitcoindart;
import 'package:flutter_test/flutter_test.dart';

import 'test_vectors.dart';

void main() {
  late bitcoindart.NetworkType particlNet;
  late bitcoindart.ECPair keyPair1;
  late bitcoindart.ECPair keyPair2;

  setUp(() {
    particlNet = bitcoindart.NetworkType(
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
    keyPair1 = bitcoindart.ECPair.fromPrivateKey(
      hexToBytes(kTestPrivKeyHex1),
      network: particlNet,
      compressed: true,
    );
    keyPair2 = bitcoindart.ECPair.fromPrivateKey(
      hexToBytes(kTestPrivKeyHex2),
      network: particlNet,
      compressed: true,
    );
  });

  group('Particl TransactionBuilder - P2WPKH (BIP84)', () {
    test('builds valid tx with version=160', () {
      final txb = bitcoindart.TransactionBuilder(network: particlNet);
      txb.setVersion(kParticlTxVersion); // 160

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

      // Use the second key's P2WPKH address as recipient.
      final recipientP2wpkh = bitcoindart.P2WPKH(
        data: bitcoindart.PaymentData(pubkey: keyPair2.publicKey!),
        network: particlNet,
      );
      final recipientAddress = recipientP2wpkh.data.address!;

      txb.addOutput(recipientAddress, kTestSendAmount1, kParticlBech32);

      txb.sign(
        vin: 0,
        keyPair: keyPair1,
        witnessValue: kTestUtxoValue1,
        overridePrefix: kParticlBech32,
      );

      final tx = txb.build(kParticlBech32);
      final hex = tx.toHex(isParticl: true);

      expect(hex, isNotEmpty);
      // Particl serialization: 2-byte version LE + 4-byte locktime.
      // Version 160 = 0xa0 -> LE 2 bytes = a0 00.
      // Locktime 0 = 00 00 00 00.
      // First 8 hex chars = a0000000 (version a000 + first 2 bytes of locktime).
      expect(hex.substring(0, 8), equals('a0000000'));
      expect(tx.ins.length, equals(1));
      expect(tx.outs.length, equals(1));
    });

    test('tx hex is deterministic for same inputs', () {
      String buildTx() {
        final txb = bitcoindart.TransactionBuilder(network: particlNet);
        txb.setVersion(kParticlTxVersion);
        final p2wpkh = bitcoindart.P2WPKH(
          data: bitcoindart.PaymentData(pubkey: keyPair1.publicKey!),
          network: particlNet,
        );
        final recipientP2wpkh = bitcoindart.P2WPKH(
          data: bitcoindart.PaymentData(pubkey: keyPair2.publicKey!),
          network: particlNet,
        );
        txb.addInput(
          kTestTxId1,
          kTestVout1,
          null,
          p2wpkh.data.output,
          kParticlBech32,
        );
        txb.addOutput(
          recipientP2wpkh.data.address!,
          kTestSendAmount1,
          kParticlBech32,
        );
        txb.sign(
          vin: 0,
          keyPair: keyPair1,
          witnessValue: kTestUtxoValue1,
          overridePrefix: kParticlBech32,
        );
        return txb.build(kParticlBech32).toHex(isParticl: true);
      }

      expect(buildTx(), equals(buildTx()));
    });

    test('built transaction can be decoded with correct structure', () {
      final txb = bitcoindart.TransactionBuilder(network: particlNet);
      txb.setVersion(kParticlTxVersion);
      final p2wpkh = bitcoindart.P2WPKH(
        data: bitcoindart.PaymentData(pubkey: keyPair1.publicKey!),
        network: particlNet,
      );
      final recipientP2wpkh = bitcoindart.P2WPKH(
        data: bitcoindart.PaymentData(pubkey: keyPair2.publicKey!),
        network: particlNet,
      );
      txb.addInput(
        kTestTxId1,
        kTestVout1,
        null,
        p2wpkh.data.output,
        kParticlBech32,
      );
      txb.addOutput(
        recipientP2wpkh.data.address!,
        kTestSendAmount1,
        kParticlBech32,
      );
      txb.sign(
        vin: 0,
        keyPair: keyPair1,
        witnessValue: kTestUtxoValue1,
        overridePrefix: kParticlBech32,
      );

      final tx = txb.build(kParticlBech32);
      expect(tx.version, equals(kParticlTxVersion));
      expect(tx.ins.length, equals(1));
      expect(tx.outs.length, equals(1));
      expect(tx.outs[0].value, equals(kTestSendAmount1));
    });
  });

  group('Particl TransactionBuilder - P2PKH (BIP44)', () {
    test('builds valid legacy tx', () {
      final txb = bitcoindart.TransactionBuilder(network: particlNet);
      txb.setVersion(kParticlTxVersion);

      final p2pkh = bitcoindart.P2PKH(
        data: bitcoindart.PaymentData(pubkey: keyPair1.publicKey!),
        network: particlNet,
      );

      txb.addInput(
        kTestTxId1,
        kTestVout1,
        null,
        p2pkh.data.output,
      );

      // Output to a P2PKH address (legacy).
      final recipientP2pkh = bitcoindart.P2PKH(
        data: bitcoindart.PaymentData(pubkey: keyPair2.publicKey!),
        network: particlNet,
      );

      txb.addOutput(recipientP2pkh.data.address!, kTestSendAmount1);

      txb.sign(
        vin: 0,
        keyPair: keyPair1,
      );

      final tx = txb.build();
      final hex = tx.toHex(isParticl: true);

      expect(hex, isNotEmpty);
      // Particl format: version a000 + locktime 00000000 at start.
      expect(hex.substring(0, 8), equals('a0000000'));
      expect(tx.ins.length, equals(1));
      expect(tx.outs.length, equals(1));
      // Legacy tx has no witness data.
      expect(
        tx.ins[0].witness == null || tx.ins[0].witness!.isEmpty,
        isTrue,
      );
    });
  });

  group('Particl TransactionBuilder - P2SH-P2WPKH (BIP49)', () {
    test('builds valid P2SH-wrapped witness tx', () {
      final txb = bitcoindart.TransactionBuilder(network: particlNet);
      txb.setVersion(kParticlTxVersion);

      // Create P2WPKH payment data, then wrap in P2SH.
      final p2wpkh = bitcoindart.P2WPKH(
        data: bitcoindart.PaymentData(pubkey: keyPair1.publicKey!),
        network: particlNet,
      );

      txb.addInput(
        kTestTxId1,
        kTestVout1,
        null,
        bitcoindart.P2SH(
          data: bitcoindart.PaymentData(redeem: p2wpkh.data),
          network: particlNet,
        ).data.output,
        kParticlBech32,
      );

      final recipientP2wpkh = bitcoindart.P2WPKH(
        data: bitcoindart.PaymentData(pubkey: keyPair2.publicKey!),
        network: particlNet,
      );

      txb.addOutput(
        recipientP2wpkh.data.address!,
        kTestSendAmount1,
        kParticlBech32,
      );

      // P2SH-P2WPKH sign requires redeemScript (the P2WPKH output script)
      // and witnessValue.
      txb.sign(
        vin: 0,
        keyPair: keyPair1,
        redeemScript: p2wpkh.data.output,
        witnessValue: kTestUtxoValue1,
        overridePrefix: kParticlBech32,
      );

      final tx = txb.build(kParticlBech32);
      final hex = tx.toHex(isParticl: true);

      expect(hex, isNotEmpty);
      expect(hex.substring(0, 8), equals('a0000000'));
      expect(tx.ins.length, equals(1));
      expect(tx.outs.length, equals(1));
      // P2SH-P2WPKH has witness data.
      expect(tx.ins[0].witness, isNotNull);
      expect(tx.ins[0].witness!.isNotEmpty, isTrue);
    });
  });

  group('Spark TransactionBuilder', () {
    late bitcoindart.NetworkType firoNet;
    late bitcoindart.ECPair firoKeyPair;

    setUp(() {
      firoNet = bitcoindart.NetworkType(
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
      firoKeyPair = bitcoindart.ECPair.fromPrivateKey(
        hexToBytes(kTestPrivKeyHex1),
        network: firoNet,
        compressed: true,
      );
    });

    test('builds dummy tx for fee estimation with version=589827', () {
      final txb = bitcoindart.TransactionBuilder(network: firoNet);
      txb.setVersion(kSparkTxVersion); // 589827

      // Firo typically uses P2PKH for transparent inputs.
      final p2pkh = bitcoindart.P2PKH(
        data: bitcoindart.PaymentData(pubkey: firoKeyPair.publicKey!),
        network: firoNet,
      );

      txb.addInput(kTestTxId1, kTestVout1, null, p2pkh.data.output);
      txb.addOutput(p2pkh.data.output!, kTestSendAmount1);

      txb.sign(vin: 0, keyPair: firoKeyPair);

      final tx = txb.build();
      final hex = tx.toHex();

      expect(hex, isNotEmpty);
      // Version 589827 = 0x00090003 in 4-byte LE: 03000900.
      expect(hex.substring(0, 8), equals('03000900'));
      expect(tx.ins.length, equals(1));
      expect(tx.outs.length, equals(1));
    });

    test('Spark tx with locktime from block height', () {
      final txb = bitcoindart.TransactionBuilder(network: firoNet);
      txb.setVersion(kSparkTxVersion);
      txb.setLockTime(800000); // Example block height.

      final p2pkh = bitcoindart.P2PKH(
        data: bitcoindart.PaymentData(pubkey: firoKeyPair.publicKey!),
        network: firoNet,
      );

      txb.addInput(
        kTestTxId1,
        kTestVout1,
        0xffffffff - 1, // Sequence must be < 0xffffffff for locktime.
        p2pkh.data.output,
      );
      txb.addOutput(p2pkh.data.output!, kTestSendAmount1);

      txb.sign(vin: 0, keyPair: firoKeyPair);

      final tx = txb.build();
      final hex = tx.toHex();

      expect(hex, isNotEmpty);
      expect(hex.substring(0, 8), equals('03000900'));
      expect(tx.locktime, equals(800000));
      expect(tx.ins.length, equals(1));
      expect(tx.outs.length, equals(1));
    });

    test('Spark tx hex is deterministic', () {
      String buildSparkTx() {
        final txb = bitcoindart.TransactionBuilder(network: firoNet);
        txb.setVersion(kSparkTxVersion);
        final p2pkh = bitcoindart.P2PKH(
          data: bitcoindart.PaymentData(pubkey: firoKeyPair.publicKey!),
          network: firoNet,
        );
        txb.addInput(kTestTxId1, kTestVout1, null, p2pkh.data.output);
        txb.addOutput(p2pkh.data.output!, kTestSendAmount1);
        txb.sign(vin: 0, keyPair: firoKeyPair);
        return txb.build().toHex();
      }

      expect(buildSparkTx(), equals(buildSparkTx()));
    });
  });
}
*/
