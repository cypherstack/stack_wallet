import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:openalias/openalias.dart' as oa;
import 'package:stackwallet/services/openalias/open_alias.dart';
import 'package:stackwallet/services/openalias/send_preview.dart';

import 'open_alias_test_fixtures.dart';

void main() {
  late SendPreview preview;
  late List<ResolvedSendRecipient> prepared;
  late List<Object> errors;
  var calls = 0;
  setUp(() {
    preview = SendPreview();
    prepared = [];
    errors = [];
    calls = 0;
  });
  tearDown(() => preview.dispose());

  Future<void> run({
    String source = 'Alice@Example',
    Future<OpenAliasRecipient>? pending,
    bool Function()? current,
    Future<void>? preparing,
  }) => preview.run(
    walletId: 'wallet',
    source: source,
    isCurrent: current ?? () => true,
    work: (attempt) async {
      final result = await attempt.resolve(
        supportsOpenAlias: true,
        validateAddress: (address) => address == 'literal',
        lookup: (domain) {
          calls++;
          expect(domain, 'alice.example');
          return pending ??
              Future.value(
                const OpenAliasRecipient(
                  domain: 'alice.example',
                  address: 'literal',
                ),
              );
        },
      );
      attempt.checkCurrent();
      prepared.add(result);
      if (preparing != null) await preparing;
      attempt.checkCurrent();
    },
    onError: (e, _) => errors.add(e),
  );

  test('literal address bypasses lookup', () async {
    await run(source: 'literal');
    expect(calls, 0);
    expect(prepared.single.destination, 'literal');
    expect(prepared.single.alias, isNull);
  });
  test(
    'each preview resolves anew and prepares only a validated address',
    () async {
      await run();
      await run();
      expect(calls, 2);
      expect(prepared.map((e) => e.destination), ['literal', 'literal']);
      expect(prepared.last.alias!.domain, 'alice.example');
      expect(prepared.last.alias!.displayAlias, 'alice@example');
      expect(errors, isEmpty);
    },
  );
  test('confirmation preserves the validated DNS provenance', () async {
    final dns = authenticatedTxt('alice.example', [
      'oa1:xmr recipient_address=literal;',
    ]);
    final resolved = await oa.OpenAliasResolver(
      lookup: (_) async => dns,
      application: 'xmr',
      validateAddress: (address) => address == 'literal',
      trustedValidators: testValidators,
    ).resolve('alice.example');
    await run(
      pending: Future.value(
        OpenAliasRecipient(
          domain: 'alice.example',
          address: 'literal',
          resolved: resolved,
        ),
      ),
    );
    expect(prepared.single.alias!.dns, same(dns));
  });

  test('lookup failures do not prepare', () async {
    await run(pending: Future.error(const OpenAliasException('DNSSEC failed')));
    expect(prepared, isEmpty);
    expect(errors.single.toString(), 'DNSSEC failed');
    expect(preview.busy, isFalse);
  });
  test('invalid resolver results do not prepare', () async {
    await run(
      pending: Future.value(
        const OpenAliasRecipient(
          domain: 'alice.example',
          address: 'wrong-wallet',
        ),
      ),
    );
    expect(prepared, isEmpty);
    expect(errors.single, isA<OpenAliasException>());
  });
  test('duplicate previews are suppressed while lookup is pending', () async {
    final pending = Completer<OpenAliasRecipient>();
    final first = run(pending: pending.future);
    await run();
    expect(calls, 1);
    pending.complete(
      const OpenAliasRecipient(domain: 'alice.example', address: 'literal'),
    );
    await first;
    expect(prepared, hasLength(1));
  });
  for (final reason in ['edit away and back', 'cancel', 'wallet switch']) {
    test('$reason invalidates old success and permits a new attempt', () async {
      final pending = Completer<OpenAliasRecipient>();
      final first = run(pending: pending.future);
      preview.invalidate();
      await run();
      pending.complete(
        const OpenAliasRecipient(domain: 'alice.example', address: 'literal'),
      );
      await first;
      expect(prepared, hasLength(1));
      expect(errors, isEmpty);
    });
  }
  test('a stale failure cannot show an error over the new draft', () async {
    final pending = Completer<OpenAliasRecipient>();
    final first = run(pending: pending.future);
    preview.invalidate();
    pending.completeError(const OpenAliasException('old failure'));
    await first;
    expect(prepared, isEmpty);
    expect(errors, isEmpty);
  });
  test(
    'external wallet/source identity is checked before preparation',
    () async {
      var current = true;
      final pending = Completer<OpenAliasRecipient>();
      final first = run(pending: pending.future, current: () => current);
      current = false;
      pending.complete(
        const OpenAliasRecipient(domain: 'alice.example', address: 'literal'),
      );
      await first;
      expect(prepared, isEmpty);
    },
  );
  test('cancel during preparation prevents navigation', () async {
    final pending = Completer<void>();
    var navigated = false;
    final first = preview.run(
      walletId: 'wallet',
      source: 'literal',
      isCurrent: () => true,
      work: (attempt) async {
        await pending.future;
        attempt.checkCurrent();
        navigated = true;
      },
      onError: (e, _) => errors.add(e),
    );
    preview.invalidate();
    pending.complete();
    await first;
    expect(navigated, isFalse);
    expect(errors, isEmpty);
  });
  test(
    'disposal invalidates lookup without notifying a disposed screen',
    () async {
      final pending = Completer<OpenAliasRecipient>();
      final first = run(pending: pending.future);
      final disposed = preview;
      disposed.dispose();
      preview = SendPreview();
      pending.complete(
        const OpenAliasRecipient(domain: 'alice.example', address: 'literal'),
      );
      await first;
      expect(prepared, isEmpty);
      expect(errors, isEmpty);
    },
  );
}
