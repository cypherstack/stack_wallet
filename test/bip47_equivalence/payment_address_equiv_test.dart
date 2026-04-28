/// Side-by-side equivalence tests: bip47 PaymentAddress vs coin PaymentAddress.
///
/// Proves that coin's send/receive address derivation and receive secret key
/// produce byte-identical output to the bip47 package for all BIP-47 spec
/// test vector indices.
///
/// TEST-05: Send address derivation equivalence (P2PKH and P2WPKH).
/// TEST-06: Receive address derivation equivalence.
/// COIN-01: deriveReceiveSecretKey produces byte-identical private key to
///          bip47's getReceiveAddressKeyPair.
///
/// D-07: Both libraries compute the tweaked pubkey for send addresses as
/// B_n + SHA256(ECDH(a_0, B_n)) * G. For receive addresses, the tweaked
/// privkey is b_n + SHA256(ECDH(b_n, A_0)). coin's static methods take
/// pre-derived keys; bip47's PaymentAddress stores the bip32 node and
/// index internally.
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip47/bip47.dart' as bip47;
import 'package:coin/coin.dart' as coin;
import 'package:coin/src/ext/bip47/bip47.dart' as coin_bip47;
import 'package:flutter_test/flutter_test.dart';

import 'test_vectors.dart';

