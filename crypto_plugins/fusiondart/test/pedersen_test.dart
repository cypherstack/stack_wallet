import 'package:fusiondart/src/exceptions.dart';
import 'package:fusiondart/src/extensions/on_string.dart';
import 'package:fusiondart/src/extensions/on_uint8list.dart';
import 'package:fusiondart/src/pedersen.dart';
import 'package:fusiondart/src/util.dart';
import 'package:test/test.dart';

void main() {
  test('Test Bad PedersenSetup', () {
    final invalidHPointHex1 =
        "0379be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
    final invalidHPointHex2 =
        "0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798b7c52588d95c3b9aa25b0403f1eef75702e84bb7597aabe663b82f6f04ef2777";

    expect(
      () => PedersenSetup(invalidHPointHex1.toUint8ListFromHex),
      throwsA(isA<InsecureHPoint>()),
      reason: 'Should raise InsecureHPoint exception for invalid H point 1',
    );

    expect(
      () => PedersenSetup(invalidHPointHex2.toUint8ListFromHex),
      throwsA(isA<InsecureHPoint>()),
      reason: 'Should raise InsecureHPoint exception for invalid H point 2',
    );

    final nonPointHex =
        "030000000000000000000000000000000000000000000000000000000000000007";

    expect(
      () => PedersenSetup(nonPointHex.toUint8ListFromHex),
      throwsA(isA<ArgumentError>()),
      reason: 'Should raise ArgumentError for non-point input',
    );
  });

  test('PedersenSetup', () {
    final order =
        "0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
            .toUint8ListFromHex
            .toBigInt;

    expect(order, Utilities.secp256k1Params.n);

    final setup = PedersenSetup(
      "\x02The scalar for this x is unknown".toUint8ListFromUtf8,
    );
    final commit0 = setup.commit(BigInt.zero);

    final commit5 = Commitment(setup, BigInt.from(5));
    final commit10m = setup.commit(BigInt.from(-10));

    final sumNonce = (commit0.nonce + commit5.nonce + commit10m.nonce) % order;

    final sumA = Commitment.addCommitments([
      commit0,
      commit5,
      commit10m,
    ]);
    final sumB = Commitment(setup, BigInt.from(-5), nonce: sumNonce);

    expect(sumA.nonce, sumB.nonce);
    expect(sumA.amountMod, sumB.amountMod);
    expect(sumA.pointPUncompressed.equals(sumB.pointPUncompressed), true);
    expect(sumA.pointPCompressed.equals(sumB.pointPCompressed), true);
  });
}
