/// Side-by-side equivalence tests: bip47 PaymentCode vs coin PaymentCode.
///
/// Proves that coin's PaymentCode encoding, segwit handling, fromBip32Node
/// factory, child key derivation, and notification address all produce
/// identical output to the bip47 package.
///
/// TEST-02: PaymentCode base58 encoding equivalence.
/// TEST-07: Notification address equivalence.
/// TEST-08: Child public key derivation equivalence.
/// COIN-02: coin segwit bit moved to byte 79 (Samourai convention).
/// COIN-03: coin PaymentCode.fromBip32Node factory added.
///
/// D-07: coin's segwit bit was originally at byte 1 (BIP-47 spec literal
/// reading); fixed to byte 79 (Samourai convention) for wire compatibility
/// with existing PayNym users. bip47 package uses byte 79 via
/// SAMOURAI_FEATURE_BYTE constant.
///
/// D-07: coin's fromBip32Node delegates to fromPublicKey, extracting
/// pubkey/chainCode from DerivedSecretKey. bip47's fromBip32Node takes
/// a bip32.BIP32 node and internally extracts the same fields.
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip47/bip47.dart' as bip47;
import 'package:coin/coin.dart' as coin;
import 'package:coin/src/ext/bip47/bip47.dart' as coin_bip47;
import 'package:flutter_test/flutter_test.dart';

import 'test_vectors.dart';

/// Bitcoin chain params for coin's notificationAddress.
const _bitcoin = coin.Chain(
  wifPrefix: 0x80,
  p2pkhPrefix: 0x00,
  p2shPrefix: 0x05,
  bech32Hrp: 'bc',
  name: 'Bitcoin',
  bip44CoinType: 0,
  supportsSegwit: true,
  supportsTaproot: true,
);

