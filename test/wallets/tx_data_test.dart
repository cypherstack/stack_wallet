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

  test('openAlias defaults to null and copies', () {
    expect(TxData().openAlias, isNull);
    expect(TxData().copyWith().openAlias, isNull);

    final txData = TxData(openAlias: 'donate@getmonero.org');
    expect(txData.openAlias, 'donate@getmonero.org');
    expect(txData.copyWith(note: 'note').openAlias, 'donate@getmonero.org');
    expect(
      TxData().copyWith(openAlias: 'alice@example.com').openAlias,
      'alice@example.com',
    );
  });
}
