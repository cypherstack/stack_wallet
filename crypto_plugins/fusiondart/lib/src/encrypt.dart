import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:fusiondart/src/exceptions.dart';
import 'package:fusiondart/src/extensions/on_list_int.dart';
import 'package:fusiondart/src/extensions/on_uint8list.dart';
import 'package:fusiondart/src/util.dart';
import 'package:pointycastle/pointycastle.dart' hide Mac;

/// Encrypts a [message] using a provided EC [pubKey].
///
/// Optionally pads to a specified length [padToLength].
Future<Uint8List> encrypt(
  Uint8List message,
  Uint8List pubKey, {
  int? padToLength,
}) async {
  // Initialize public point from the public key
  final ECPoint pubPoint;
  try {
    pubPoint = Utilities.serToPoint(pubKey, Utilities.secp256k1Params);
  } catch (_) {
    throw EncryptionFailed(); // If serialization to point fails, throw encryption failed exception.
  }

  // Generate secure random nonce.
  final BigInt nonceSec = Utilities.secureRandomBigInt(
    Utilities.secp256k1Params.n,
  );

  // Calculate G * nonceSec
  final ECPoint? gTimesNonceSec = Utilities.secp256k1Params.G * nonceSec;
  if (gTimesNonceSec == null) {
    throw Exception('Multiplication of G with nonceSec resulted in null');
  }

  // Serialize G_times_nonceSec to bytes
  final Uint8List noncePub = Utilities.pointToSer(gTimesNonceSec, true);

  // Calculate public point * nonceSec
  ECPoint? pubPointTimesNonceSec = pubPoint * nonceSec;
  if (pubPointTimesNonceSec == null) {
    throw Exception(
        'Multiplication of pubPoint with nonceSec resulted in null');
  }

  // Create a SHA-256 hash as the symmetric key.
  final List<int> key =
      Utilities.sha256(Utilities.pointToSer(pubPointTimesNonceSec, true));

  // Prepare plaintext with message length prepended.
  Uint8List plaintext = Uint8List(4 + message.length)
    ..buffer.asByteData().setUint32(0, message.length, Endian.big)
    ..setRange(4, 4 + message.length, message);

  // Handle padding for AES encryption.
  if (padToLength == null) {
    padToLength = ((plaintext.length + 15) ~/ 16) *
        16; // Round up to nearest 16 bytes for AES block size.
  } else if (padToLength % 16 != 0) {
    throw ArgumentError('$padToLength not multiple of 16');
  }
  if (padToLength < plaintext.length) {
    throw ArgumentError('$padToLength < ${plaintext.length}');
  }

  // Actual padding.
  plaintext = Uint8List(padToLength)
    ..setRange(0, message.length + 4, plaintext);

  // Initialize secret key, MAC algorithm, and cipher.
  final secretKey = SecretKey(key);
  final cipher = AesCbc.with256bits(
    macAlgorithm: Hmac.sha256(),
    paddingAlgorithm: PaddingAlgorithm.zero,
  );

  // IV is set to zeros: https://github.com/Electron-Cash/Electron-Cash/blob/ba01323b732d1ae4ba2ca66c40e3f27bb92cee4b/electroncash_plugins/fusion/encrypt.py#L97
  final nonce = Uint8List(16);

  // Perform AES encryption.
  final secretBox = await cipher.encrypt(
    plaintext,
    secretKey: secretKey,
    nonce: nonce,
  );

  // Prepare final ciphertext.
  final ciphertext = secretBox.cipherText;

  // truncate mac (as done in the python code)
  final mac = secretBox.mac.bytes.sublist(0, 16);

  // Combine nonce, ciphertext, and MAC to create the final encrypted message.
  return Uint8List.fromList([
    ...noncePub,
    ...ciphertext,
    ...mac,
  ]);
}

/// Decrypts data using a symmetric key.
Future<Uint8List> decryptWithSymmkey(Uint8List data, Uint8List key) async {
  // Check if the incoming data has a minimum length to contain all the elements.
  if (data.length < 33 + 16 + 16) {
    throw DecryptionFailed();
  }

  // Extract the actual ciphertext from the data (skipping nonce and MAC).
  Uint8List ciphertext = data.sublist(33, data.length - 16);

  // Check if the ciphertext's length is a multiple of the AES block size.
  if (ciphertext.length % 16 != 0) {
    throw DecryptionFailed();
  }

  // Initialize the secret key and cipher.
  final secretKey = SecretKey(key);
  final cipher = AesCbc.with256bits(
    macAlgorithm: Hmac.sha256(),
    paddingAlgorithm: PaddingAlgorithm.zero,
  );

  // IV https://github.com/Electron-Cash/Electron-Cash/blob/ba01323b732d1ae4ba2ca66c40e3f27bb92cee4b/electroncash_plugins/fusion/encrypt.py#L119
  final nonce = Uint8List(16);

  final extractedMacBytes = data.sublist(data.length - 16);

  final calculatedHMAC = await Hmac(Sha256()).calculateMac(
    ciphertext,
    secretKey: secretKey,
    nonce: nonce,
  );

  if (!calculatedHMAC.bytes.sublist(0, 16).equals(extractedMacBytes)) {
    throw DecryptionFailed();
  }

  // Initialize the SecretBox with the ciphertext, MAC and nonce.
  final secretBox = SecretBox(
    ciphertext,
    mac: calculatedHMAC,
    nonce: nonce,
  );

  // Perform the decryption.
  final plaintext = await cipher.decrypt(secretBox, secretKey: secretKey);

  // Check if the decrypted plaintext has at least 4 bytes (for the length field).
  if (plaintext.length < 4) {
    throw DecryptionFailed();
  }

  // Convert plaintext to ByteData to read the length field.
  Uint8List uint8list = Uint8List.fromList(plaintext);
  ByteData byteData = ByteData.sublistView(uint8list);
  int msgLength = byteData.getUint32(0, Endian.big);

  // Check if the length field in the decrypted message matches the actual message length.
  if (msgLength + 4 > plaintext.length) {
    throw DecryptionFailed();
  }

  // Extract and return the actual message from the decrypted plaintext.
  return Uint8List.fromList(plaintext.sublist(4, 4 + msgLength));
}

/// Decrypts an encrypted message using a provided EC private key.
Future<({Uint8List decrypted, Uint8List symmetricKey})> decrypt(
  Uint8List data,
  Uint8List privateKey,
) async {
  // Ensure the encrypted data is of the minimum required length.
  if (data.length < 33 + 16 + 16) {
    throw DecryptionFailed();
  }
  // Extract the public part of the nonce from the incoming data.
  Uint8List noncePub = data.sublist(0, 33);
  ECPoint noncePoint;

  // Attempt to deserialize the nonce point.
  try {
    noncePoint = Utilities.serToPoint(noncePub, Utilities.secp256k1Params);
  } catch (_) {
    throw DecryptionFailed();
  }

  final ECPoint? point = noncePoint * privateKey.toBigInt;

  // Generate the symmetric key using the SHA-256 hash of the computed point.
  final key = Utilities.sha256(Utilities.pointToSer(point!, true));
  // Use the symmetric key to decrypt the data.
  final decryptedData = await decryptWithSymmkey(data, key);

  // Return the decrypted data and the symmetric key used for decryption.
  return (decrypted: decryptedData, symmetricKey: Uint8List.fromList(key));
}
