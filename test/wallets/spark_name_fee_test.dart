import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/spark_interface.dart';

void main() {
  test('Spark Name fee size includes the tagged output bytes', () {
    final baseScript = Uint8List(25);
    final feeScript = sparkNameFeeScript(
      baseScript: baseScript,
      name: 'alice',
      sparkAddress: List.filled(144, 'a').join(),
    );

    expect(feeScript.length - baseScript.length, 155);
    expect(feeScript.length, 180);
  });

  test('Spark Name payments never have the miner fee subtracted', () {
    expect(
      shouldSubtractSparkFeeFromAmount(
        isSparkNameRegistration: true,
        spendsAll: true,
      ),
      isFalse,
    );
    expect(
      shouldSubtractSparkFeeFromAmount(
        isSparkNameRegistration: false,
        spendsAll: true,
      ),
      isTrue,
    );
  });
}
