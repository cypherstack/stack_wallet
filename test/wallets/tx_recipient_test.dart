import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/models/tx_recipient.dart';

void main() {
  test('freezes equality and hash inputs and redacts metadata values', () {
    final memo = Uint8List.fromList([1, 2, 3]);
    final params = {'reply-to': 'private-value'};
    final recipient = TxRecipient(
      address: 'recipient',
      amount: Amount(rawValue: BigInt.one, fractionDigits: 8),
      isChange: false,
      addressType: AddressType.nonWallet,
      memoBytes: memo,
      message: 'private-message',
      additionalParams: params,
    );
    final hash = recipient.hashCode;

    memo[0] = 9;
    params['reply-to'] = 'changed';
    recipient.memoBytes![1] = 9;

    expect(recipient.memoBytes, [1, 2, 3]);
    expect(recipient.additionalParams, {'reply-to': 'private-value'});
    expect(recipient.hashCode, hash);
    expect(
      () => recipient.additionalParams['new'] = 'value',
      throwsUnsupportedError,
    );
    expect(recipient.toString(), isNot(contains('private-message')));
    expect(recipient.toString(), isNot(contains('private-value')));
    expect(recipient.toString(), contains('reply-to'));
  });
}
