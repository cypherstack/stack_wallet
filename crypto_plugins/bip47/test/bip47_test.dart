import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip47/bip47.dart';
import 'package:bip47/src/util.dart';
import 'package:coin/coin.dart' as coin;
import 'package:pointycastle/ecc/api.dart' as ecc;
import 'package:test/test.dart';

const String kPath = "m/47'/0'/0'";

// test data chosen from:
// https://gist.github.com/SamouraiDev/6aad669604c5930864bd
// https://github.com/SamouraiDev/OBPPrfc05/blob/main/TestVectorsV3.java
// https://github.com/rust-bitcoin/rust-bip47/blob/master/src/lib.rs#L718-L720
// https://github.com/sparrowwallet/drongo/blob/master/src/test/java/com/sparrowwallet/drongo/bip47/PaymentCodeTest.java#L33

const String kSeedAlice =
    "response seminar brave tip suit recall often sound stick owner lottery mot"
    "ion";
const String kPaymentCodeAlice =
    "PM8TJTLJbPRGxSbc8EJi42Wrr6QbNSaSSVJ5Y3E4pbCYiTHUskHg13935Ubb7q8tx9GVbh2UuR"
    "nBc3WSyJHhUrw8KhprKnn9eDznYGieTzFcwQRya4GA";
const kNotificationAddressAlice = "1JDdmqFLhpzcUwPeinhJbUPw4Co3aWLyzW";

const String kSeedBob =
    "reward upper indicate eight swift arch injury crystal super wrestle alread"
    "y dentist";
const String kPaymentCodeBob =
    "PM8TJS2JxQ5ztXUpBBRnpTbcUXbUHy2T1abfrb3KkAAtMEGNbey4oumH7Hc578WgQJhPjBxteQ"
    "5GHHToTYHE3A1w6p7tU6KSoFmWBVbFGjKPisZDbP97";
const kNotificationAddressBob = "1ChvUUvht2hUQufHBXF8NgLhW8SwE2ecGV";

const String kAliceDesignatedPrivateKey =
    "Kx983SRhAZpAhj7Aac1wUXMJ6XZeyJKqCxJJ49dxEbYCT4a1ozRD";

const String kAlicePayloadHexString =
    "010002b85034fb08a8bfefd22848238257b252721454bbbfba2c3667f168837ea2cdad671a"
    "f9f65904632e2dcc0c6ad314e11d53fc82fa4c4ea27a4a14eccecc478fee00000000000000"
    "000000000000";

const String kNotificationSharedSecret =
    "736a25d9250238ad64ed5da03450c6a3f4f8f4dcdf0b58d1ed69029d76ead48d";
const String kBlindingMask =
    "be6e7a4256cac6f4d4ed4639b8c39c4cb8bece40010908e70d17ea9d77b4dc57f1da36f2d6"
    "641ccb37cf2b9f3146686462e0fa3161ae74f88c0afd4e307adbd5";
const String kBlindedPaymentCodeAlice =
    "010002063e4eb95e62791b06c50e1a3a942e1ecaaa9afbbeb324d16ae6821e091611fa96c0"
    "cf048f607fe51a0327f5e2528979311c78cb2de0d682c61e1180fc3d543b00000000000000000000000000";

const String kOpReturnScript =
    "6a4c50010002063e4eb95e62791b06c50e1a3a942e1ecaaa9afbbeb324d16ae6821e091611"
    "fa96c0cf048f607fe51a0327f5e2528979311c78cb2de0d682c61e1180fc3d543b00000000"
    "000000000000000000";
const String kNotificationScript =
    "76a9148066a8e7ee82e5c5b9b7dc1765038340dc5420a988ac";

// Outpoint of first UTXO in Alice's notification transaction to Bob:
const String kIndexedNotificationOutpoint =
    "86f411ab1c8e70ae8a0795ab7a6757aea6e4d5ae1826fc7b8f00c597d500609c01000000";
const String kNotificationOutpoint =
    "86f411ab1c8e70ae8a0795ab7a6757aea6e4d5ae1826fc7b8f00c597d500609c";

