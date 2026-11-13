import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/wallet/supporting/mimblewimblecoin_wallet_math.dart';

void main() {
  test("MWC fee estimation is skipped only for unusable inputs", () {
    expect(shouldSkipMwcFeeEstimate(amount: 0, available: 1), isTrue);
    expect(shouldSkipMwcFeeEstimate(amount: -1, available: 1), isTrue);
    expect(shouldSkipMwcFeeEstimate(amount: 1, available: 0), isTrue);
    expect(shouldSkipMwcFeeEstimate(amount: 1, available: -1), isTrue);
    expect(shouldSkipMwcFeeEstimate(amount: 1, available: 1), isFalse);
  });

  test("MWC restore height uses its exact first-block timestamp", () {
    final genesis = DateTime.fromMillisecondsSinceEpoch(
      1573462801 * 1000,
      isUtc: true,
    );

    expect(estimateMwcRestoreHeight(genesis), 0);
    expect(
      estimateMwcRestoreHeight(genesis.add(const Duration(seconds: 60))),
      0,
    );
    expect(
      estimateMwcRestoreHeight(genesis.add(const Duration(seconds: 61))),
      1,
    );
    expect(
      estimateMwcRestoreHeight(genesis.subtract(const Duration(days: 1))),
      0,
    );
  });
}