void main() {
  setUpAll(() async {
    await coin.VaultKeeper.initialize();
  });

  // Shared setup
  late Uint8List aliceSeed;
  late Uint8List bobSeed;
  late bip32.BIP32 bip47AliceBip32Node;
  late bip32.BIP32 bip47BobBip32Node;
  late coin.DerivedSecretKey coinAliceNode;
  late coin.DerivedSecretKey coinBobNode;

  setUp(() {
    aliceSeed = hexToBytes(aliceSeedHex);
    bobSeed = hexToBytes(bobSeedHex);

    bip47AliceBip32Node =
        bip32.BIP32.fromSeed(aliceSeed).derivePath("m/47'/0'/0'");
    bip47BobBip32Node =
        bip32.BIP32.fromSeed(bobSeed).derivePath("m/47'/0'/0'");

    coinAliceNode = coin.DerivedKey.fromSeed(aliceSeed).derivePath(
      "m/47'/0'/0'",
    ) as coin.DerivedSecretKey;
    coinBobNode = coin.DerivedKey.fromSeed(bobSeed).derivePath(
      "m/47'/0'/0'",
    ) as coin.DerivedSecretKey;
  });

  group('PaymentCode encoding equivalence (TEST-02)', () {
    test('non-segwit payment code base58 matches between bip47 and coin', () {
      // bip47 side
      final bip47AlicePC = bip47.PaymentCode.fromPaymentCode(
        alicePaymentCodeBase58,
        networkType: bip47.bitcoin,
      );
      // coin side
      final coinAlicePC =
          coin_bip47.PaymentCode.fromBase58(alicePaymentCodeBase58);

      // Base58 encoding
      expect(coinAlicePC.toBase58(), equals(bip47AlicePC.toString()));

      // Payload bytes
      expect(coinAlicePC.payload, equals(bip47AlicePC.getPayload()));

      // Public key (notification pubkey)
      expect(
        coinAlicePC.notificationPublicKey,
        equals(bip47AlicePC.getPubKey()),
      );

      // Chain code
      expect(coinAlicePC.chainCode, equals(bip47AlicePC.getChain()));
    });

    test('non-segwit Bob payment code base58 matches', () {
      final bip47BobPC = bip47.PaymentCode.fromPaymentCode(
        bobPaymentCodeBase58,
        networkType: bip47.bitcoin,
      );
      final coinBobPC =
          coin_bip47.PaymentCode.fromBase58(bobPaymentCodeBase58);

      expect(coinBobPC.toBase58(), equals(bip47BobPC.toString()));
      expect(coinBobPC.payload, equals(bip47BobPC.getPayload()));
      expect(coinBobPC.notificationPublicKey, equals(bip47BobPC.getPubKey()));
      expect(coinBobPC.chainCode, equals(bip47BobPC.getChain()));
    });

    test('segwit payment code base58 matches between bip47 and coin', () {
      // bip47 side: construct segwit payment code from bip32 node
      final bip47SegwitPC = bip47.PaymentCode.fromBip32Node(
        bip47AliceBip32Node,
        networkType: bip47.bitcoin,
        shouldSetSegwitBit: true,
      );

      // coin side: construct segwit payment code from pubkey/chaincode
      final coinSegwitPC = coin_bip47.PaymentCode.fromPublicKey(
        pubKey: coinAliceNode.publicKey.bytes,
        chainCode: coinAliceNode.chainCode,
        segwit: true,
      );

      // COIN-02: After fix, both must produce identical base58
      expect(coinSegwitPC.toBase58(), equals(bip47SegwitPC.toString()));

      // Both must report segwit enabled
      expect(coinSegwitPC.isSegwit, isTrue);
      expect(bip47SegwitPC.isSegWitEnabled(), isTrue);
    });
  });

  group('PaymentCode.fromBip32Node equivalence (COIN-03)', () {
    test('fromBip32Node produces same payment code as bip47.fromBip32Node',
        () {
      // bip47 side
      final bip47PC = bip47.PaymentCode.fromBip32Node(
        bip47AliceBip32Node,
        networkType: bip47.bitcoin,
        shouldSetSegwitBit: false,
      );

      // coin side
      final coinPC = coin_bip47.PaymentCode.fromBip32Node(coinAliceNode);

      expect(coinPC.toBase58(), equals(bip47PC.toString()));
      expect(coinPC.toBase58(), equals(alicePaymentCodeBase58));
    });

    test('fromBip32Node with segwit produces same payment code', () {
      // bip47 side
      final bip47SegwitPC = bip47.PaymentCode.fromBip32Node(
        bip47AliceBip32Node,
        networkType: bip47.bitcoin,
        shouldSetSegwitBit: true,
      );

      // coin side
      final coinSegwitPC = coin_bip47.PaymentCode.fromBip32Node(
        coinAliceNode,
        segwit: true,
      );

      expect(coinSegwitPC.toBase58(), equals(bip47SegwitPC.toString()));
      expect(coinSegwitPC.isSegwit, isTrue);
    });

    test('fromBip32Node for Bob produces same payment code', () {
      // bip47 side
      final bip47BobPC = bip47.PaymentCode.fromBip32Node(
        bip47BobBip32Node,
        networkType: bip47.bitcoin,
        shouldSetSegwitBit: false,
      );

      // coin side
      final coinBobPC = coin_bip47.PaymentCode.fromBip32Node(coinBobNode);

      expect(coinBobPC.toBase58(), equals(bip47BobPC.toString()));
      expect(coinBobPC.toBase58(), equals(bobPaymentCodeBase58));
    });
  });

  group('Child public key derivation equivalence (TEST-08)', () {
    test('child pubkeys at indices 0-9 match between bip47 and coin', () {
      final bip47BobPC = bip47.PaymentCode.fromPaymentCode(
        bobPaymentCodeBase58,
        networkType: bip47.bitcoin,
      );
      final coinBobPC =
          coin_bip47.PaymentCode.fromBase58(bobPaymentCodeBase58);

      for (var i = 0; i < 10; i++) {
        final bip47Child = bip47BobPC.derivePublicKey(i);
        final coinChild = coinBobPC.derivePublicKey(i);
        expect(
          coinChild.bytes,
          equals(bip47Child),
          reason: 'Child public key mismatch at index $i',
        );
      }
    });

    test('Alice A0 matches test vector in both libraries', () {
      final bip47AlicePC = bip47.PaymentCode.fromPaymentCode(
        alicePaymentCodeBase58,
        networkType: bip47.bitcoin,
      );
      final coinAlicePC =
          coin_bip47.PaymentCode.fromBase58(alicePaymentCodeBase58);

      final bip47A0 = bip47AlicePC.derivePublicKey(0);
      final coinA0 = coinAlicePC.derivePublicKey(0);

      expect(bytesToHex(Uint8List.fromList(bip47A0)), equals(aliceA0PubHex));
      expect(bytesToHex(coinA0.bytes), equals(aliceA0PubHex));
      expect(coinA0.bytes, equals(bip47A0));
    });

    test('Bob B0 matches test vector in both libraries', () {
      final bip47BobPC = bip47.PaymentCode.fromPaymentCode(
        bobPaymentCodeBase58,
        networkType: bip47.bitcoin,
      );
      final coinBobPC =
          coin_bip47.PaymentCode.fromBase58(bobPaymentCodeBase58);

      final bip47B0 = bip47BobPC.derivePublicKey(0);
      final coinB0 = coinBobPC.derivePublicKey(0);

      expect(bytesToHex(Uint8List.fromList(bip47B0)), equals(bobB0PubHex));
      expect(bytesToHex(coinB0.bytes), equals(bobB0PubHex));
      expect(coinB0.bytes, equals(bip47B0));
    });
  });

  group('Notification address equivalence (TEST-07)', () {
    test('Alice notification address matches between bip47 and coin', () {
      final bip47AlicePC = bip47.PaymentCode.fromPaymentCode(
        alicePaymentCodeBase58,
        networkType: bip47.bitcoin,
      );
      final coinAlicePC =
          coin_bip47.PaymentCode.fromBase58(alicePaymentCodeBase58);

      final bip47Addr = bip47AlicePC.notificationAddressP2PKH();
      final coinAddr = coinAlicePC.notificationAddress(_bitcoin);

      expect(coinAddr, equals(bip47Addr));
      expect(coinAddr, equals(aliceNotificationAddress));
      expect(bip47Addr, equals(aliceNotificationAddress));
    });
  });
}
