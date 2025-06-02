import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/models.dart';

void main() {
  test("FeeObject constructor", () {
    final feeObject = FeeObject(
      fast: BigInt.from(3),
      medium: BigInt.from(2),
      slow: BigInt.from(1),
      numberOfBlocksFast: 4,
      numberOfBlocksSlow: 5,
      numberOfBlocksAverage: 10,
    );
    expect(
      feeObject.toString(),
      "{fast: 3, medium: 2, slow: 1, numberOfBlocksFast: 4, numberOfBlocksAverage: 10, numberOfBlocksSlow: 5}",
    );
  });
}
