import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/openalias/open_alias.dart';

void main() {
  test('normalizes email aliases, case and root dot', () {
    expect(normalizeOpenAlias(' Alice@Example. '), 'alice.example');
    expect(
      normalizeOpenAlias('xn--bcher-kva.example'),
      'xn--bcher-kva.example',
    );
    expect(normalizeOpenAlias('Dan_M@_Pay.Example'), 'dan_m._pay.example');
  });
  test('displays aliases as entered, without case or root dot', () {
    expect(displayOpenAlias(' Dan@CypherStack.com. '), 'dan@cypherstack.com');
    const recipient = OpenAliasRecipient(domain: 'a.example', address: 'x');
    expect(recipient.displayAlias, 'a.example');
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
    'a.localhost',
    'a.org\u0000',
  ]) {
    test('rejects invalid alias $name', () {
      expect(
        () => normalizeOpenAlias(name),
        throwsA(isA<OpenAliasException>()),
      );
    });
  }
}
