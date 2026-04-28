/// Side-by-side equivalence tests: bip47 blinding mask and payload blinding
/// vs coin blinding mask and payload blinding.
///
/// Proves that coin's blindingMask (HMAC-SHA512) and blindPayload (XOR)
/// produce byte-identical output to the bip47 package's getMask and blind.
///
/// TEST-03: Blinding mask HMAC-SHA512 equivalence.
/// TEST-04: Payload blinding/unblinding equivalence.
///
/// D-07: bip47's getMask(sPoint, oPoint) uses key=oPoint, data=sPoint
/// internally (HMac.init(KeyParameter(oPoint)).process(sPoint)). coin's
/// blindingMask(ecdhSecret, outpoint) must call hmacSha512(outpoint,
/// ecdhSecret) to match -- key=outpoint, data=ecdhSecret. The public
/// API signature keeps (ecdhSecret, outpoint) for readability, but the
/// internal HMAC arguments are swapped for wire compatibility with
/// existing PayNym notification transactions.
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

  // Shared setup for deriving ECDH secret and outpoint.
  late Uint8List ecdhSecret;
  late Uint8List outpoint;
  late bip47.PaymentCode bip47AlicePC;
  late coin_bip47.PaymentCode coinAlicePC;

  setUp(() {
    final aliceSeed = hexToBytes(aliceSeedHex);

    // bip47 side: derive Alice a0 and Bob B0 for ECDH
    final bip47AliceChild0 =
        bip32.BIP32.fromSeed(aliceSeed).derivePath("m/47'/0'/0'").derive(0);
    final bip47BobPC = bip47.PaymentCode.fromPaymentCode(
      bobPaymentCodeBase58,
      networkType: bip47.bitcoin,
    );
    final bip47BobB0 = bip47BobPC.derivePublicKey(0);
    final bip47SP =
        bip47.SecretPoint(bip47AliceChild0.privateKey!, bip47BobB0);
    ecdhSecret = bip47SP.ecdhSecret();

    // Parse outpoint from test vectors
    outpoint = hexToBytes(outpointHex);

    // Payment codes for payload tests
    bip47AlicePC = bip47.PaymentCode.fromPaymentCode(
      alicePaymentCodeBase58,
      networkType: bip47.bitcoin,
    );
    coinAlicePC = coin_bip47.PaymentCode.fromBase58(alicePaymentCodeBase58);
  });

  group('Blinding mask equivalence (TEST-03)', () {
    test(
      'HMAC-SHA512 blinding mask is byte-identical between bip47 and coin',
      () {
        // bip47 side: getMask(sPoint=ecdhSecret, oPoint=outpoint)
        // Internally: key=outpoint, data=ecdhSecret
        final bip47Mask =
            bip47.PaymentCode.getMask(ecdhSecret, outpoint);

        // coin side: blindingMask(ecdhSecret, outpoint)
        // After fix: internally calls hmacSha512(outpoint, ecdhSecret)
        final coinMask =
            coin_bip47.blindingMask(ecdhSecret, outpoint);

        // THE critical equivalence check
        expect(coinMask, equals(bip47Mask));
        expect(coinMask.length, equals(64));
      },
    );

    test(
      'blinding mask with different outpoint produces different result '
      'in both libraries',
      () {
        // Original masks
        final bip47MaskOrig =
            bip47.PaymentCode.getMask(ecdhSecret, outpoint);
        final coinMaskOrig =
            coin_bip47.blindingMask(ecdhSecret, outpoint);

        // Modified outpoint (flip last byte)
        final altOutpoint = Uint8List.fromList(outpoint);
        altOutpoint[altOutpoint.length - 1] ^= 0xff;

        final bip47MaskAlt =
            bip47.PaymentCode.getMask(ecdhSecret, altOutpoint);
        final coinMaskAlt =
            coin_bip47.blindingMask(ecdhSecret, altOutpoint);

        // Both libraries produce same alt mask
        expect(coinMaskAlt, equals(bip47MaskAlt));

        // Alt mask differs from original
        expect(coinMaskAlt, isNot(equals(coinMaskOrig)));
        expect(bip47MaskAlt, isNot(equals(bip47MaskOrig)));
      },
    );
  });

  group('Payload blinding equivalence (TEST-04)', () {
    test(
      'blinded payload is byte-identical between bip47 and coin',
      () {
        // Get Alice's payload from both libraries
        final bip47Payload = bip47AlicePC.getPayload();
        final coinPayload = coinAlicePC.payload;

        // Payloads must be identical first (proven in TEST-02)
        expect(coinPayload, equals(bip47Payload));

        // Compute mask (identical after TEST-03)
        final mask = bip47.PaymentCode.getMask(ecdhSecret, outpoint);

        // bip47 side: blind (unBlind: false)
        final bip47Blinded = bip47.PaymentCode.blind(
          payload: bip47Payload,
          mask: mask,
          unBlind: false,
        );

        // coin side: blindPayload (XOR is the same for blind/unblind)
        final coinBlinded = coin_bip47.blindPayload(
          payload: coinPayload,
          mask: mask,
        );

        // THE critical equivalence check
        expect(coinBlinded, equals(bip47Blinded));
      },
    );

    test(
      'unblinded payload round-trip matches between bip47 and coin',
      () {
        final payload = bip47AlicePC.getPayload();
        final mask = bip47.PaymentCode.getMask(ecdhSecret, outpoint);

        // Blind with bip47, unblind with coin
        final bip47Blinded = bip47.PaymentCode.blind(
          payload: payload,
          mask: mask,
          unBlind: false,
        );
        final coinUnblinded = coin_bip47.blindPayload(
          payload: bip47Blinded,
          mask: mask,
        );
        expect(coinUnblinded, equals(payload));

        // Blind with coin, unblind with bip47
        final coinBlinded = coin_bip47.blindPayload(
          payload: payload,
          mask: mask,
        );
        final bip47Unblinded = bip47.PaymentCode.blind(
          payload: coinBlinded,
          mask: mask,
          unBlind: true,
        );
        expect(bip47Unblinded, equals(payload));
      },
    );

    test(
      'blinding preserves version, features, and pubkey prefix byte',
      () {
        final payload = bip47AlicePC.getPayload();
        final mask = bip47.PaymentCode.getMask(ecdhSecret, outpoint);

        // Blind with coin
        final blinded = coin_bip47.blindPayload(
          payload: payload,
          mask: mask,
        );

        // Bytes 0 (version), 1 (features), 2 (pubkey prefix) are unchanged
        // because XOR starts at byte 3.
        expect(blinded[0], equals(payload[0])); // version
        expect(blinded[1], equals(payload[1])); // features
        expect(blinded[2], equals(payload[2])); // pubkey prefix (0x02 or 0x03)

        // Bytes 3+ should be different (XOR'd with non-zero mask)
        var anyDifference = false;
        for (var i = 3; i < 67; i++) {
          if (blinded[i] != payload[i]) {
            anyDifference = true;
            break;
          }
        }
        expect(anyDifference, isTrue);
      },
    );
  });
}
