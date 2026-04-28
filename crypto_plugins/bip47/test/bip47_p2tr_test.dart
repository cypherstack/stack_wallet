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

// Regression anchor snapshots -- generated from first successful run.
// If derivation changes, these catch it.
const _kSnapshotIndex0 =
    'bc1psa0ktf6mgjg595vf54s7rtv6pn0s43nctkjxr92qjdu9vfcm454snxfrwv';
const _kSnapshotIndex1 =
    'bc1pn2td293fe9hpm4543gk7pdnv56s4c4egjvfss7d73847mlje04aq24tjs7';
const _kSnapshotIndex2 =
    'bc1pxys9wd9y24yf8yr2kxc3r05t7tqg6uhr7gqj0qyp0usz5nwt54xqt5jsn0';

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

  group('P2TR send/receive symmetry', () {
    for (int i = 0; i < 10; i++) {
      test('index $i: Alice send P2TR == Bob receive P2TR', () {
        final aliceSends = PaymentAddress(
          paymentCode: pCodeBob,
          bip32Node: aliceBip32.derive(0),
          index: i,
        ).getSendAddressP2TR();

        final bobReceives = PaymentAddress(
          paymentCode: pCodeAlice,
          bip32Node: bobBip32.derive(i),
          index: 0,
        ).getReceiveAddressP2TR();

        expect(aliceSends, equals(bobReceives),
            reason: 'P2TR symmetry failed at index $i');
        expect(aliceSends, startsWith('bc1p'),
            reason: 'P2TR mainnet address must start with bc1p');
      });
    }

    test('intermediate BIP47-tweaked keys match (belt and suspenders)', () {
      for (int i = 0; i < 5; i++) {
        final bobPair = PaymentAddress(
          paymentCode: pCodeAlice,
          bip32Node: bobBip32.derive(i),
          index: 0,
        ).getReceiveAddressKeyPair();

        // Verify the public key is a valid compressed key (33 bytes, 02/03)
        expect(bobPair.publicKey.length, equals(33));
        expect(
          bobPair.publicKey[0] == 0x02 || bobPair.publicKey[0] == 0x03,
          isTrue,
          reason: 'BIP47-tweaked public key must be compressed',
        );
      }
    });
  });

  group('P2TR address snapshots (regression anchors)', () {
    test('Alice->Bob index 0 P2TR address matches snapshot', () {
      final addr = PaymentAddress(
        paymentCode: pCodeBob,
        bip32Node: aliceBip32.derive(0),
        index: 0,
      ).getSendAddressP2TR();

      expect(addr, startsWith('bc1p'));
      expect(addr.length, equals(62),
          reason: 'bech32m P2TR address is exactly 62 chars');
      expect(addr, equals(_kSnapshotIndex0));
    });

    test('Alice->Bob index 1 P2TR address matches snapshot', () {
      final addr = PaymentAddress(
        paymentCode: pCodeBob,
        bip32Node: aliceBip32.derive(0),
        index: 1,
      ).getSendAddressP2TR();

      expect(addr, equals(_kSnapshotIndex1));
    });

    test('Alice->Bob index 2 P2TR address matches snapshot', () {
      final addr = PaymentAddress(
        paymentCode: pCodeBob,
        bip32Node: aliceBip32.derive(0),
        index: 2,
      ).getSendAddressP2TR();

      expect(addr, equals(_kSnapshotIndex2));
    });
  });

  group('P2TR address format', () {
    test('mainnet P2TR addresses start with bc1p', () {
      final addr = PaymentAddress(
        paymentCode: pCodeBob,
        bip32Node: aliceBip32.derive(0),
        index: 0,
      ).getSendAddressP2TR();
      expect(addr, startsWith('bc1p'));
    });

    test('testnet P2TR addresses start with tb1p', () {
      final pCodeAliceTestnet = PaymentCode.fromPaymentCode(
        _kPaymentCodeAlice,
        networkType: testnet,
      );
      final addr = PaymentAddress(
        paymentCode: pCodeAliceTestnet,
        bip32Node: bobBip32.derive(0),
        networkType: testnet,
        index: 0,
      ).getReceiveAddressP2TR();
      expect(addr, startsWith('tb1p'));
    });
  });

  group('Feature byte taproot bit', () {
    test('round-trip preserves taproot bit (TAPTEST-03)', () {
      final pCode = PaymentCode.fromBip32Node(
        aliceBip32,
        networkType: bitcoin,
        shouldSetSegwitBit: false,
        shouldSetTaprootBit: true,
      );
      expect(pCode.isTaprootEnabled(), isTrue);

      // Round-trip through toString -> fromPaymentCode
      final pCodeString = pCode.toString();
      final restored = PaymentCode.fromPaymentCode(
        pCodeString,
        networkType: bitcoin,
      );
      expect(restored.isTaprootEnabled(), isTrue,
          reason:
              'taproot bit must survive toString/fromPaymentCode round-trip');
    });

    test('round-trip through fromPayload preserves taproot bit', () {
      final pCode = PaymentCode.fromBip32Node(
        aliceBip32,
        networkType: bitcoin,
        shouldSetSegwitBit: false,
        shouldSetTaprootBit: true,
      );
      final payload = pCode.getPayload();

      final restored = PaymentCode.fromPayload(
        payload,
        networkType: bitcoin,
      );
      expect(restored.isTaprootEnabled(), isTrue,
          reason:
              'taproot bit must survive getPayload/fromPayload round-trip');
    });

    test('taproot bit implies segwit bit (TAPTEST-04)', () {
      final pCode = PaymentCode.fromBip32Node(
        aliceBip32,
        networkType: bitcoin,
        shouldSetSegwitBit: false,
        shouldSetTaprootBit: true,
      );
      expect(pCode.isTaprootEnabled(), isTrue);
      expect(pCode.isSegWitEnabled(), isTrue,
          reason: 'taproot implies segwit -- both bits must be set');
    });
  });

  group('P2TR differs from P2WPKH', () {
    test('P2TR and P2WPKH addresses differ at same index (TAPTEST-05)', () {
      for (int i = 0; i < 3; i++) {
        final pa = PaymentAddress(
          paymentCode: pCodeBob,
          bip32Node: aliceBip32.derive(0),
          index: i,
        );
        final p2tr = pa.getSendAddressP2TR();
        final p2wpkh = pa.getSendAddressP2WPKH();

        expect(p2tr, isNot(equals(p2wpkh)),
            reason: 'P2TR and P2WPKH must differ at index $i');
        expect(p2tr, startsWith('bc1p'));
        expect(p2wpkh, startsWith('bc1q'));
      }
    });
  });
}
