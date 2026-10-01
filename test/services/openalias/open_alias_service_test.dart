import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/openalias/open_alias.dart';
import 'package:stackwallet/services/openalias/open_alias_service.dart';

void main() {
  test('privacy restrictions prevent any network lookup', () async {
    var calls = 0;
    for (final policy in [(false, false, true), (true, true, false)]) {
      final service = OpenAliasService(
        externalCalls: () => policy.$1,
        useTor: () => policy.$2,
        supportsTor: () => policy.$3,
        lookup: (_, _) async {
          calls++;
          return [];
        },
      );
      await expectLater(
        service.resolve('alice.example', validateAddress: (_) => true),
        throwsA(isA<OpenAliasException>()),
      );
    }
    expect(calls, 0);
  });
  test('Incognito mode points to the setting that allows lookups', () async {
    final service = OpenAliasService(
      externalCalls: () => false,
      lookup: (_, _) async => [],
    );
    await expectLater(
      service.resolve('alice.example', validateAddress: (_) => true),
      throwsA(
        isA<OpenAliasException>().having(
          (e) => e.message,
          'message',
          contains('Experience to Easy Crypto in Advanced settings'),
        ),
      ),
    );
  });
  test(
    'Tor policy is passed to the lookup and a changed policy rejects results',
    () async {
      var tor = true;
      final pending = Completer<List<String>>();
      final service = OpenAliasService(
        externalCalls: () => true,
        useTor: () => tor,
        supportsTor: () => true,
        lookup: (domain, useTor) {
          expect(domain, 'alice.example');
          expect(useTor, isTrue);
          return pending.future;
        },
      );
      final future = service.resolve(
        'alice@example',
        validateAddress: (_) => true,
      );
      tor = false;
      pending.complete(['oa1:xmr recipient_address=valid;']);
      await expectLater(future, throwsA(isA<OpenAliasException>()));
    },
  );
  test('returns only a validated literal recipient', () async {
    final service = OpenAliasService(
      externalCalls: () => true,
      useTor: () => false,
      supportsTor: () => true,
      lookup: (_, _) async => ['oa1:xmr recipient_address=valid;'],
    );
    final result = await service.resolve(
      'alice.example',
      validateAddress: (s) => s == 'valid',
    );
    expect(result.address, 'valid');
    expect(result.domain, 'alice.example');
  });
}
