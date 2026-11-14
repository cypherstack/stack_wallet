import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/address_utils.dart';

void main() {
  test('recipient metadata is immutable and private values are redacted', () {
    final memo = Uint8List.fromList('memo'.codeUnits);
    final params = {'reply-to': 'private-value'};
    final recipient = PaymentUriRecipient(
      address: 'recipient',
      memoBytes: memo,
      message: 'private-message',
      additionalParams: params,
    );

    memo[0] = 0;
    params['reply-to'] = 'changed';
    recipient.memoBytes![1] = 0;

    expect(recipient.memoText, 'memo');
    expect(recipient.additionalParams, {'reply-to': 'private-value'});
    expect(
      () => recipient.additionalParams['new'] = 'value',
      throwsUnsupportedError,
    );
    expect(recipient.toString(), isNot(contains('private-message')));
    expect(recipient.toString(), isNot(contains('private-value')));
    expect(recipient.toString(), contains('reply-to'));
  });

  test('payment URI data exposes only valid UTF-8 memo text', () {
    final valid = PaymentUriData(
      recipients: [
        PaymentUriRecipient(
          address: 'recipient',
          memoBytes: Uint8List.fromList('hello'.codeUnits),
        ),
      ],
      additionalParams: const {},
    );
    final invalid = PaymentUriData(
      recipients: [
        PaymentUriRecipient(
          address: 'recipient',
          memoBytes: Uint8List.fromList([0x80]),
        ),
      ],
      additionalParams: const {'memo': 'fallback'},
    );

    expect(valid.memo, 'hello');
    expect(invalid.memo, 'fallback');
  });
}
