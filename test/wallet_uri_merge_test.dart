import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/utilities/address_utils.dart';

void main() {
  test(
    'wallet URI secrets stay redacted and malformed restores are rejected',
    () {
      final data = WalletUriData.fromUriString(
        'monero_wallet:?seed=alpha%20beta&height=123',
      );
      expect(data.seed, 'alpha beta');
      expect(data.height, 123);
      expect(data.toString(), isNot(contains('alpha beta')));
      for (final uri in [
        'monero:?seed=alpha',
        'monero_wallet:?seed=',
        'monero_wallet:?seed=alpha&height=-1',
        'monero_wallet:?seed=alpha&txid=123',
        'monero_wallet:?view_key=abcd',
      ]) {
        expect(
          () => WalletUriData.fromUriString(uri),
          throwsA(anyOf(isA<FormatException>(), isA<UnsupportedError>())),
        );
      }
    },
  );

  test('payment URI still parses percent-encoded recipient separators', () {
    final data = AddressUtils.parsePaymentUri(
      'monero:abc;def?tx_amount=1;2&recipient_name=Alice%3BBob;Carol',
      allowMultipleRecipients: true,
    );
    expect(data!.recipients.length, 2);
    expect(data.recipients.first.label, 'Alice;Bob');
  });
}
