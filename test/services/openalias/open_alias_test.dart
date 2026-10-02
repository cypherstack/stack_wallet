import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/openalias/open_alias.dart';

OpenAliasRecipient select(List<String> records) => selectOpenAliasRecipient(
  domain: 'alice.example',
  records: records,
  validateAddress: (s) => s == 'valid' || s == 'second',
);

void main() {
  test('normalizes email aliases, case and root dot', () {
    expect(normalizeOpenAlias(' Alice@Example. '), 'alice.example');
    expect(
      normalizeOpenAlias('xn--bcher-kva.example'),
      'xn--bcher-kva.example',
    );
    expect(normalizeOpenAlias('Dan_M@_Pay.Example'), 'dan_m._pay.example');
  });
  test('names the alias when it has no Monero record', () {
    expect(
      () => select(['oa1:btc recipient_address=valid;']),
      throwsA(
        isA<OpenAliasException>().having(
          (e) => e.message,
          'message',
          'No Monero OpenAlias record was found for alice.example.',
        ),
      ),
    );
  });
  test('displays aliases as entered, without case or root dot', () {
    expect(displayOpenAlias(' Dan@CypherStack.com. '), 'dan@cypherstack.com');
  });
  for (final name in [
    'example',
    'https://example.org',
    'a@@b.org',
    'a..org',
    'a.org/path',
    '-a.org',
    'ü.example',
    'K.example',
    '127.0.0.1',
    'a.onion',
    'a.org\u0000',
  ]) {
    test('rejects invalid alias $name', () {
      expect(
        () => normalizeOpenAlias(name),
        throwsA(isA<OpenAliasException>()),
      );
    });
  }
  test(
    'parses semicolon fields and quoted values without requiring spaces',
    () {
      expect(
        select([
          'oa1:xmr recipient_name="Alice; Example";recipient_address="valid";',
        ]).address,
        'valid',
      );
    },
  );
  test('ignores other coins and nonmatching currency prefixes', () {
    expect(
      select([
        'oa1:btc recipient_address=bad;',
        'oa1:xmrfoo recipient_address=bad;',
        'oa1:xmr recipient_address=valid;',
      ]).address,
      'valid',
    );
  });
  for (final records in [
    <String>[],
    ['oa1:xmr recipient_address=wrong-network;'],
    ['oa1:xmr recipient_address=valid;recipient_address=second;'],
    ['oa1:xmr recipient_address=valid;', 'oa1:xmr recipient_address=second;'],
    ['oa1:xmr recipient_address=valid;tx_payment_id=0123456789abcdef;'],
    ['oa1:xmr recipient_address="valid;'],
  ]) {
    test(
      'rejects missing, invalid or ambiguous payment instructions $records',
      () {
        expect(() => select(records), throwsA(isA<OpenAliasException>()));
      },
    );
  }
  test('does not apply suggested amounts or names to recipient', () {
    final result = select([
      'oa1:xmr recipient_address=valid;tx_amount=999;recipient_name=Someone;',
    ]);
    expect(result.domain, 'alice.example');
    expect(result.address, 'valid');
  });
}
