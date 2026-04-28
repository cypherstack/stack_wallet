// Coverage tests for bitcoindart PaymentData/P2PKH/P2WPKH/P2SH and Address API.
// Commented out: bitcoindart is no longer a direct dependency.
// Kept as historical reference for the original API patterns.
// See equivalence test files (*_equiv_test.dart) for the active coin regression suite.

/*
import 'dart:typed_data';

import 'package:bitcoindart/bitcoindart.dart' as bitcoindart;
import 'package:flutter_test/flutter_test.dart';

import 'test_vectors.dart';

/// bitcoindart PaymentData (P2PKH/P2WPKH/P2SH-P2WPKH) construction and
/// Address.addressToOutputScript coverage tests.
///
/// These tests validate that bitcoindart produces the correct scriptPubKey
/// bytes for all three standard derive-path types (BIP44, BIP84, BIP49),
/// matching the patterns used in particl_wallet.dart, spark_interface.dart,
/// and paynym_interface.dart.
void main() {
  // Particl mainnet network type (matches test_vectors constants).
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

  // Firo mainnet network type.
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

  // Derive the compressed public key from the test private key.
  late final Uint8List pubKey;

  setUpAll(() {
    final keyPair = bitcoindart.ECPair.fromPrivateKey(
      hexToBytes(kTestPrivKeyHex1),
      network: particlNet,
      compressed: true,
    );
    pubKey = keyPair.publicKey!;
    // Sanity: the derived pubkey must match the known test vector.
    expect(bytesToHex(pubKey), equals(kTestPubKeyHex1));
  });

  group('P2PKH (BIP44) PaymentData', () {
    test('produces valid 25-byte scriptPubKey for Particl', () {
      final p2pkh = bitcoindart.P2PKH(
        data: bitcoindart.PaymentData(pubkey: pubKey),
        network: particlNet,
      );
      final script = p2pkh.data.output!;

      // P2PKH: OP_DUP OP_HASH160 <20-byte-hash160> OP_EQUALVERIFY OP_CHECKSIG
      expect(script.length, equals(25));
      expect(script[0], equals(0x76)); // OP_DUP
      expect(script[1], equals(0xa9)); // OP_HASH160
      expect(script[2], equals(0x14)); // push 20 bytes
      expect(script[23], equals(0x88)); // OP_EQUALVERIFY
      expect(script[24], equals(0xac)); // OP_CHECKSIG
    });

    test('produces same scriptPubKey structure on Firo network', () {
      final p2pkhParticl = bitcoindart.P2PKH(
        data: bitcoindart.PaymentData(pubkey: pubKey),
        network: particlNet,
      );
      final p2pkhFiro = bitcoindart.P2PKH(
        data: bitcoindart.PaymentData(pubkey: pubKey),
        network: firoNet,
      );

      final scriptParticl = p2pkhParticl.data.output!;
      final scriptFiro = p2pkhFiro.data.output!;

      // The scriptPubKey only depends on the pubkey hash, not the network.
      // Both networks should produce identical output scripts.
      expect(scriptFiro, equals(scriptParticl));

      // But the addresses differ (different version byte).
      expect(
        p2pkhFiro.data.address,
        isNot(equals(p2pkhParticl.data.address)),
      );
    });
  });

  group('P2WPKH (BIP84) PaymentData', () {
    test('produces valid 22-byte witness scriptPubKey for Particl', () {
      final p2wpkh = bitcoindart.P2WPKH(
        data: bitcoindart.PaymentData(pubkey: pubKey),
        network: particlNet,
      );
      final script = p2wpkh.data.output!;

      // P2WPKH: OP_0 <20-byte-hash160>
      expect(script.length, equals(22));
      expect(script[0], equals(0x00)); // witness version 0
      expect(script[1], equals(0x14)); // push 20 bytes
    });
  });

  group('P2SH-P2WPKH (BIP49) PaymentData', () {
    test('produces valid 23-byte P2SH scriptPubKey wrapping P2WPKH', () {
      final p2wpkh = bitcoindart.P2WPKH(
        data: bitcoindart.PaymentData(pubkey: pubKey),
        network: particlNet,
      );
      final p2sh = bitcoindart.P2SH(
        data: bitcoindart.PaymentData(redeem: p2wpkh.data),
        network: particlNet,
      );
      final script = p2sh.data.output!;

      // P2SH: OP_HASH160 <20-byte-hash160-of-redeemscript> OP_EQUAL
      expect(script.length, equals(23));
      expect(script[0], equals(0xa9)); // OP_HASH160
      expect(script[1], equals(0x14)); // push 20 bytes
      expect(script[22], equals(0x87)); // OP_EQUAL
    });
  });

  group('Address.addressToOutputScript', () {
    test('converts bech32 address to witness scriptPubKey', () {
      final p2wpkh = bitcoindart.P2WPKH(
        data: bitcoindart.PaymentData(pubkey: pubKey),
        network: particlNet,
      );
      final address = p2wpkh.data.address!;

      // Sanity: bech32 address should start with Particl HRP.
      expect(address, startsWith(kParticlBech32));

      // For non-standard HRPs (Particl uses 'pw', not 'bc'/'tb'),
      // addressToOutputScript requires the overridePrefix parameter.
      final outputScript = bitcoindart.Address.addressToOutputScript(
        address,
        particlNet,
        kParticlBech32,
      );

      // Round-trip: addressToOutputScript must produce the same script.
      expect(outputScript, equals(p2wpkh.data.output));
    });

    test('converts P2PKH address to legacy scriptPubKey', () {
      final p2pkh = bitcoindart.P2PKH(
        data: bitcoindart.PaymentData(pubkey: pubKey),
        network: particlNet,
      );
      final address = p2pkh.data.address!;

      final outputScript = bitcoindart.Address.addressToOutputScript(
        address,
        particlNet,
      );

      // Round-trip: must match the original scriptPubKey.
      expect(outputScript, equals(p2pkh.data.output));
    });
  });
}
*/
