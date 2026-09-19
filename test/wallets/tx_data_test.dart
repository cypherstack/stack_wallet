import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';

void main() {
  test('subtractFeeFromAmount defaults and copies', () {
    final txData = TxData();

    expect(txData.subtractFeeFromAmount, false);

    final enabled = txData.copyWith(subtractFeeFromAmount: true);
    expect(enabled.subtractFeeFromAmount, true);
    expect(enabled.copyWith().subtractFeeFromAmount, true);
    expect(
      enabled.copyWith(subtractFeeFromAmount: false).subtractFeeFromAmount,
      false,
    );
  });
}