/// Bitcoin chain params for coin's address derivation.
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

  // Shared key material derived once per test.
  late bip32.BIP32 bip47AliceRoot;
  late bip32.BIP32 bip47BobRoot;
  late coin.DerivedSecretKey coinAliceNode;
  late coin.DerivedSecretKey coinBobNode;
  late bip47.PaymentCode bip47BobPC;
  late bip47.PaymentCode bip47AlicePC;
  late coin_bip47.PaymentCode coinBobPC;
  late coin_bip47.PaymentCode coinAlicePC;

  setUp(() {
    final aliceSeed = hexToBytes(aliceSeedHex);
    final bobSeed = hexToBytes(bobSeedHex);

    // bip47 side
    bip47AliceRoot =
        bip32.BIP32.fromSeed(aliceSeed).derivePath("m/47'/0'/0'");
    bip47BobRoot = bip32.BIP32.fromSeed(bobSeed).derivePath("m/47'/0'/0'");
    bip47BobPC = bip47.PaymentCode.fromPaymentCode(
      bobPaymentCodeBase58,
      networkType: bip47.bitcoin,
    );
    bip47AlicePC = bip47.PaymentCode.fromPaymentCode(
      alicePaymentCodeBase58,
      networkType: bip47.bitcoin,
    );

    // coin side
    coinAliceNode = coin.DerivedKey.fromSeed(aliceSeed).derivePath(
      "m/47'/0'/0'",
    ) as coin.DerivedSecretKey;
    coinBobNode = coin.DerivedKey.fromSeed(bobSeed).derivePath(
      "m/47'/0'/0'",
    ) as coin.DerivedSecretKey;
    coinBobPC = coin_bip47.PaymentCode.fromBase58(bobPaymentCodeBase58);
    coinAlicePC = coin_bip47.PaymentCode.fromBase58(alicePaymentCodeBase58);
  });

  group('Send address equivalence (TEST-05)', () {
    test(
      'P2PKH send addresses match for all 10 spec vector indices',
      () {
        // Alice sends to Bob: Alice's a_0 + Bob's payment code at index i
        final bip47AliceChild0 = bip47AliceRoot.derive(0);

        for (var i = 0; i < 10; i++) {
          // bip47 side
          final bip47PA = bip47.PaymentAddress(
            paymentCode: bip47BobPC,
            bip32Node: bip47AliceChild0,
            index: i,
          );
          final bip47Addr = bip47PA.getSendAddressP2PKH();

          // coin side: a_0 is the notification key (child 0)
          final coinAliceChild0 =
              coinAliceNode.derive(0) as coin.DerivedSecretKey;
          final coinAddr = coin_bip47.PaymentAddress.deriveSendAddress(
            myKey: coinAliceChild0.secretKey,
            theirPaymentCode: coinBobPC,
            index: i,
            chain: _bitcoin,
          );

          // THE critical equivalence check
          expect(
            coinAddr,
            equals(bip47Addr),
            reason: 'Send address mismatch at index $i',
          );

          // Also verify against known test vectors
          expect(
            coinAddr,
            equals(receivingAddresses[i]),
            reason: 'Send address does not match test vector at index $i',
          );
        }
      },
    );

    test(
      'P2WPKH send address matches between bip47 and coin at index 0',
      () {
        final bip47AliceChild0 = bip47AliceRoot.derive(0);
        final bip47PA = bip47.PaymentAddress(
          paymentCode: bip47BobPC,
          bip32Node: bip47AliceChild0,
          index: 0,
        );
        final bip47Addr = bip47PA.getSendAddressP2WPKH();

        final coinAliceChild0 =
            coinAliceNode.derive(0) as coin.DerivedSecretKey;
        final coinAddr = coin_bip47.PaymentAddress.deriveSendAddress(
          myKey: coinAliceChild0.secretKey,
          theirPaymentCode: coinBobPC,
          index: 0,
          chain: _bitcoin,
          segwit: true,
        );

        expect(coinAddr, equals(bip47Addr));
        // Segwit address starts with bc1q
        expect(coinAddr, startsWith('bc1q'));
      },
    );
  });

  group('Receive address equivalence (TEST-06)', () {
    test(
      'P2PKH receive addresses match for all 10 spec vector indices',
      () {
        for (var i = 0; i < 10; i++) {
          // bip47 side: Bob uses b_i as bip32Node, Alice's payment code,
          // index=0 (to derive Alice's A_0 for ECDH).
          // Note: bip47 PaymentAddress.getSharedSecret() uses
          // bip32Node.privateKey + paymentCode.derivePublicKey(index).
          // For receive: bip32Node = Bob's child i, index = 0 (Alice's A_0).
          final bip47BobChildI = bip47BobRoot.derive(i);
          final bip47PA = bip47.PaymentAddress(
            paymentCode: bip47AlicePC,
            bip32Node: bip47BobChildI,
            index: 0,
          );
          final bip47Addr = bip47PA.getReceiveAddressP2PKH();

          // coin side: Bob's b_i + Alice's payment code
          final coinBobChildI =
              coinBobNode.derive(i) as coin.DerivedSecretKey;
          final coinAddr = coin_bip47.PaymentAddress.deriveReceiveAddress(
            myKey: coinBobChildI.secretKey,
            theirPaymentCode: coinAlicePC,
            index: i,
            chain: _bitcoin,
          );

          // THE critical equivalence check
          expect(
            coinAddr,
            equals(bip47Addr),
            reason: 'Receive address mismatch at index $i',
          );

          // Also verify against known test vectors
          expect(
            coinAddr,
            equals(receivingAddresses[i]),
            reason: 'Receive address does not match test vector at index $i',
          );
        }
      },
    );

    test(
      'send and receive derive same address at each index in both libraries',
      () {
        final bip47AliceChild0 = bip47AliceRoot.derive(0);
        final coinAliceChild0 =
            coinAliceNode.derive(0) as coin.DerivedSecretKey;

        for (var i = 0; i < 5; i++) {
          // Send: Alice a_0 -> Bob at index i
          final bip47SendPA = bip47.PaymentAddress(
            paymentCode: bip47BobPC,
            bip32Node: bip47AliceChild0,
            index: i,
          );
          final bip47SendAddr = bip47SendPA.getSendAddressP2PKH();

          // Receive: Bob b_i <- Alice at index 0
          final bip47BobChildI = bip47BobRoot.derive(i);
          final bip47RecvPA = bip47.PaymentAddress(
            paymentCode: bip47AlicePC,
            bip32Node: bip47BobChildI,
            index: 0,
          );
          final bip47RecvAddr = bip47RecvPA.getReceiveAddressP2PKH();

          // coin side
          final coinSendAddr = coin_bip47.PaymentAddress.deriveSendAddress(
            myKey: coinAliceChild0.secretKey,
            theirPaymentCode: coinBobPC,
            index: i,
            chain: _bitcoin,
          );

          final coinBobChildI =
              coinBobNode.derive(i) as coin.DerivedSecretKey;
          final coinRecvAddr = coin_bip47.PaymentAddress.deriveReceiveAddress(
            myKey: coinBobChildI.secretKey,
            theirPaymentCode: coinAlicePC,
            index: i,
            chain: _bitcoin,
          );

          // All four must agree
          expect(bip47SendAddr, equals(bip47RecvAddr),
              reason: 'bip47 send/receive mismatch at index $i');
          expect(coinSendAddr, equals(coinRecvAddr),
              reason: 'coin send/receive mismatch at index $i');
          expect(coinSendAddr, equals(bip47SendAddr),
              reason: 'cross-library send mismatch at index $i');
        }
      },
    );
  });

  group('Receive secret key equivalence (COIN-01)', () {
    test(
      'receive secret key is byte-identical between bip47 and coin',
      () {
        for (var i = 0; i < 5; i++) {
          // bip47 side: getReceiveAddressKeyPair returns ECPair with
          // privateKey = (b_i + SHA256(ECDH(b_i, A_0))) mod n
          final bip47BobChildI = bip47BobRoot.derive(i);
          final bip47PA = bip47.PaymentAddress(
            paymentCode: bip47AlicePC,
            bip32Node: bip47BobChildI,
            index: 0,
          );
          final bip47PrivKey = bip47PA.getReceiveAddressKeyPair().privateKey!;

          // coin side: deriveReceiveSecretKey implements the same operation
          // (b_i + SHA256(ECDH(b_i, A_0))) mod n
          final coinBobChildI =
              coinBobNode.derive(i) as coin.DerivedSecretKey;
          final coinKey = coin_bip47.PaymentAddress.deriveReceiveSecretKey(
            myKey: coinBobChildI.secretKey,
            theirPaymentCode: coinAlicePC,
            index: i,
          );

          // THE critical equivalence check
          expect(
            coinKey.bytes,
            equals(bip47PrivKey),
            reason: 'Receive secret key mismatch at index $i',
          );
        }
      },
    );

    test(
      'receive secret key produces correct public key matching receive '
      'address',
      () {
        for (var i = 0; i < 3; i++) {
          // Get the receive secret key from coin
          final coinBobChildI =
              coinBobNode.derive(i) as coin.DerivedSecretKey;
          final coinKey = coin_bip47.PaymentAddress.deriveReceiveSecretKey(
            myKey: coinBobChildI.secretKey,
            theirPaymentCode: coinAlicePC,
            index: i,
          );

          // Derive the public key and encode as P2PKH
          final pubKey = coinKey.publicKey;
          final pkHash = coin.hash160(pubKey.bytes);
          final addr = coin.P2pkhAddr(pkHash).encode(_bitcoin);

          // Must match the receive address
          expect(
            addr,
            equals(receivingAddresses[i]),
            reason: 'Receive key -> address mismatch at index $i',
          );
        }
      },
    );
  });
}