// first 10 address used by Alice for sending to Bob:
const String address0 = "141fi7TY3h936vRUKh1qfUZr8rSBuYbVBK";
const String address1 = "12u3Uued2fuko2nY4SoSFGCoGLCBUGPkk6";
const String address2 = "1FsBVhT5dQutGwaPePTYMe5qvYqqjxyftc";
const String address3 = "1CZAmrbKL6fJ7wUxb99aETwXhcGeG3CpeA";
const String address4 = "1KQvRShk6NqPfpr4Ehd53XUhpemBXtJPTL";
const String address5 = "1KsLV2F47JAe6f8RtwzfqhjVa8mZEnTM7t";
const String address6 = "1DdK9TknVwvBrJe7urqFmaxEtGF2TMWxzD";
const String address7 = "16DpovNuhQJH7JUSZQFLBQgQYS4QB9Wy8e";
const String address8 = "17qK2RPGZMDcci2BLQ6Ry2PDGJErrNojT5";
const String address9 = "1GxfdfP286uE24qLZ9YRP3EWk2urqXgC4s";

// first 10 shared secrests
const String kSharedSecret0 =
    "f5bb84706ee366052471e6139e6a9a969d586e5fe6471a9b96c3d8caefe86fef";
const String kSharedSecret1 =
    "adfb9b18ee1c4460852806a8780802096d67a8c1766222598dc801076beb0b4d";
const String kSharedSecret2 =
    "79e860c3eb885723bb5a1d54e5cecb7df5dc33b1d56802906762622fa3c18ee5";
const String kSharedSecret3 =
    "d8339a01189872988ed4bd5954518485edebf52762bf698b75800ac38e32816d";
const String kSharedSecret4 =
    "14c687bc1a01eb31e867e529fee73dd7540c51b9ff98f763adf1fc2f43f98e83";
const String kSharedSecret5 =
    "725a8e3e4f74a50ee901af6444fb035cb8841e0f022da2201b65bc138c6066a2";
const String kSharedSecret6 =
    "521bf140ed6fb5f1493a5164aafbd36d8a9e67696e7feb306611634f53aa9d1f";
const String kSharedSecret7 =
    "5f5ecc738095a6fb1ea47acda4996f1206d3b30448f233ef6ed27baf77e81e46";
const String kSharedSecret8 =
    "1e794128ac4c9837d7c3696bbc169a8ace40567dc262974206fcf581d56defb4";
const String kSharedSecret9 =
    "fe36c27c62c99605d6cd7b63bf8d9fe85d753592b14744efca8be20a4d767c37";

// ECDH params
const String a0 =
    "8d6a8ecd8ee5e0042ad0cb56e3a971c760b5145c3917a8e7beaf0ed92d7a520c";
const String A0 =
    "0353883a146a23f988e0f381a9507cbdb3e3130cd81b3ce26daf2af088724ce683";
const String b0 =
    "04448fd1be0c9c13a5ca0b530e464b619dc091b299b98c5cab9978b32b4a1b8b";
const String B0 =
    "024ce8e3b04ea205ff49f529950616c3db615b1e37753858cc60c1ce64d17e2ad8";
const String b1 =
    "6bfa917e4c44349bfdf46346d389bf73a18cec6bc544ce9f337e14721f06107b";
const String B1 =
    "03e092e58581cf950ff9c8fc64395471733e13f97dedac0044ebd7d60ccc1eea4d";
const String b2 =
    "46d32fbee043d8ee176fe85a18da92557ee00b189b533fce2340e4745c4b7b8c";
const String B2 =
    "029b5f290ef2f98a0462ec691f5cc3ae939325f7577fcaf06cfc3b8fc249402156";
const String b3 =
    "4d3037cfd9479a082d3d56605c71cbf8f38dc088ba9f7a353951317c35e6c343";
const String B3 =
    "02094be7e0eef614056dd7c8958ffa7c6628c1dab6706f2f9f45b5cbd14811de44";
const String b4 =
    "97b94a9d173044b23b32f5ab64d905264622ecd3eafbe74ef986b45ff273bbba";
const String B4 =
    "031054b95b9bc5d2a62a79a58ecfe3af000595963ddc419c26dab75ee62e613842";
const String b5 =
    "ce67e97abf4772d88385e66d9bf530ee66e07172d40219c62ee721ff1a0dca01";
const String B5 =
    "03dac6d8f74cacc7630106a1cfd68026c095d3d572f3ea088d9a078958f8593572";
