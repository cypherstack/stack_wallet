import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_transaction_type.dart';

void main() {
  test('recognizes Spark spend transaction types', () {
    expect(isSparkSpendTransaction({'version': 3, 'type': 9}), isTrue);
    expect(isSparkSpendTransaction({'version': 3, 'type': 11}), isTrue);
    expect(isSparkSpendTransaction({'version': 3, 'type': 10}), isFalse);
    expect(isSparkSpendTransaction({'version': 2, 'type': 11}), isFalse);
  });
}
