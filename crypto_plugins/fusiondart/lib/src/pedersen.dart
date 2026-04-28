import 'dart:typed_data';

import 'package:fusiondart/src/exceptions.dart';
import 'package:fusiondart/src/util.dart';
import 'package:pointycastle/ecc/api.dart';

/// Class responsible for setting up a Pedersen commitment.
class PedersenSetup {
  late final ECPoint _pointH;
  late final ECPoint _pointHG;

  /// Constructor initializes the Pedersen setup with a given H point.
  PedersenSetup(Uint8List _hBytes) {
    // Deserialize hBytes to get point H.
    try {
      _pointH = Utilities.serToPoint(_hBytes, Utilities.secp256k1Params);
    } catch (_) {
      throw ArgumentError("H could not be parsed");
    }

    // Calculate H + G to get HG.
    try {
      _pointHG = (_pointH + Utilities.secp256k1Params.G)!;
    } catch (_) {
      throw Exception('Failed to compute HG');
    }

    if (_pointHG.isInfinity) {
      throw InsecureHPoint();
    }
  }

  // Getter methods to fetch _H and _HG points.
  Uint8List get pointH => Utilities.pointToSer(_pointH, false);
  Uint8List get pointHG => Utilities.pointToSer(_pointHG, false);

  /// Create a new commitment.
  Commitment commit(
    BigInt amount, {
    BigInt? nonce,
    Uint8List? pointPUncompressed,
  }) {
    return Commitment(
      this,
      amount,
      nonce: nonce,
      pointPUncompressed: pointPUncompressed,
    );
  }
}

/// Class to encapsulate the Pedersen commitment.
class Commitment {
  // Private instance variables
  final PedersenSetup setup; // Added setup property to Commitment class

  late final BigInt nonce;

  late final BigInt amountMod;

  Uint8List get pointPUncompressed => _pointPUncompressed;
  Uint8List get pointPCompressed => _pointPCompressed;

  late final Uint8List _pointPUncompressed;
  late final Uint8List _pointPCompressed;

  Commitment(
    this.setup,
    BigInt amount, {
    BigInt? nonce,
    Uint8List? pointPUncompressed,
  }) {
    // https://github.com/Electron-Cash/Electron-Cash/blob/master/electroncash_plugins/fusion/pedersen.py#L160
    // Initialize nonce with a secure random value if not provided.
    this.nonce = nonce ??
        Utilities.secureRandomBigInt(
          Utilities.secp256k1Params.n,
        );

    // Validate that nonce is within the allowed range (0, n).
    if (this.nonce <= BigInt.zero ||
        this.nonce >= Utilities.secp256k1Params.n) {
      throw NonceRangeError();
    }

    // Take the modulus of the amount to ensure it fits within the group order.
    amountMod =
        amount % Utilities.secp256k1Params.n; // setup.params.n is order.

    // Retrieve curve points H and HG.
    final pointH = setup._pointH;
    final pointHG = setup._pointHG;

    // Compute multipliers for points H and HG.
    BigInt a = amountMod;
    BigInt k = this.nonce;

    // Multiply curve points by multipliers.
    ECPoint? pointHMultiplied =
        pointH * ((a - k) % Utilities.secp256k1Params.n);
    ECPoint? pointHGMultiplied = pointHG * k;

    // Add the multiplied points to get the commitment point P.
    ECPoint? pointP = pointHMultiplied != null && pointHGMultiplied != null
        ? pointHMultiplied + pointHGMultiplied
        : null;

    // Check if point P ends up at infinity, which shouldn't happen.
    if (pointP == Utilities.secp256k1Params.curve.infinity) {
      throw ResultAtInfinity();
    }

    if (pointPUncompressed == null) {
      // Do initial calculation of point P and nonce.
      _calcInitial(setup, amount);
    } else {
      _pointPUncompressed = pointPUncompressed;
      _pointPCompressed = Utilities.pointToSer(
        Utilities.serToPoint(
          _pointPUncompressed,
          Utilities.secp256k1Params,
        ),
        true,
      );
    }
  }

  /// Calculate the initial point and nonce for a given setup and amount.
  void _calcInitial(PedersenSetup setup, BigInt amount) {
    // Retrieve the curve points H and HG from the Pedersen setup.
    final ECPoint pointH = setup._pointH;
    final ECPoint pointHG = setup._pointHG;

    // Legwork towards calculating the point P.
    BigInt k = nonce;
    BigInt a = amountMod;
    ECPoint? pointHMultiplied = pointH *
        ((a - k) % Utilities.secp256k1Params.n); // setup.params.n is order.
    ECPoint? pointHGMultiplied = pointHG * k;

    if (pointHMultiplied == null || pointHGMultiplied == null) {
      throw NullPointError();
    }

    // Sum the two multiplied points to get the final point P.
    ECPoint pointP = ((pointHMultiplied) + (pointHGMultiplied))!;

    // Check if the resulting point P is at infinity, which should not occur.
    if (pointP == Utilities.secp256k1Params.curve.infinity) {
      throw ResultAtInfinity();
    }

    // Store both forms of the point P
    _pointPUncompressed = pointP.getEncoded(false);
    _pointPCompressed = pointP.getEncoded(true);
  }

  /// Add multiple Commitments together.
  static Commitment addCommitments(Iterable<Commitment> commitmentIterable) {
    BigInt ktotal = BigInt.zero; // Changed to `BigInt` from `int`.
    BigInt atotal = BigInt.zero; // Changed to `BigInt` from `int`.
    List<Uint8List> points = [];
    List<PedersenSetup> setups = []; // Changed Setup to PedersenSetup.

    // Loop through each commitment to sum up nonces and amounts.
    for (Commitment c in commitmentIterable) {
      ktotal += c.nonce;
      atotal += c.amountMod; // Changed from amount to amountMod.
      points.add(c.pointPUncompressed);
      setups.add(c.setup);
    }

    // Check for empty list of points.
    if (points.isEmpty) {
      throw ArgumentError('Empty list');
    }

    // Check if all setups are the same.
    PedersenSetup setup = setups[0]; // Changed Setup to PedersenSetup
    if (!setups.every((s) => s == setup)) {
      throw ArgumentError('Mismatched setups');
    }

    // Compute sum of nonces modulo group order.
    ktotal =
        ktotal % Utilities.secp256k1Params.n; // Changed order to setup.params.n

    // Check if summed nonce is zero.
    if (ktotal == BigInt.zero) {
      // Changed comparison from 0 to `BigInt.zero`.
      throw Exception('Nonce range error');
    }

    // Compute the sum of points if possible, else set to `null`.
    Uint8List? pointPUncompressed;
    if (points.length < 512) {
      try {
        pointPUncompressed = Utilities.addPoints(
          points,
          Utilities.secp256k1Params,
        );
      } on Exception {
        pointPUncompressed = null;
      }
    } else {
      pointPUncompressed = null;
    }

    // Return new Commitment object with summed values.
    return Commitment(
      setup,
      atotal,
      nonce: ktotal,
      pointPUncompressed: pointPUncompressed,
    );
  }
}
