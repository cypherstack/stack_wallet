import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/amount/fee_rate_formatter.dart';

void main() {
  test('fractional fee rates retain one decimal place', () {
    expect(formatApproximateFeeRate(BigInt.from(125), 100), '~1.3');
    expect(formatApproximateFeeRate(BigInt.from(124), 100), '~1.2');
    expect(formatApproximateFeeRate(BigInt.one, 3), '~0.3');
    expect(formatApproximateFeeRate(BigInt.from(100), 100), '~1.0');
    expect(formatApproximateFeeRate(BigInt.zero, 100), '~0.0');
  });

  test('unknown and invalid fees or sizes have no display value', () {
    expect(formatApproximateFeeRate(null, 100), isNull);
    expect(formatApproximateFeeRate(BigInt.one, null), isNull);
    expect(formatApproximateFeeRate(BigInt.one, 0), isNull);
    expect(formatApproximateFeeRate(BigInt.one, -1), isNull);
    expect(formatApproximateFeeRate(-BigInt.one, 100), isNull);
  });

  test('large atomic fees are formatted without floating point loss', () {
    expect(
      formatApproximateFeeRate(BigInt.parse('9007199254740993125'), 100),
      '~90071992547409931.3',
    );
  });
}
