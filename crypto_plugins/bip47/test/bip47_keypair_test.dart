import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip47/bip47.dart';
import 'package:coin/coin.dart' as coin;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';
import 'package:test/test.dart';

// Same Samourai vectors as bip47_test.dart.
const _kPath = "m/47'/0'/0'";

const _kSeedAlice =
    "response seminar brave tip suit recall often sound stick owner lottery mot"
    "ion";
const _kPaymentCodeAlice =
    "PM8TJTLJbPRGxSbc8EJi42Wrr6QbNSaSSVJ5Y3E4pbCYiTHUskHg13935Ubb7q8tx9GVbh2UuR"
    "nBc3WSyJHhUrw8KhprKnn9eDznYGieTzFcwQRya4GA";

const _kSeedBob =
    "reward upper indicate eight swift arch injury crystal super wrestle alread"
    "y dentist";
const _kPaymentCodeBob =
    "PM8TJS2JxQ5ztXUpBBRnpTbcUXbUHy2T1abfrb3KkAAtMEGNbey4oumH7Hc578WgQJhPjBxteQ"
    "5GHHToTYHE3A1w6p7tU6KSoFmWBVbFGjKPisZDbP97";

// Known P2PKH addresses for cross-check.
const _p2pkhAddresses = [
  '141fi7TY3h936vRUKh1qfUZr8rSBuYbVBK',
  '12u3Uued2fuko2nY4SoSFGCoGLCBUGPkk6',
  '1FsBVhT5dQutGwaPePTYMe5qvYqqjxyftc',
  '1CZAmrbKL6fJ7wUxb99aETwXhcGeG3CpeA',
  '1KQvRShk6NqPfpr4Ehd53XUhpemBXtJPTL',
];

