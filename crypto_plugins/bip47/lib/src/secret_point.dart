import 'dart:typed_data';

import 'package:bip47/src/util.dart';
import 'package:pointycastle/ecc/api.dart';

// wrapper for EC key pair/point data
class SecretPoint {
  late final ECPrivateKey privKey;
  late final ECPublicKey pubKey;

  final _parameters = ECDomainParameters("secp256k1");

  // constructor
  SecretPoint(Uint8List priv, Uint8List pub) {
    privKey = _loadPrivateKey(priv);
    pubKey = _loadPublicKey(pub);
  }

  /// grab the ECDH secret for this point
  Uint8List ecdhSecret() {
    final result =
        (ECDHBasicAgreement()..init(privKey)).calculateAgreement(pubKey);
    return result.to32Bytes();
  }

  /// generate an EC pub key from [data]
  ECPublicKey _loadPublicKey(Uint8List data) {
    final ecPoint = _parameters.curve.decodePoint(data);
    return ECPublicKey(ecPoint, _parameters);
  }

  /// generate an EC private key from [data]
  ECPrivateKey _loadPrivateKey(Uint8List data) {
    return ECPrivateKey(data.toBigInt, _parameters);
  }
}
