import 'dart:typed_data';

import 'package:bip32/bip32.dart' hide NetworkType, Bip32Type;
import 'package:bip47/src/network_type.dart';
import 'package:bip47/src/payment_code.dart';
import 'package:bip47/src/secret_point.dart';
import 'package:bip47/src/util.dart';
import 'package:coin/coin.dart' as coin;
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/pointycastle.dart';

class PaymentAddress {
  final PaymentCode paymentCode;
  final BIP32? bip32Node;
  final NetworkType networkType;
  int index;

  static final curveParams = ECDomainParameters("secp256k1");

  PaymentAddress({
    required this.paymentCode,
    this.bip32Node,
    NetworkType? networkType,
    this.index = 0,
  }) : networkType = networkType ?? bitcoin;

  ECPoint sG() => (curveParams.G * getSecretPoint())!;

  SecretPoint getSharedSecret() => SecretPoint(
        bip32Node!.privateKey!,
        paymentCode.derivePublicKey(index),
      );

  BigInt getSecretPoint() {
    // convert hash to value 's'
    final BigInt s = hashSharedSecret().toBigInt;

    // check that 's' is a member of the associated scalar group
    if (!s.isScalarGroupMemberOf(curveParams)) {
      throw Exception("Secret point is not a member of the secp256k1 group");
    }

    return s;
  }

  ECPoint getECPoint() =>
      curveParams.curve.decodePoint(paymentCode.derivePublicKey(index))!;

  Uint8List hashSharedSecret() =>
      SHA256Digest().process(getSharedSecret().ecdhSecret());

  Uint8List _getSendAddressPublicKey() {
    final sum = getECPoint() + sG();
    return sum!.getEncoded(true);
  }

  String getSendAddressP2PKH() {
    final pubKeyBytes = _getSendAddressPublicKey();
    final pkHash = coin.hash160(pubKeyBytes);
    return coin.P2pkhAddr(pkHash).encode(_toCoinChain());
  }

  String getSendAddressP2WPKH() {
    final pubKeyBytes = _getSendAddressPublicKey();
    final pkHash = coin.hash160(pubKeyBytes);
    return coin.P2wpkhAddr(pkHash).encode(_toCoinChain());
  }

  String getSendAddressP2TR() {
    // Step 1: BIP-47 point addition -> compressed pubkey B'
    final bip47PubKey = _getSendAddressPublicKey();

    // Step 2: BIP-341 taproot key-path tweak (no script tree)
    final internalKey = coin.PublicKey(bip47PubKey);
    final outputKey = coin.Taproot(internalKey: internalKey).tweakedKey;

    // Step 3: bech32m address encoding
    return coin.TaprootAddr(outputKey).encode(_toCoinChain());
  }

  /// Returns the tweaked private key and derived public key for receiving.
  ///
  /// The returned record has [privateKey] (raw 32 bytes) and [publicKey]
  /// (compressed 33 bytes). This replaces the old bitcoindart ECPair.
  ({Uint8List privateKey, Uint8List publicKey}) getReceiveAddressKeyPair() {
    final tweakedPrivKey = _addSecp256k1(
      bip32Node!.privateKey!.toBigInt,
      getSecretPoint(),
    ).to32Bytes();

    final sk = coin.SecretKey(tweakedPrivKey);
    return (privateKey: tweakedPrivKey, publicKey: sk.publicKey.bytes);
  }

  String getReceiveAddressP2PKH() {
    final pair = getReceiveAddressKeyPair();
    final pkHash = coin.hash160(pair.publicKey);
    return coin.P2pkhAddr(pkHash).encode(_toCoinChain());
  }

  String getReceiveAddressP2WPKH() {
    final pair = getReceiveAddressKeyPair();
    final pkHash = coin.hash160(pair.publicKey);
    return coin.P2wpkhAddr(pkHash).encode(_toCoinChain());
  }

  String getReceiveAddressP2TR() {
    // Step 1: BIP-47 scalar addition -> keypair (b', B')
    final pair = getReceiveAddressKeyPair();

    // Step 2: BIP-341 taproot key-path tweak using B' as internal key
    final internalKey = coin.PublicKey(pair.publicKey);
    final outputKey = coin.Taproot(internalKey: internalKey).tweakedKey;

    // Step 3: bech32m address encoding
    return coin.TaprootAddr(outputKey).encode(_toCoinChain());
  }

  BigInt _addSecp256k1(BigInt b1, BigInt b2) {
    final BigInt value = b1 + b2;

    return value % curveParams.n;
  }

  coin.Chain _toCoinChain() {
    return coin.Chain(
      wifPrefix: networkType.wif,
      p2pkhPrefix: networkType.pubKeyHash,
      p2shPrefix: networkType.scriptHash,
      bech32Hrp: networkType.bech32,
      name: 'bip47',
      bip44CoinType: 0,
      privHDPrefix: networkType.bip32.private,
      pubHDPrefix: networkType.bip32.public,
    );
  }
}
