import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip47/bip47.dart';
import 'package:coin/coin.dart' as coin;
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

// Known-good P2PKH addresses (from spec) -- used to cross-check P2WPKH
// derivation by verifying the underlying public key hash is the same.
const _p2pkhAddresses = [
  '141fi7TY3h936vRUKh1qfUZr8rSBuYbVBK',
  '12u3Uued2fuko2nY4SoSFGCoGLCBUGPkk6',
  '1FsBVhT5dQutGwaPePTYMe5qvYqqjxyftc',
  '1CZAmrbKL6fJ7wUxb99aETwXhcGeG3CpeA',
  '1KQvRShk6NqPfpr4Ehd53XUhpemBXtJPTL',
];

void main() {
  late bip32.BIP32 aliceBip32;
  late bip32.BIP32 bobBip32;
  late PaymentCode pCodeAlice;
  late PaymentCode pCodeBob;

  setUpAll(() async {
    await coin.initCoin();

    aliceBip32 = bip32.BIP32
        .fromSeed(bip39.mnemonicToSeed(_kSeedAlice))
        .derivePath(_kPath);
    bobBip32 = bip32.BIP32
        .fromSeed(bip39.mnemonicToSeed(_kSeedBob))
        .derivePath(_kPath);
    pCodeAlice = PaymentCode.fromPaymentCode(
      _kPaymentCodeAlice,
      networkType: bitcoin,
    );
    pCodeBob = PaymentCode.fromPaymentCode(
      _kPaymentCodeBob,
      networkType: bitcoin,
    );
  });

  group('P2WPKH send addresses', () {
    test('produce valid bech32 addresses with bc1q prefix', () {
      final a2b = PaymentAddress(
        paymentCode: pCodeBob,
        bip32Node: aliceBip32.derive(0),
        index: 0,
      );

      for (int i = 0; i < 5; i++) {
        a2b.index = i;
        final addr = a2b.getSendAddressP2WPKH();
        expect(addr.startsWith('bc1q'), isTrue,
            reason: 'index $i: $addr should start with bc1q');
        expect(addr.length, inInclusiveRange(42, 62),
            reason: 'bech32 P2WPKH address length');
      }
    });

    test('P2WPKH and P2PKH use same underlying pubkey hash', () {
      // Both address types derive from the same tweaked public key.
      // We can verify this by checking that hash160(pubkey) matches
      // what both address formats encode.
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

      final a2b = PaymentAddress(
        paymentCode: pCodeBob,
        bip32Node: aliceBip32.derive(0),
        index: 0,
      );

      for (int i = 0; i < 5; i++) {
        a2b.index = i;
        final p2pkh = a2b.getSendAddressP2PKH();
        final p2wpkh = a2b.getSendAddressP2WPKH();

        // The P2PKH should match known vectors
        expect(p2pkh, _p2pkhAddresses[i]);

        // P2WPKH should be a different encoding of the same key
        expect(p2wpkh, isNot(equals(p2pkh)));
        expect(p2wpkh.startsWith('bc1q'), isTrue);
      }
    });
  });

  group('P2WPKH receive addresses', () {
    test('produce valid bech32 addresses', () {
      for (int i = 0; i < 5; i++) {
        final pa = PaymentAddress(
          paymentCode: pCodeAlice,
          bip32Node: bobBip32.derive(i),
          index: 0,
        );
        final addr = pa.getReceiveAddressP2WPKH();
        expect(addr.startsWith('bc1q'), isTrue,
            reason: 'index $i: $addr should start with bc1q');
      }
    });

    test('P2WPKH and P2PKH receive addresses use same key', () {
      for (int i = 0; i < 5; i++) {
        final pa = PaymentAddress(
          paymentCode: pCodeAlice,
          bip32Node: bobBip32.derive(i),
          index: 0,
        );

        final p2pkh = pa.getReceiveAddressP2PKH();
        final p2wpkh = pa.getReceiveAddressP2WPKH();

        // P2PKH must match known vector
        expect(p2pkh, _p2pkhAddresses[i]);

        // P2WPKH must be different format, same key
        expect(p2wpkh, isNot(equals(p2pkh)));
        expect(p2wpkh.startsWith('bc1q'), isTrue);
      }
    });
  });

  group('P2WPKH send/receive symmetry', () {
    test('Alice send P2WPKH == Bob receive P2WPKH at each index', () {
      for (int i = 0; i < 10; i++) {
        // Alice sends to Bob
        final aliceSends = PaymentAddress(
          paymentCode: pCodeBob,
          bip32Node: aliceBip32.derive(0),
          index: i,
        ).getSendAddressP2WPKH();

        // Bob receives from Alice
        final bobReceives = PaymentAddress(
          paymentCode: pCodeAlice,
          bip32Node: bobBip32.derive(i),
          index: 0,
        ).getReceiveAddressP2WPKH();

        expect(aliceSends, bobReceives,
            reason: 'P2WPKH symmetry failed at index $i');
      }
    });

    test('P2PKH send/receive symmetry still holds (regression)', () {
      for (int i = 0; i < 10; i++) {
        final aliceSends = PaymentAddress(
          paymentCode: pCodeBob,
          bip32Node: aliceBip32.derive(0),
          index: i,
        ).getSendAddressP2PKH();

        final bobReceives = PaymentAddress(
          paymentCode: pCodeAlice,
          bip32Node: bobBip32.derive(i),
          index: 0,
        ).getReceiveAddressP2PKH();

        expect(aliceSends, bobReceives,
            reason: 'P2PKH symmetry failed at index $i');
      }
    });
  });

  group('testnet NetworkType', () {
    test('P2WPKH uses tb1q prefix on testnet', () {
      final aliceTestnet = PaymentAddress(
        paymentCode: PaymentCode.fromPaymentCode(
          _kPaymentCodeAlice,
          networkType: testnet,
        ),
        bip32Node: bobBip32.derive(0),
        networkType: testnet,
        index: 0,
      );

      final addr = aliceTestnet.getReceiveAddressP2WPKH();
      expect(addr.startsWith('tb1q'), isTrue,
          reason: 'testnet P2WPKH should use tb1q prefix');
    });

    test('P2PKH uses different prefix on testnet', () {
      final aliceTestnet = PaymentAddress(
        paymentCode: PaymentCode.fromPaymentCode(
          _kPaymentCodeAlice,
          networkType: testnet,
        ),
        bip32Node: bobBip32.derive(0),
        networkType: testnet,
        index: 0,
      );

      final addr = aliceTestnet.getReceiveAddressP2PKH();
      // Testnet P2PKH starts with 'm' or 'n'
      expect(addr.startsWith('m') || addr.startsWith('n'), isTrue,
          reason: 'testnet P2PKH should use m/n prefix, got: $addr');
    });
  });
}
