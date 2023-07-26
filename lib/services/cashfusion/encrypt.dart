import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/pointycastle.dart' hide Mac;
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'util.dart';

final ECDomainParameters params = ECDomainParameters('secp256k1');
final BigInt order = params.n;

class EncryptionFailed implements Exception {}
class DecryptionFailed implements Exception {}

Future<Uint8List> encrypt(Uint8List message, ECPoint pubkey, {int? padToLength}) async {
  ECPoint pubpoint;
  try {
    pubpoint = Util.ser_to_point(pubkey.getEncoded(true), params);
  } catch (_) {
    throw EncryptionFailed();
  }
  var nonceSec = Util.secureRandomBigInt(params.n.bitLength);
  var G_times_nonceSec = params.G * nonceSec;
  if (G_times_nonceSec == null) {
    throw Exception('Multiplication of G with nonceSec resulted in null');
  }
  var noncePub = Util.point_to_ser(G_times_nonceSec, true);

  var pubpoint_times_nonceSec = pubpoint * nonceSec;
  if (pubpoint_times_nonceSec == null) {
    throw Exception('Multiplication of pubpoint with nonceSec resulted in null');
  }
  var key = crypto.sha256.convert(Util.point_to_ser(pubpoint_times_nonceSec, true)).bytes;



  var plaintext = Uint8List(4 + message.length)..buffer.asByteData().setUint32(0, message.length, Endian.big)..setRange(4, 4 + message.length, message);
  if (padToLength == null) {
    padToLength = ((plaintext.length + 15) ~/ 16) * 16;  // round up to nearest 16
  } else if (padToLength % 16 != 0) {
    throw ArgumentError('$padToLength not multiple of 16');
  }
  if (padToLength < plaintext.length) {
    throw ArgumentError('$padToLength < ${plaintext.length}');
  }
  plaintext = Uint8List(padToLength)..setRange(0, message.length + 4, plaintext);

  final secretKey = SecretKey(key);

  final macAlgorithm = Hmac(Sha256());

  final cipher = AesCbc.with128bits(macAlgorithm: macAlgorithm);


  final nonce = Uint8List(16); // Random nonce
  final secretBox = await cipher.encrypt(plaintext, secretKey: secretKey, nonce: nonce);

  final ciphertext = secretBox.cipherText;

  return Uint8List(noncePub.length + ciphertext.length + secretBox.mac.bytes.length)
    ..setRange(0, noncePub.length, noncePub)
    ..setRange(noncePub.length, noncePub.length + ciphertext.length, ciphertext)
    ..setRange(noncePub.length + ciphertext.length, noncePub.length + ciphertext.length + secretBox.mac.bytes.length, secretBox.mac.bytes);
}

Future<Uint8List> decryptWithSymmkey(Uint8List data, Uint8List key) async {
  if (data.length < 33 + 16 + 16) {
    throw DecryptionFailed();
  }
  var ciphertext = data.sublist(33, data.length - 16);
  if (ciphertext.length % 16 != 0) {
    throw DecryptionFailed();
  }

  final secretKey = SecretKey(key);
  final cipher = AesCbc.with128bits(macAlgorithm: Hmac.sha256());
  final nonce = Uint8List(16); // Random nonce

  final secretBox = SecretBox(ciphertext, mac: Mac(data.sublist(data.length - 16)), nonce: nonce);
  final plaintext = await cipher.decrypt(secretBox, secretKey: secretKey);

  if (plaintext.length < 4) {
    throw DecryptionFailed();
  }

  Uint8List uint8list = Uint8List.fromList(plaintext);
  ByteData byteData = ByteData.sublistView(uint8list);
  var msgLength = byteData.getUint32(0, Endian.big);


  if (msgLength + 4 > plaintext.length) {
    throw DecryptionFailed();
  }
  return Uint8List.fromList(plaintext.sublist(4, 4 + msgLength));

}

Future<Tuple<Uint8List, Uint8List>> decrypt(Uint8List data, ECPrivateKey privkey) async {
  if (data.length < 33 + 16 + 16) {
    throw DecryptionFailed();
  }
  var noncePub = data.sublist(0, 33);
  ECPoint noncePoint;
  try {
    noncePoint = Util.ser_to_point(noncePub, params);
  } catch (_) {
    throw DecryptionFailed();
  }

  // DOUBLE CHECK THIS IS RIGHT IDEA MATCHING PYTHON.

  ECPoint G = params.G;
  var key;

  if (privkey.d != null && noncePoint != null) {
    var point = (G * privkey.d)! + noncePoint;
    key = crypto.sha256.convert(Util.point_to_ser(point!, true)).bytes;
    // ...
  } else {
    // Handle the situation where privkey.d or noncePoint is null
  }

  var decryptedData = await decryptWithSymmkey(data, Uint8List.fromList(key));
  return Tuple(decryptedData, Uint8List.fromList(key));
}