const String b6 =
    "ef049794ed2eef833d5466b3be6fe7676512aa302afcde0f88d6fcfe8c32cc09";
const String B6 =
    "02396351f38e5e46d9a270ad8ee221f250eb35a575e98805e94d11f45d763c4651";
const String b7 =
    "d3ea8f780bed7ef2cd0e38c5d943639663236247c0a77c2c16d374e5a202455b";
const String B7 =
    "039d46e873827767565141574aecde8fb3b0b4250db9668c73ac742f8b72bca0d0";
const String b8 =
    "efb86ca2a3bad69558c2f7c2a1e2d7008bf7511acad5c2cbf909b851eb77e8f3";
const String B8 =
    "038921acc0665fd4717eb87f81404b96f8cba66761c847ebea086703a6ae7b05bd";
const String b9 =
    "18bcf19b0b4148e59e2bba63414d7a8ead135a7c2f500ae7811125fb6f7ce941";
const String B9 =
    "03d51a06c6b48f067ff144d5acdfbe046efa2e83515012cf4990a89341c1440289";

/// Decode a WIF-encoded private key (compressed) to raw 32 bytes.
Uint8List _wifToPrivateKey(String wif) {
  final decoded = wif.fromBase58Check;
  // decoded: [version(1)] [privkey(32)] [compressed_flag(1)]
  return Uint8List.fromList(decoded.sublist(1, 33));
}

