import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/models.dart';

void main() {
  test("FeeObject constructor", () {
    final feeObject = FeeObject(
      fast: 3,
      medium: 2,
      slow: 1,
      numberOfBlocksFast: 4,
      numberOfBlocksSlow: 5,
      numberOfBlocksAverage: 10,
    );
    expect(feeObject.toString(),
        "{fast: 3, medium: 2, slow: 1, numberOfBlocksFast: 4, numberOfBlocksAverage: 10, numberOfBlocksSlow: 5}");
  });

  test("FeeObject.fromJson factory", () {
    final feeObject = FeeObject.fromJson({
      "fast": 3,
      "average": 2,
      "slow": 1,
      "numberOfBlocksFast": 4,
      "numberOfBlocksSlow": 5,
      "numberOfBlocksAverage": 6,
    });
    expect(feeObject.toString(),
        "{fast: 3, medium: 2, slow: 1, numberOfBlocksFast: 4, numberOfBlocksAverage: 6, numberOfBlocksSlow: 5}");
  });
}
