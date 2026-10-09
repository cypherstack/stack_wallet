import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/openalias/send_recipient.dart';

void main() {
  SendRecipient classify(String input, {bool supportsOpenAlias = true}) =>
      SendRecipient.classify(
        input,
        supportsOpenAlias: supportsOpenAlias,
        validateAddress: (value) => value == 'literal-address',
      );

  test('paste and QR cleanup preserve raw aliases for validation', () {
    for (final input in [
      '\u00a0alice.example',
      'alice.example\ufeff',
      'alice.example\nignored',
    ]) {
      final prepared = prepareSendRecipientInput(
        input,
        supportsOpenAlias: true,
        validateAddress: (value) => value == 'literal-address',
      );
      expect(prepared, input);
      expect(classify(prepared).kind, SendRecipientKind.invalid);
    }
    expect(
      prepareSendRecipientInput(
        ' literal-address\nignored ',
        supportsOpenAlias: true,
        validateAddress: (value) => value == 'literal-address',
      ),
      'literal-address',
    );
  });

  test('pasted payment URIs retain whitespace and first-line cleanup', () {
    const uri = 'monero:literal-address?tx_amount=1';
    for (final input in [' $uri ', '$uri\nignored']) {
      expect(
        prepareSendRecipientInput(
          input,
          supportsOpenAlias: true,
          validateAddress: (_) => false,
        ),
        uri,
      );
    }
  });

  test('literal addresses take precedence and preserve case', () {
    final result = classify(' literal-address ');
    expect(result.kind, SendRecipientKind.literal);
    expect(result.destination, 'literal-address');
    expect(result.isAlias, isFalse);
    final domainAddress = SendRecipient.classify(
      'Native.Address',
      supportsOpenAlias: true,
      validateAddress: (_) => true,
    );
    expect(domainAddress.kind, SendRecipientKind.literal);
    expect(domainAddress.destination, 'Native.Address');
  });

  test('domain and email aliases use OpenAlias normalization', () {
    for (final input in [' Alice.Example. ', 'Alice@Example']) {
      final result = classify(input);
      expect(result.kind, SendRecipientKind.openAlias);
      expect(result.destination, 'alice.example');
    }
  });

  test('invalid forms remain invalid without a lookup', () {
    for (final input in [
      '',
      'alice',
      'a@@b.org',
      'https://alice.example',
      'a..org',
      '127.0.0.1',
      'a.onion',
      'ü.example',
      '\u00a0alice.example',
      'alice.example\ufeff',
      '\u2003alice.example',
      'monero:literal-address',
    ]) {
      expect(classify(input).kind, SendRecipientKind.invalid, reason: input);
    }
  });

  test('coins without the capability accept only their literal addresses', () {
    expect(
      classify('alice.example', supportsOpenAlias: false).kind,
      SendRecipientKind.invalid,
    );
    expect(
      classify('literal-address', supportsOpenAlias: false).kind,
      SendRecipientKind.literal,
    );
  });
}
