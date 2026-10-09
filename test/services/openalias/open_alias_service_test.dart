import 'dart:async';

import 'package:doh_resolver/doh_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/openalias/open_alias.dart';
import 'package:stackwallet/services/openalias/open_alias_service.dart';

import 'open_alias_test_fixtures.dart';

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
          return authenticatedTxt('alice.example', []);
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
      lookup: (_, _) async => authenticatedTxt('alice.example', []),
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
      final pending = Completer<AuthenticatedTxtResult>();
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
      pending.complete(
        authenticatedTxt('alice.example', ['oa1:xmr recipient_address=valid;']),
      );
      await expectLater(future, throwsA(isA<OpenAliasException>()));
    },
  );
  test(
    'cancellation settles promptly and ignores a late successful lookup',
    () async {
      final pending = Completer<AuthenticatedTxtResult>();
      final service = OpenAliasService(
        externalCalls: () => true,
        useTor: () => false,
        trustedValidators: testValidators,
        lookup: (_, _) => pending.future,
      );
      final operation = service.startResolve(
        'alice.example',
        validateAddress: (_) => true,
      );
      final result = expectLater(
        operation.result,
        throwsA(isA<OpenAliasException>()),
      );
      operation.cancel();
      operation.cancel();
      await result;
      pending.complete(
        authenticatedTxt('alice.example', ['oa1:xmr recipient_address=valid;']),
      );
      await Future<void>.delayed(Duration.zero);
    },
  );

  test(
    'caller mutations cannot extend the wallet validator allowlist',
    () async {
      final trusted = <DnsValidator>[];
      final service = OpenAliasService(
        externalCalls: () => true,
        useTor: () => false,
        trustedValidators: trusted,
        lookup: (_, _) async => authenticatedTxt('alice.example', [
          'oa1:xmr recipient_address=valid;',
        ]),
      );
      trusted.addAll(testValidators);
      await expectLater(
        service.resolve('alice.example', validateAddress: (_) => true),
        throwsA(isA<OpenAliasException>()),
      );
    },
  );

  test('returns only a validated literal recipient', () async {
    final service = OpenAliasService(
      externalCalls: () => true,
      useTor: () => false,
      supportsTor: () => true,
      lookup: (_, _) async => authenticatedTxt('alice.example', [
        'oa1:xmr recipient_address=valid;',
      ]),
      trustedValidators: testValidators,
    );
    final result = await service.resolve(
      'alice.example',
      validateAddress: (s) => s == 'valid',
    );
    expect(result.address, 'valid');
    expect(result.domain, 'alice.example');
  });
}