void main() {
  late bip32.BIP32 bobBip32;
  late PaymentCode pCodeAlice;

  setUpAll(() async {
    await coin.initCoin();

    bobBip32 = bip32.BIP32
        .fromSeed(bip39.mnemonicToSeed(_kSeedBob))
        .derivePath(_kPath);
    pCodeAlice = PaymentCode.fromPaymentCode(
      _kPaymentCodeAlice,
      networkType: bitcoin,
    );
  });

  group('getReceiveAddressKeyPair record type', () {
    test('returns non-null privateKey and publicKey', () {
      final pa = PaymentAddress(
        paymentCode: pCodeAlice,
        bip32Node: bobBip32.derive(0),
        index: 0,
      );

      final pair = pa.getReceiveAddressKeyPair();
      expect(pair.privateKey, isNotNull);
      expect(pair.publicKey, isNotNull);
      expect(pair.privateKey.length, 32, reason: 'private key must be 32 bytes');
      expect(pair.publicKey.length, 33, reason: 'compressed pubkey must be 33 bytes');
    });

    test('publicKey starts with 02 or 03 (compressed)', () {
      for (int i = 0; i < 10; i++) {
        final pa = PaymentAddress(
          paymentCode: pCodeAlice,
          bip32Node: bobBip32.derive(i),
          index: 0,
        );

        final pair = pa.getReceiveAddressKeyPair();
        final prefix = pair.publicKey[0];
        expect(prefix == 0x02 || prefix == 0x03, isTrue,
            reason: 'index $i: pubkey prefix $prefix must be 02 or 03');
      }
    });

    test('privateKey derives matching publicKey via coin.SecretKey', () {
      for (int i = 0; i < 5; i++) {
        final pa = PaymentAddress(
          paymentCode: pCodeAlice,
          bip32Node: bobBip32.derive(i),
          index: 0,
        );

        final pair = pa.getReceiveAddressKeyPair();
        final sk = coin.SecretKey(pair.privateKey);
        expect(sk.publicKey.bytes, pair.publicKey,
            reason: 'index $i: SecretKey(privKey).publicKey must match pair.publicKey');
      }
    });

    test('publicKey hash160 produces correct P2PKH address', () {
      final btcChain = coin.Chain(
        wifPrefix: 0x80,
        p2pkhPrefix: 0x00,
        p2shPrefix: 0x05,
        bech32Hrp: 'bc',
        name: 'bitcoin',
        bip44CoinType: 0,
        privHDPrefix: 0x0488ade4,
        pubHDPrefix: 0x0488b21e,
      );

      for (int i = 0; i < 5; i++) {
        final pa = PaymentAddress(
          paymentCode: pCodeAlice,
          bip32Node: bobBip32.derive(i),
          index: 0,
        );

        final pair = pa.getReceiveAddressKeyPair();
        final pkHash = coin.hash160(pair.publicKey);
        final addr = coin.P2pkhAddr(pkHash).encode(btcChain);

        expect(addr, _p2pkhAddresses[i],
            reason: 'index $i: address from key pair must match known vector');
      }
    });

    test('publicKey hash160 produces correct P2WPKH address', () {
      final btcChain = coin.Chain(
        wifPrefix: 0x80,
        p2pkhPrefix: 0x00,
        p2shPrefix: 0x05,
        bech32Hrp: 'bc',
        name: 'bitcoin',
        bip44CoinType: 0,
        privHDPrefix: 0x0488ade4,
        pubHDPrefix: 0x0488b21e,
      );

      for (int i = 0; i < 5; i++) {
        final pa = PaymentAddress(
          paymentCode: pCodeAlice,
          bip32Node: bobBip32.derive(i),
          index: 0,
        );

        final pair = pa.getReceiveAddressKeyPair();
        final pkHash = coin.hash160(pair.publicKey);
        final addrFromPair = coin.P2wpkhAddr(pkHash).encode(btcChain);

        // Cross-check with getReceiveAddressP2WPKH
        final addrFromMethod = pa.getReceiveAddressP2WPKH();
        expect(addrFromPair, addrFromMethod,
            reason: 'index $i: address from key pair must equal getReceiveAddressP2WPKH');
      }
    });
  });

  group('getReceiveAddressKeyPair signing', () {
    test('private key produces valid ECDSA signature', () {
      final curveParams = ECDomainParameters('secp256k1');

      for (int i = 0; i < 3; i++) {
        final pa = PaymentAddress(
          paymentCode: pCodeAlice,
          bip32Node: bobBip32.derive(i),
          index: 0,
        );

        final pair = pa.getReceiveAddressKeyPair();

        // Build EC keys from raw bytes
        final d = BigInt.parse(
          pair.privateKey
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join(),
          radix: 16,
        );
        final privKey = ECPrivateKey(d, curveParams);
        final pubPoint = curveParams.curve.decodePoint(pair.publicKey);
        final pubKey = ECPublicKey(pubPoint, curveParams);

        // Sign a dummy 32-byte hash
        final hash = Uint8List(32);
        for (int j = 0; j < 32; j++) hash[j] = (i * 37 + j) & 0xff;

        final signer = Signer('SHA-256/DET-ECDSA');
        signer.init(true, PrivateKeyParameter<ECPrivateKey>(privKey));
        final sig = signer.generateSignature(hash) as ECSignature;

        // Verify
        final verifier = Signer('SHA-256/DET-ECDSA');
        verifier.init(false, PublicKeyParameter<ECPublicKey>(pubKey));
        expect(verifier.verifySignature(hash, sig), isTrue,
            reason: 'index $i: signature must verify with the key pair');
      }
    });

    test('different indices produce different key pairs', () {
      final pairs = <({Uint8List privateKey, Uint8List publicKey})>[];
      for (int i = 0; i < 5; i++) {
        final pa = PaymentAddress(
          paymentCode: pCodeAlice,
          bip32Node: bobBip32.derive(i),
          index: 0,
        );
        pairs.add(pa.getReceiveAddressKeyPair());
      }

      // All private keys should be unique
      final privKeyHexes = pairs
          .map((p) => p.privateKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join())
          .toSet();
      expect(privKeyHexes.length, 5, reason: 'all 5 private keys must be unique');

      // All public keys should be unique
      final pubKeyHexes = pairs
          .map((p) => p.publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join())
          .toSet();
      expect(pubKeyHexes.length, 5, reason: 'all 5 public keys must be unique');
    });
  });
}
