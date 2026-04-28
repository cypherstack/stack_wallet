/// Side-by-side equivalence tests: bip47 SecretPoint vs coin SecretPoint.
///
/// Proves that coin's ECDH implementation produces byte-identical shared
/// secrets to the bip47 package for BIP-47 spec test vectors.
///
/// TEST-01: SecretPoint ECDH equivalence at multiple indices.
///
/// D-07: Both libraries use secp256k1 ECDH. bip47 uses pointycastle's
/// ECDHBasicAgreement (pure Dart); coin uses libsecp256k1 FFI (or pure
/// Dart fallback). Output must be the same 32-byte x-coordinate.
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip47/bip47.dart' as bip47;
import 'package:coin/coin.dart' as coin;
import 'package:coin/src/ext/bip47/bip47.dart' as coin_bip47;
import 'package:flutter_test/flutter_test.dart';

import 'test_vectors.dart';

void main() {
  setUpAll(() async {
    await coin.VaultKeeper.initialize();
  });

  group('SecretPoint ECDH equivalence (TEST-01)', () {
    // Shared setup: derive Alice and Bob keys in both libraries.
    late Uint8List aliceSeed;
    late Uint8List bobSeed;

    // bip47 side
    late bip32.BIP32 bip47AliceRoot;
    late bip32.BIP32 bip47BobRoot;

    // coin side
    late coin.DerivedSecretKey coinAliceNode;
    late coin.DerivedSecretKey coinBobNode;

    setUp(() {
      aliceSeed = hexToBytes(aliceSeedHex);
      bobSeed = hexToBytes(bobSeedHex);

      // bip47 side: derive using bip32 package
      bip47AliceRoot = bip32.BIP32.fromSeed(aliceSeed);
      bip47BobRoot = bip32.BIP32.fromSeed(bobSeed);

      // coin side: derive using coin's DerivedKey
      coinAliceNode = coin.DerivedKey.fromSeed(aliceSeed).derivePath(
        "m/47'/0'/0'",
      ) as coin.DerivedSecretKey;
      coinBobNode = coin.DerivedKey.fromSeed(bobSeed).derivePath(
        "m/47'/0'/0'",
      ) as coin.DerivedSecretKey;
    });

    test(
      'ECDH shared secret is byte-identical between bip47 and coin '
      '(Alice a0 * Bob B0)',
      () {
        // bip47 side: Alice's private key at m/47'/0'/0'/0
        final bip47AliceChild0 =
            bip47AliceRoot.derivePath("m/47'/0'/0'").derive(0);
        final alicePrivBytes = bip47AliceChild0.privateKey!;

        // bip47 side: Bob's B0 public key from payment code
        final bip47BobPC = bip47.PaymentCode.fromPaymentCode(
          bobPaymentCodeBase58,
          networkType: bip47.bitcoin,
        );
        final bip47BobB0 = bip47BobPC.derivePublicKey(0);

        final bip47SP = bip47.SecretPoint(alicePrivBytes, bip47BobB0);
        final bip47Secret = bip47SP.ecdhSecret();

        // coin side: Alice's secret key at child 0
        final coinAliceChild0 =
            coinAliceNode.derive(0) as coin.DerivedSecretKey;

        // coin side: Bob's B0 from payment code
        final coinBobPC =
            coin_bip47.PaymentCode.fromBase58(bobPaymentCodeBase58);
        final coinBobB0 = coinBobPC.derivePublicKey(0);

        final coinSP =
            coin_bip47.SecretPoint(coinAliceChild0.secretKey, coinBobB0);
        final coinSecret = coinSP.ecdhSecret;

        // THE critical equivalence check
        expect(coinSecret, equals(bip47Secret));
        expect(coinSecret.length, equals(32));
      },
    );

    test(
      'ECDH is symmetric (Alice-side == Bob-side) for both libraries',
      () {
        // Alice side: a0 * B0
        final bip47AliceChild0 =
            bip47AliceRoot.derivePath("m/47'/0'/0'").derive(0);
        final bip47BobPC = bip47.PaymentCode.fromPaymentCode(
          bobPaymentCodeBase58,
          networkType: bip47.bitcoin,
        );
        final bip47AliceSide = bip47.SecretPoint(
          bip47AliceChild0.privateKey!,
          bip47BobPC.derivePublicKey(0),
        ).ecdhSecret();

        // Bob side: b0 * A0
        final bip47BobChild0 =
            bip47BobRoot.derivePath("m/47'/0'/0'").derive(0);
        final bip47AlicePC = bip47.PaymentCode.fromPaymentCode(
          alicePaymentCodeBase58,
          networkType: bip47.bitcoin,
        );
        final bip47BobSide = bip47.SecretPoint(
          bip47BobChild0.privateKey!,
          bip47AlicePC.derivePublicKey(0),
        ).ecdhSecret();

        // coin side: Alice a0 * Bob B0
        final coinAliceChild0 =
            coinAliceNode.derive(0) as coin.DerivedSecretKey;
        final coinBobPC =
            coin_bip47.PaymentCode.fromBase58(bobPaymentCodeBase58);
        final coinAliceSide = coin_bip47.SecretPoint(
          coinAliceChild0.secretKey,
          coinBobPC.derivePublicKey(0),
        ).ecdhSecret;

        // coin side: Bob b0 * Alice A0
        final coinBobChild0 = coinBobNode.derive(0) as coin.DerivedSecretKey;
        final coinAlicePC =
            coin_bip47.PaymentCode.fromBase58(alicePaymentCodeBase58);
        final coinBobSide = coin_bip47.SecretPoint(
          coinBobChild0.secretKey,
          coinAlicePC.derivePublicKey(0),
        ).ecdhSecret;

        // All 4 must match
        expect(bip47AliceSide, equals(bip47BobSide));
        expect(coinAliceSide, equals(coinBobSide));
        expect(coinAliceSide, equals(bip47AliceSide));
        expect(coinBobSide, equals(bip47BobSide));
      },
    );

    test(
      'ECDH shared secret at index 5 matches between bip47 and coin',
      () {
        // bip47 side: Alice a0 * Bob B5
        final bip47AliceChild0 =
            bip47AliceRoot.derivePath("m/47'/0'/0'").derive(0);
        final bip47BobPC = bip47.PaymentCode.fromPaymentCode(
          bobPaymentCodeBase58,
          networkType: bip47.bitcoin,
        );
        final bip47BobB5 = bip47BobPC.derivePublicKey(5);

        final bip47Secret =
            bip47.SecretPoint(bip47AliceChild0.privateKey!, bip47BobB5)
                .ecdhSecret();

        // coin side: Alice a0 * Bob B5
        final coinAliceChild0 =
            coinAliceNode.derive(0) as coin.DerivedSecretKey;
        final coinBobPC =
            coin_bip47.PaymentCode.fromBase58(bobPaymentCodeBase58);
        final coinBobB5 = coinBobPC.derivePublicKey(5);

        final coinSecret = coin_bip47.SecretPoint(
          coinAliceChild0.secretKey,
          coinBobB5,
        ).ecdhSecret;

        expect(coinSecret, equals(bip47Secret));
        expect(coinSecret.length, equals(32));
      },
    );
  });
}
