import 'package:pointycastle/ecc/api.dart';
import 'util.dart';
import 'dart:math';
import 'dart:typed_data';

ECDomainParameters getDefaultParams() {
  return ECDomainParameters("secp256k1");
}

class NullPointError implements Exception {
  String errMsg() => 'NullPointError: Either Hpoint or HGpoint is null.';
}


class NonceRangeError implements Exception {
  final String message;
  NonceRangeError([this.message = "Nonce value must be in the range 0 < nonce < order"]);
  String toString() => "NonceRangeError: $message";
}

class ResultAtInfinity implements Exception {
  final String message;
  ResultAtInfinity([this.message = "Result is at infinity"]);
  String toString() => "ResultAtInfinity: $message";
}

class InsecureHPoint implements Exception {
  final String message;
  InsecureHPoint([this.message = "The H point has a known discrete logarithm, which means the commitment setup is broken"]);
  String toString() => "InsecureHPoint: $message";
}



class PedersenSetup {
  late ECPoint _H;
  late ECPoint _HG;
  late ECDomainParameters _params;
  ECDomainParameters get params => _params;

  PedersenSetup(this._H) {
    _params = new ECDomainParameters("secp256k1");
    // validate H point
    if (!Util.isPointOnCurve(_H, _params.curve)) {
      throw Exception('H is not a valid point on the curve');
    }
    _HG = Util.combinePubKeys([_H, _params.G]);
  }

  Uint8List get H => _H.getEncoded(false);
  Uint8List get HG => _HG.getEncoded(false);

  Commitment commit(BigInt amount, {BigInt? nonce, Uint8List? PUncompressed}) {
    return Commitment(this, amount, nonce: nonce, PUncompressed: PUncompressed);
  }

}

class Commitment {
  late PedersenSetup setup; // Added setup property to Commitment class
  late BigInt amountMod;
  late BigInt nonce;
  late Uint8List PUncompressed;


  Commitment(this.setup, BigInt amount, {BigInt? nonce, Uint8List? PUncompressed}) {
    this.nonce = nonce ?? Util.secureRandomBigInt(setup.params.n.bitLength);
    amountMod = amount % setup.params.n;

    if (this.nonce <= BigInt.zero || this.nonce >= setup.params.n) {
      throw NonceRangeError();
    }

    ECPoint? Hpoint = setup._H;
    ECPoint? HGpoint = setup._HG;

    if (Hpoint == null || HGpoint == null) {
      throw NullPointError();
    }

    BigInt multiplier1 = (amountMod - this.nonce) % setup.params.n;
    BigInt multiplier2 = this.nonce;

    ECPoint? HpointMultiplied = Hpoint * multiplier1;
    ECPoint? HGpointMultiplied = HGpoint * multiplier2;

    ECPoint? Ppoint = HpointMultiplied != null && HGpointMultiplied != null ? HpointMultiplied + HGpointMultiplied : null;

    if (Ppoint == setup.params.curve.infinity) {
      throw ResultAtInfinity();
    }

    this.PUncompressed = PUncompressed ?? Ppoint?.getEncoded(false) ?? Uint8List(0);
  }

  void calcInitial(PedersenSetup setup, BigInt amount) {
    amountMod = amount % setup.params.n;
    nonce = Util.secureRandomBigInt(setup.params.n.bitLength);

    ECPoint? Hpoint = setup._H;
    ECPoint? HGpoint = setup._HG;

    if (nonce <= BigInt.zero || nonce >= setup.params.n) {
      throw NonceRangeError();
    }

    if (Hpoint == null || HGpoint == null) {
      throw NullPointError();
    }

    BigInt multiplier1 = amountMod;
    BigInt multiplier2 = nonce;

    ECPoint? HpointMultiplied = Hpoint * multiplier1;
    ECPoint? HGpointMultiplied = HGpoint * multiplier2;

    ECPoint? Ppoint = HpointMultiplied != null && HGpointMultiplied != null ? HpointMultiplied + HGpointMultiplied : null;

    if (Ppoint == setup.params.curve.infinity) {
      throw ResultAtInfinity();
    }

    PUncompressed = Ppoint?.getEncoded(false) ?? Uint8List(0);
  }

  static Uint8List add_points(Iterable<Uint8List> pointsIterable) {
    ECDomainParameters params = getDefaultParams(); // Using helper function here
    var pointList = pointsIterable.map((pser) => Util.ser_to_point(pser, params)).toList();

    if (pointList.isEmpty) {
      throw ArgumentError('Empty list');
    }

    ECPoint pSum = pointList.first; // Initialize pSum with the first point in the list

    for (var i = 1; i < pointList.length; i++) {
      pSum = (pSum + pointList[i])!;
    }

    if (pSum == params.curve.infinity) {
      throw Exception('Result is at infinity');
    }

    return Util.point_to_ser(pSum, false);
  }


  Commitment addCommitments(Iterable<Commitment> commitmentIterable) {
    BigInt ktotal = BigInt.zero; // Changed to BigInt from int
    BigInt atotal = BigInt.zero; // Changed to BigInt from int
    List<Uint8List> points = [];
    List<PedersenSetup> setups = []; // Changed Setup to PedersenSetup
    for (Commitment c in commitmentIterable) {
      ktotal += c.nonce;
      atotal += c.amountMod; // Changed from amount to amountMod
      points.add(c.PUncompressed);
      setups.add(c.setup);
    }

    if (points.isEmpty) {
      throw ArgumentError('Empty list');
    }

    PedersenSetup setup = setups[0]; // Changed Setup to PedersenSetup
    if (!setups.every((s) => s == setup)) {
      throw ArgumentError('Mismatched setups');
    }

    ktotal = ktotal % setup.params.n; // Changed order to setup.params.n

    if (ktotal == BigInt.zero) { // Changed comparison from 0 to BigInt.zero
      throw Exception('Nonce range error');
    }

    Uint8List? PUncompressed;
    if (points.length < 512) {
      try {
        PUncompressed = add_points(points);
      } on Exception {
        PUncompressed = null;
      }
    } else {
      PUncompressed = null;
    }
    return Commitment(setup, atotal, nonce: ktotal, PUncompressed: PUncompressed);
  }
}
