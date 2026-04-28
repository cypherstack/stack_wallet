import 'dart:typed_data';

import 'package:fusiondart/src/extensions/on_big_int.dart';
import 'package:fusiondart/src/extensions/on_uint8list.dart';
import 'package:fusiondart/src/util.dart';
import 'package:pointycastle/ecc/ecc_fp.dart' as fp;

/// Schnorr blind signature creator for the requester side.
///
/// See https://blog.cryptographyengineering.com/a-note-on-blind-signature-schemes/
class BlindSignatureRequest {
  // Curve properties.
  final BigInt _order; // ECDSA curve order.

  // Other fields needed for blind signature generation.
  final Uint8List pubkey;
  final Uint8List R;
  final Uint8List messageHash;

  // Private variables used in calculations.
  late BigInt _a;
  late BigInt _b;
  late BigInt _c;
  late BigInt _e;

  // late BigInt _eNew; // Written to but never read

  // Storage for intermediary and final results.
  late Uint8List _pointRxNew;
  late Uint8List _pubKeyCompressed;

  BlindSignatureRequest({
    required this.pubkey,
    required this.R,
    required this.messageHash,
  }) : _order = Utilities.secp256k1Params.n {
    // Check argument validity
    if (pubkey.length != 33 || R.length != 33 || messageHash.length != 32) {
      throw ArgumentError('Invalid argument lengths.');
    }

    // Generate random `BigInt`s `a` and `b`.
    _a = Utilities.secureRandomBigInt(_order);
    _b = Utilities.secureRandomBigInt(_order);

    // Perform initial calculations.
    _calcInitial();

    // Calculate `e` and `eNew`.
    final bytes =
        Utilities.sha256(_pointRxNew + _pubKeyCompressed + messageHash);
    final eHash = bytes.toBigInt;
    _e = (_c * eHash + _b) % _order;
    // _eNew = eHash % _order;
  }

  /// Returns the request as a Uint8List.
  Uint8List get request {
    // Return the request as a Uint8List
    return _e.toBytesPadded(32);
  }

  /// Finalizes the blind signature request.
  ///
  /// Expects 32 bytes s value, returns 64 byte finished signature.
  /// If check=True (default) this will perform a verification of the result.
  /// Upon failure it raises RuntimeError. The cause for this error is that
  /// the blind signer has provided an incorrect blinded s value.
  Uint8List finalize(Uint8List sBytes, {bool check = true}) {
    // Check argument validity.
    if (sBytes.length != 32) {
      throw ArgumentError('Invalid length for sBytes');
    }

    // Calculate sNew.
    final s = sBytes.toBigInt;
    final sNew = (_c * (s + _a)) % _order;

    // Calculate the final signature.
    final sig = _pointRxNew + sNew.toBytesPadded(32);

    // pad with zeros
    while (sig.length < 64) {
      sig.insert(0, 0);
    }

    // Check that pubPoint is not null.
    if (check && !Utilities.schnorrVerify(pubkey, sig, messageHash)) {
      throw Exception('Blind signature verification failed.');
    }

    return Uint8List.fromList(sig.toList());
  }

  // ================== Private functions ======================================

  /// Performs initial calculations needed for blind signature generation.
  void _calcInitial() {
    // Convert byte representations to ECPoints.
    final pointR = Utilities.serToPoint(R, Utilities.secp256k1Params);
    final pubPoint = Utilities.serToPoint(pubkey, Utilities.secp256k1Params);

    // Compress public key.
    _pubKeyCompressed = Utilities.pointToSer(pubPoint, true);

    // Calculate intermediateR.
    final intermediateR = pointR + (Utilities.secp256k1Params.G * _a);

    // Check that intermediateR is not null.
    if (intermediateR == null) {
      throw ArgumentError(
          'Failed to perform elliptic curve operation pointR + (params.G * a).');
    }

    // Calculate pointRNew.
    final pointRNew = intermediateR + (pubPoint * _b);

    // Check that pointRNew is not null.
    if (pointRNew == null || pointRNew.x?.toBigInteger() == null) {
      throw ArgumentError(
          'Failed to perform elliptic curve operation intermediateR + (pubPoint * b).');
    }

    // Convert pointRNew.x to bytes
    _pointRxNew = pointRNew.x!.toBigInteger()!.toBytesPadded(32);

    // Calculate y for the Jacobi symbol c.
    final y = pointRNew.y?.toBigInteger();

    // Check that y is not null.
    if (y == null) {
      throw ArgumentError('Y-coordinate of the new R point is null.');
    }

    // Calculate Jacobi symbol c.
    _c = Utilities.jacobi(
      y,
      (Utilities.secp256k1Params.curve as fp.ECCurve).q!,
    );
  }
}