void main() {
  setUpAll(() async {
    await coin.initCoin();
  });

  group("payment codes v1", () {
    test('Payment code v1 fromPayload succeeds', () {
      final bytes = kAlicePayloadHexString.fromHex;

      final paymentCodeAliceV1 = PaymentCode.fromPayload(
        bytes,
        networkType: bitcoin,
      );

      expect(
        paymentCodeAliceV1.toString(),
        kPaymentCodeAlice,
      );
    });

    test('Payment code v1 fromPayload fails due to invalid payload length', () {
      final invalidLengthPayload = Uint8List.fromList([0, 1, 2, 3, 4]);

      Exception? exception;
      try {
        PaymentCode.fromPayload(
          invalidLengthPayload,
          networkType: bitcoin,
        );
      } catch (e) {
        exception = e as Exception;
      }

      expect(
        exception?.toString(),
        "Exception: Invalid payload size: 5",
      );
    });

    test('Payment code v1 fromPayload fails due to bad version', () {
      final bytes = Uint8List(PaymentCode.PAYLOAD_LEN);

      Exception? exception;
      try {
        PaymentCode.fromPayload(
          bytes,
          networkType: bitcoin,
        );
      } catch (e) {
        exception = e as Exception;
      }

      expect(
        exception?.toString(),
        "Exception: Unsupported payment code version: 0",
      );
    });

    test('Payment code v1 initFromBip32Node succeeds', () {
      final bip32NodeAlice = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(kSeedAlice))
          .derivePath(kPath);

      final paymentCodeAliceV1 = PaymentCode.fromBip32Node(
        bip32NodeAlice,
        networkType: bitcoin,
        shouldSetSegwitBit: false,
      );

      expect(
        paymentCodeAliceV1.toString(),
        kPaymentCodeAlice,
      );

      final bip32NodeBob = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(kSeedBob))
          .derivePath(kPath);

      final paymentCodeBobV1 = PaymentCode.fromBip32Node(
        bip32NodeBob,
        networkType: bitcoin,
        shouldSetSegwitBit: false,
      );

      expect(
        paymentCodeBobV1.toString(),
        kPaymentCodeBob,
      );
    });

    test('Payment code v1 initFromBip32Node fails due to network info mismatch',
        () {
      final bip32NodeAlice = bip32.BIP32
          .fromSeed(
            bip39.mnemonicToSeed(kSeedAlice),
            bip32.NetworkType(
              wif: 99,
              bip32: bip32.Bip32Type(
                public: 1,
                private: 0,
              ),
            ),
          )
          .derivePath(kPath);

      String? exceptionMessage;
      try {
        PaymentCode.fromBip32Node(
          bip32NodeAlice,
          networkType: bitcoin,
          shouldSetSegwitBit: false,
        );
      } catch (e) {
        exceptionMessage = e.toString();
      }

      expect(
        exceptionMessage,
        "Exception: BIP32 network info does not match provided networkType info",
      );
    });

    test('Payment code v1 getPayload', () {
      final bip32NodeAlice = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(kSeedAlice))
          .derivePath(kPath);

      final paymentCodeAliceV1 = PaymentCode.fromBip32Node(
        bip32NodeAlice,
        networkType: bitcoin,
        shouldSetSegwitBit: false,
      );

      expect(
        paymentCodeAliceV1.getPayload().toHex,
        kAlicePayloadHexString,
      );
    });

    test('Payment code v1 initFromPaymentCode', () {
      final bip32NodeAlice = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(kSeedAlice))
          .derivePath(kPath);

      final paymentCodeAliceV1 = PaymentCode.fromPaymentCode(
        kPaymentCodeAlice,
        networkType: bitcoin,
      );

      expect(paymentCodeAliceV1.getPubKey(), bip32NodeAlice.publicKey);
      expect(paymentCodeAliceV1.getChain(), bip32NodeAlice.chainCode);

      final bip32NodeBob = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(kSeedBob))
          .derivePath(kPath);

      final paymentCodeBobV1 = PaymentCode.fromPaymentCode(
        kPaymentCodeBob,
        networkType: bitcoin,
      );

      expect(paymentCodeBobV1.getPubKey(), bip32NodeBob.publicKey);
      expect(paymentCodeBobV1.getChain(), bip32NodeBob.chainCode);
    });

    test('Payment code v1 isValid', () {
      final paymentCodeAliceV1 = PaymentCode.fromPaymentCode(
        kPaymentCodeAlice,
        networkType: bitcoin,
      );

      final paymentCodeBobV1 = PaymentCode.fromPaymentCode(
        kPaymentCodeBob,
        networkType: bitcoin,
      );

      expect(paymentCodeBobV1.isValid(), true);
      expect(paymentCodeAliceV1.isValid(), true);
    });

    test('Payment code v1 notificationAddress', () {
      final paymentCodeAliceV1 = PaymentCode.fromPaymentCode(
        kPaymentCodeAlice,
        networkType: bitcoin,
      );

      expect(paymentCodeAliceV1.notificationAddressP2PKH(),
          kNotificationAddressAlice);

      final paymentCodeBobV1 = PaymentCode.fromPaymentCode(
        kPaymentCodeBob,
        networkType: bitcoin,
      );

      expect(
          paymentCodeBobV1.notificationAddressP2PKH(), kNotificationAddressBob);
    });

    test('notification tx blinding', () {
      final bip32NodeAlice = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(kSeedAlice))
          .derivePath(kPath);
      final paymentCodeAliceV1 = PaymentCode.fromBip32Node(
        bip32NodeAlice,
        networkType: bitcoin,
        shouldSetSegwitBit: false,
      );

      expect(paymentCodeAliceV1.getPayload().toHex, kAlicePayloadHexString);

      final paymentCodeBobV1 = PaymentCode.fromPaymentCode(
        kPaymentCodeBob,
        networkType: bitcoin,
      );

      final alicePrivateKey = _wifToPrivateKey(kAliceDesignatedPrivateKey);

      final txPointData = kNotificationOutpoint.fromHex.reversed.toList();
      final txPointDataIndex = 1;
      final _rev = txPointData.reversed.toList();
      final rev = Uint8List(_rev.length + 4);
      Util.copyBytes(Uint8List.fromList(_rev), 0, rev, 0, _rev.length);
      final buffer = rev.buffer.asByteData();
      buffer.setUint32(_rev.length, txPointDataIndex, Endian.little);
      expect(
        rev.toHex,
        kIndexedNotificationOutpoint,
      );

      final S = SecretPoint(
          alicePrivateKey, paymentCodeBobV1.notificationPublicKey());
      expect(
        S.ecdhSecret().toHex,
        kNotificationSharedSecret,
      );

      final blindingMask = PaymentCode.getMask(S.ecdhSecret(), rev);
      expect(
        blindingMask.toHex,
        kBlindingMask,
      );

      final blindedPaymentCode = PaymentCode.blind(
        payload: paymentCodeAliceV1.getPayload(),
        mask: blindingMask,
        unBlind: false,
      );
      expect(
        blindedPaymentCode.toHex,
        kBlindedPaymentCodeAlice,
      );

      // Verify notification address for Bob
      expect(
        paymentCodeBobV1.notificationAddressP2PKH(),
        kNotificationAddressBob,
      );
    });

    test('Payment code v1 alice send addresses', () {
      final bip32NodeAlice = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(kSeedAlice))
          .derivePath(kPath);

      final paymentCodeBobV1 = PaymentCode.fromPaymentCode(
        kPaymentCodeBob,
        networkType: bitcoin,
      );

      final a2b = PaymentAddress(
        paymentCode: paymentCodeBobV1,
        bip32Node: bip32NodeAlice.derive(0),
        index: 0,
      );
      expect(a2b.getSendAddressP2PKH(), address0);

      a2b.index++;
      expect(a2b.getSendAddressP2PKH(), address1);

      a2b.index++;
      expect(a2b.getSendAddressP2PKH(), address2);

      a2b.index++;
      expect(a2b.getSendAddressP2PKH(), address3);

      a2b.index++;
      expect(a2b.getSendAddressP2PKH(), address4);

      a2b.index++;
      expect(a2b.getSendAddressP2PKH(), address5);

      a2b.index++;
      expect(a2b.getSendAddressP2PKH(), address6);

      a2b.index++;
      expect(a2b.getSendAddressP2PKH(), address7);

      a2b.index++;
      expect(a2b.getSendAddressP2PKH(), address8);

      a2b.index++;
      expect(a2b.getSendAddressP2PKH(), address9);
    });

    test('Payment code v1 un blind', () {
      final unBlinded = PaymentCode.blind(
        payload: kBlindedPaymentCodeAlice.fromHex,
        mask: kBlindingMask.fromHex,
        unBlind: true,
      );

      final unBlindedCode = PaymentCode.fromPayload(
        unBlinded,
        networkType: bitcoin,
      );

      expect(unBlindedCode.toString(), kPaymentCodeAlice);
    });

    test('Payment code v1 bob receive addresses', () {
      final bobBip32 = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(kSeedBob))
          .derivePath(kPath);
      final pCodeA = PaymentCode.fromPaymentCode(
        kPaymentCodeAlice,
        networkType: bitcoin,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(0),
          index: 0,
        ).getReceiveAddressP2PKH(),
        address0,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(1),
          index: 0,
        ).getReceiveAddressP2PKH(),
        address1,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(2),
          index: 0,
        ).getReceiveAddressP2PKH(),
        address2,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(3),
          index: 0,
        ).getReceiveAddressP2PKH(),
        address3,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(4),
          index: 0,
        ).getReceiveAddressP2PKH(),
        address4,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(5),
          index: 0,
        ).getReceiveAddressP2PKH(),
        address5,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(6),
          index: 0,
        ).getReceiveAddressP2PKH(),
        address6,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(7),
          index: 0,
        ).getReceiveAddressP2PKH(),
        address7,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(8),
          index: 0,
        ).getReceiveAddressP2PKH(),
        address8,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(9),
          index: 0,
        ).getReceiveAddressP2PKH(),
        address9,
      );
    });

    test('Payment code v1 alice shared secrets', () {
      final bobBip32 = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(kSeedBob))
          .derivePath(kPath);
      final pCodeA = PaymentCode.fromPaymentCode(
        kPaymentCodeAlice,
        networkType: bitcoin,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(0),
          index: 0,
        ).getSharedSecret().ecdhSecret().toHex,
        kSharedSecret0,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(1),
          index: 0,
        ).getSharedSecret().ecdhSecret().toHex,
        kSharedSecret1,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(2),
          index: 0,
        ).getSharedSecret().ecdhSecret().toHex,
        kSharedSecret2,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(3),
          index: 0,
        ).getSharedSecret().ecdhSecret().toHex,
        kSharedSecret3,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(4),
          index: 0,
        ).getSharedSecret().ecdhSecret().toHex,
        kSharedSecret4,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(5),
          index: 0,
        ).getSharedSecret().ecdhSecret().toHex,
        kSharedSecret5,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(6),
          index: 0,
        ).getSharedSecret().ecdhSecret().toHex,
        kSharedSecret6,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(7),
          index: 0,
        ).getSharedSecret().ecdhSecret().toHex,
        kSharedSecret7,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(8),
          index: 0,
        ).getSharedSecret().ecdhSecret().toHex,
        kSharedSecret8,
      );

      expect(
        PaymentAddress(
          paymentCode: pCodeA,
          bip32Node: bobBip32.derive(9),
          index: 0,
        ).getSharedSecret().ecdhSecret().toHex,
        kSharedSecret9,
      );
    });

    test('Payment code v1 bob shared secrets', () {
      final bip32NodeAlice = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(kSeedAlice))
          .derivePath(kPath);

      final paymentCodeBobV1 = PaymentCode.fromPaymentCode(
        kPaymentCodeBob,
        networkType: bitcoin,
      );

      final a2b = PaymentAddress(
        paymentCode: paymentCodeBobV1,
        bip32Node: bip32NodeAlice.derive(0),
        index: 0,
      );
      expect(
        a2b.getSharedSecret().ecdhSecret().toHex,
        kSharedSecret0,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().ecdhSecret().toHex,
        kSharedSecret1,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().ecdhSecret().toHex,
        kSharedSecret2,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().ecdhSecret().toHex,
        kSharedSecret3,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().ecdhSecret().toHex,
        kSharedSecret4,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().ecdhSecret().toHex,
        kSharedSecret5,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().ecdhSecret().toHex,
        kSharedSecret6,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().ecdhSecret().toHex,
        kSharedSecret7,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().ecdhSecret().toHex,
        kSharedSecret8,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().ecdhSecret().toHex,
        kSharedSecret9,
      );
    });

    test('Payment code v1 alice ECDH params', () {
      final bip32NodeAlice = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(kSeedAlice))
          .derivePath(kPath);

      final paymentCodeBobV1 = PaymentCode.fromPaymentCode(
        kPaymentCodeBob,
        networkType: bitcoin,
      );

      final a2b = PaymentAddress(
        paymentCode: paymentCodeBobV1,
        bip32Node: bip32NodeAlice.derive(0),
        index: 0,
      );
      expect(
        a2b.getSharedSecret().privKey.d!.toHex,
        a0,
      );
      expect(
        a2b.getSharedSecret().pubKey.Q?.getEncoded().toHex,
        B0,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().privKey.d!.toHex,
        a0,
      );
      expect(
        a2b.getSharedSecret().pubKey.Q?.getEncoded().toHex,
        B1,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().privKey.d!.toHex,
        a0,
      );
      expect(
        a2b.getSharedSecret().pubKey.Q?.getEncoded().toHex,
        B2,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().privKey.d!.toHex,
        a0,
      );
      expect(
        a2b.getSharedSecret().pubKey.Q?.getEncoded().toHex,
        B3,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().privKey.d!.toHex,
        a0,
      );
      expect(
        a2b.getSharedSecret().pubKey.Q?.getEncoded().toHex,
        B4,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().privKey.d!.toHex,
        a0,
      );
      expect(
        a2b.getSharedSecret().pubKey.Q?.getEncoded().toHex,
        B5,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().privKey.d!.toHex,
        a0,
      );
      expect(
        a2b.getSharedSecret().pubKey.Q?.getEncoded().toHex,
        B6,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().privKey.d!.toHex,
        a0,
      );
      expect(
        a2b.getSharedSecret().pubKey.Q?.getEncoded().toHex,
        B7,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().privKey.d!.toHex,
        a0,
      );
      expect(
        a2b.getSharedSecret().pubKey.Q?.getEncoded().toHex,
        B8,
      );

      a2b.index++;
      expect(
        a2b.getSharedSecret().privKey.d!.toHex,
        a0,
      );
      expect(
        a2b.getSharedSecret().pubKey.Q?.getEncoded().toHex,
        B9,
      );
    });

    test('Payment code v1 bob ECDH params', () {
      final bobBip32 = bip32.BIP32
          .fromSeed(bip39.mnemonicToSeed(kSeedBob))
          .derivePath(kPath);
      final pCodeA = PaymentCode.fromPaymentCode(
        kPaymentCodeAlice,
        networkType: bitcoin,
      );

      final pa0 = PaymentAddress(
        paymentCode: pCodeA,
        bip32Node: bobBip32.derive(0),
        index: 0,
      );
      expect(
        pa0.getSharedSecret().privKey.d!.toHex,
        b0,
      );
      expect(
        pa0.getSharedSecret().pubKey.Q!.getEncoded().toHex,
        A0,
      );

      final pa1 = PaymentAddress(
        paymentCode: pCodeA,
        bip32Node: bobBip32.derive(1),
        index: 0,
      );
      expect(
        pa1.getSharedSecret().privKey.d!.toHex,
        b1,
      );
      expect(
        pa1.getSharedSecret().pubKey.Q!.getEncoded().toHex,
        A0,
      );

      final pa2 = PaymentAddress(
        paymentCode: pCodeA,
        bip32Node: bobBip32.derive(2),
        index: 0,
      );
      expect(
        pa2.getSharedSecret().privKey.d!.toHex,
        b2,
      );
      expect(
        pa2.getSharedSecret().pubKey.Q!.getEncoded().toHex,
        A0,
      );

      final pa3 = PaymentAddress(
        paymentCode: pCodeA,
        bip32Node: bobBip32.derive(3),
        index: 0,
      );
      expect(
        pa3.getSharedSecret().privKey.d!.toHex,
        b3,
      );
      expect(
        pa3.getSharedSecret().pubKey.Q!.getEncoded().toHex,
        A0,
      );

      final pa4 = PaymentAddress(
        paymentCode: pCodeA,
        bip32Node: bobBip32.derive(4),
        index: 0,
      );
      expect(
        pa4.getSharedSecret().privKey.d!.toHex,
        b4,
      );
      expect(
        pa4.getSharedSecret().pubKey.Q!.getEncoded().toHex,
        A0,
      );

      final pa5 = PaymentAddress(
        paymentCode: pCodeA,
        bip32Node: bobBip32.derive(5),
        index: 0,
      );
      expect(
        pa5.getSharedSecret().privKey.d!.toHex,
        b5,
      );
      expect(
        pa5.getSharedSecret().pubKey.Q!.getEncoded().toHex,
        A0,
      );

      final pa6 = PaymentAddress(
        paymentCode: pCodeA,
        bip32Node: bobBip32.derive(6),
        index: 0,
      );
      expect(
        pa6.getSharedSecret().privKey.d!.toHex,
        b6,
      );
      expect(
        pa6.getSharedSecret().pubKey.Q!.getEncoded().toHex,
        A0,
      );

      final pa7 = PaymentAddress(
        paymentCode: pCodeA,
        bip32Node: bobBip32.derive(7),
        index: 0,
      );
      expect(
        pa7.getSharedSecret().privKey.d!.toHex,
        b7,
      );
      expect(
        pa7.getSharedSecret().pubKey.Q!.getEncoded().toHex,
        A0,
      );

      final pa8 = PaymentAddress(
        paymentCode: pCodeA,
        bip32Node: bobBip32.derive(8),
        index: 0,
      );
      expect(
        pa8.getSharedSecret().privKey.d!.toHex,
        b8,
      );
      expect(
        pa8.getSharedSecret().pubKey.Q!.getEncoded().toHex,
        A0,
      );

      final pa9 = PaymentAddress(
        paymentCode: pCodeA,
        bip32Node: bobBip32.derive(9),
        index: 0,
      );
      expect(
        pa9.getSharedSecret().privKey.d!.toHex,
        b9,
      );
      expect(
        pa9.getSharedSecret().pubKey.Q!.getEncoded().toHex,
        A0,
      );
    });
  });

  group("isScalarGroupMember tests", () {
    final curveParams = ecc.ECDomainParameters("secp256k1");

    test(
      "just outside lower bounds",
      () => expect(
        BigInt.from(-1).isScalarGroupMemberOf(curveParams),
        false,
      ),
    );

    test(
      "at lower bound",
      () => expect(
        BigInt.zero.isScalarGroupMemberOf(curveParams),
        true,
      ),
    );

    test(
      "just inside lower bounds",
      () => expect(
        BigInt.one.isScalarGroupMemberOf(curveParams),
        true,
      ),
    );

    test(
      "at upper bound",
      () => expect(
        (curveParams.n - BigInt.one).isScalarGroupMemberOf(curveParams),
        true,
      ),
    );

    test(
      "check against n itself",
      () => expect(
        curveParams.n.isScalarGroupMemberOf(curveParams),
        false,
      ),
    );

    test(
      "just outside upper bounds",
      () => expect(
        (curveParams.n + BigInt.one).isScalarGroupMemberOf(curveParams),
        false,
      ),
    );
  });
}
