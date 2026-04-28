import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip47/bip47.dart';
import 'package:coin/coin.dart' as coin;
import 'package:test/test.dart';

// Samourai vectors.
const _kPath = "m/47'/0'/0'";
const _kSeedAlice =
    "response seminar brave tip suit recall often sound stick owner lottery mot"
    "ion";
const _kPaymentCodeAlice =
    "PM8TJTLJbPRGxSbc8EJi42Wrr6QbNSaSSVJ5Y3E4pbCYiTHUskHg13935Ubb7q8tx9GVbh2UuR"
    "nBc3WSyJHhUrw8KhprKnn9eDznYGieTzFcwQRya4GA";
const _kNotificationAddressAlice = '1JDdmqFLhpzcUwPeinhJbUPw4Co3aWLyzW';

void main() {
  setUpAll(() async {
    await coin.initCoin();
  });

  group('NetworkType constants', () {
    test('bitcoin constant has correct mainnet params', () {
      expect(bitcoin.pubKeyHash, 0x00);
      expect(bitcoin.scriptHash, 0x05);
      expect(bitcoin.wif, 0x80);
      expect(bitcoin.bech32, 'bc');
      expect(bitcoin.bip32.public, 0x0488b21e);
      expect(bitcoin.bip32.private, 0x0488ade4);
    });

    test('testnet constant has correct testnet params', () {
      expect(testnet.pubKeyHash, 0x6f);
      expect(testnet.scriptHash, 0xc4);
      expect(testnet.wif, 0xef);
      expect(testnet.bech32, 'tb');
      expect(testnet.bip32.public, 0x043587cf);
      expect(testnet.bip32.private, 0x04358394);
    });
  });

  group('custom NetworkType construction (paynym_interface pattern)', () {
    test('manually constructed NetworkType matches bitcoin constant', () {
      // This is exactly how paynym_interface.dart constructs NetworkType
      // from cryptoCurrency.networkParams.
      final custom = NetworkType(
        messagePrefix: '\x18Bitcoin Signed Message:\n',
        bech32: 'bc',
        bip32: Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
        pubKeyHash: 0x00,
        scriptHash: 0x05,
        wif: 0x80,
      );

      expect(custom.pubKeyHash, bitcoin.pubKeyHash);
      expect(custom.scriptHash, bitcoin.scriptHash);
      expect(custom.wif, bitcoin.wif);
      expect(custom.bech32, bitcoin.bech32);
      expect(custom.bip32.public, bitcoin.bip32.public);
      expect(custom.bip32.private, bitcoin.bip32.private);
    });

    test('custom NetworkType produces same notification address as constant', () {
      final custom = NetworkType(
        messagePrefix: '\x18Bitcoin Signed Message:\n',
        bech32: 'bc',
        bip32: Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
        pubKeyHash: 0x00,
        scriptHash: 0x05,
        wif: 0x80,
      );

      final pcConstant = PaymentCode.fromPaymentCode(
        _kPaymentCodeAlice,
        networkType: bitcoin,
      );
      final pcCustom = PaymentCode.fromPaymentCode(
        _kPaymentCodeAlice,
        networkType: custom,
      );

      expect(pcCustom.notificationAddressP2PKH(),
          pcConstant.notificationAddressP2PKH());
      expect(pcCustom.notificationAddressP2PKH(), _kNotificationAddressAlice);
    });

    test('custom NetworkType produces same send/receive addresses', () {
      final custom = NetworkType(
        messagePrefix: '\x18Bitcoin Signed Message:\n',
        bech32: 'bc',
        bip32: Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
        pubKeyHash: 0x00,
        scriptHash: 0x05,
        wif: 0x80,
      );

      final aliceBip32 = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(_kSeedAlice))
          .derivePath(_kPath);

      final pcBobConst = PaymentCode.fromPaymentCode(
        "PM8TJS2JxQ5ztXUpBBRnpTbcUXbUHy2T1abfrb3KkAAtMEGNbey4oumH7Hc578WgQJhPjBxteQ"
        "5GHHToTYHE3A1w6p7tU6KSoFmWBVbFGjKPisZDbP97",
        networkType: bitcoin,
      );
      final pcBobCustom = PaymentCode.fromPaymentCode(
        "PM8TJS2JxQ5ztXUpBBRnpTbcUXbUHy2T1abfrb3KkAAtMEGNbey4oumH7Hc578WgQJhPjBxteQ"
        "5GHHToTYHE3A1w6p7tU6KSoFmWBVbFGjKPisZDbP97",
        networkType: custom,
      );

      for (int i = 0; i < 5; i++) {
        final paConst = PaymentAddress(
          paymentCode: pcBobConst,
          bip32Node: aliceBip32.derive(0),
          networkType: bitcoin,
          index: i,
        );
        final paCustom = PaymentAddress(
          paymentCode: pcBobCustom,
          bip32Node: aliceBip32.derive(0),
          networkType: custom,
          index: i,
        );

        expect(paCustom.getSendAddressP2PKH(), paConst.getSendAddressP2PKH(),
            reason: 'P2PKH at index $i must match');
        expect(paCustom.getSendAddressP2WPKH(), paConst.getSendAddressP2WPKH(),
            reason: 'P2WPKH at index $i must match');
      }
    });
  });

  group('fromBip32Node with NetworkType', () {
    test('produces correct payment code with bitcoin constant', () {
      final aliceBip32 = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(_kSeedAlice))
          .derivePath(_kPath);

      final pc = PaymentCode.fromBip32Node(
        aliceBip32,
        networkType: bitcoin,
        shouldSetSegwitBit: false,
      );

      expect(pc.toString(), _kPaymentCodeAlice);
    });

    test('segwit bit produces different payment code string', () {
      final aliceBip32 = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(_kSeedAlice))
          .derivePath(_kPath);

      final pcNoSegwit = PaymentCode.fromBip32Node(
        aliceBip32,
        networkType: bitcoin,
        shouldSetSegwitBit: false,
      );

      final pcSegwit = PaymentCode.fromBip32Node(
        aliceBip32,
        networkType: bitcoin,
        shouldSetSegwitBit: true,
      );

      // Different encoding due to segwit bit
      expect(pcSegwit.toString(), isNot(equals(pcNoSegwit.toString())));
      // But same pubkey and chaincode
      expect(pcSegwit.getPubKey(), pcNoSegwit.getPubKey());
      expect(pcSegwit.getChain(), pcNoSegwit.getChain());
      // Segwit flag should be set
      expect(pcSegwit.isSegWitEnabled(), isTrue);
      expect(pcNoSegwit.isSegWitEnabled(), isFalse);
    });

    test('network type mismatch throws', () {
      final aliceBip32 = bip32.BIP32
          .fromSeed(
            bip39.mnemonicToSeed(_kSeedAlice),
            bip32.NetworkType(
              wif: 99,
              bip32: bip32.Bip32Type(public: 1, private: 0),
            ),
          )
          .derivePath(_kPath);

      expect(
        () => PaymentCode.fromBip32Node(
          aliceBip32,
          networkType: bitcoin,
          shouldSetSegwitBit: false,
        ),
        throwsException,
      );
    });
  });

  group('Litecoin-like NetworkType', () {
    test('P2WPKH uses ltc1q prefix with litecoin bech32 hrp', () {
      // Litecoin mainnet params
      final litecoin = NetworkType(
        messagePrefix: '\x19Litecoin Signed Message:\n',
        bech32: 'ltc',
        bip32: Bip32Type(public: 0x019da462, private: 0x019d9cfe),
        pubKeyHash: 0x30,
        scriptHash: 0x32,
        wif: 0xb0,
      );

      // Can't use Samourai vectors since those are for bitcoin bip32 params.
      // Just verify the address format uses the right prefix.
      final pcAlice = PaymentCode.fromPaymentCode(
        _kPaymentCodeAlice,
        networkType: bitcoin, // payment code itself is bitcoin-encoded
      );

      final aliceBip32 = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(_kSeedAlice))
          .derivePath(_kPath);

      final pa = PaymentAddress(
        paymentCode: pcAlice,
        bip32Node: aliceBip32.derive(0),
        networkType: litecoin,
        index: 0,
      );

      final p2wpkh = pa.getSendAddressP2WPKH();
      expect(p2wpkh.startsWith('ltc1q'), isTrue,
          reason: 'Litecoin P2WPKH should use ltc1q prefix, got: $p2wpkh');

      final p2pkh = pa.getSendAddressP2PKH();
      expect(p2pkh.startsWith('L') || p2pkh.startsWith('M'), isTrue,
          reason: 'Litecoin P2PKH should use L/M prefix, got: $p2pkh');
    });
  });
}
