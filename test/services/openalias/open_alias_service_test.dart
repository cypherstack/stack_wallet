import 'dart:async';
import 'dart:io';

import 'package:cs_openalias/cs_openalias.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/openalias/open_alias_service.dart';

const incognito =
    'OpenAlias lookups are off in Incognito mode. To use OpenAlias, switch '
    'Stack Experience to Easy Crypto in Advanced settings.';
const torUnavailable = 'Tor is unavailable. No lookup was sent.';

class _Calls {
  final aliases = <String>[];
  final proxies = <CsOpenAliasProxy?>[];
  final validators = <bool Function(String)>[];
  final applications = <String>[];
  final operations = <CsOpenAliasOperation<CsOpenAliasRecipient>>[];

  CsOpenAliasOperation<CsOpenAliasRecipient> lookup(
    String alias, {
    required bool Function(String address) isValidAddress,
    required String application,
    required CsOpenAliasProxy? proxy,
  }) {
    aliases.add(alias);
    proxies.add(proxy);
    validators.add(isValidAddress);
    applications.add(application);
    final operation = CsOpenAliasOperation<CsOpenAliasRecipient>(
      Future.error(CsOpenAliasNoRecordException('no record', alias: alias)),
      () {},
    );
    operations.add(operation);
    return operation;
  }
}

OpenAliasService _service(
  OpenAliasLookup lookup, {
  bool external = true,
  DateTime Function()? now,
}) => OpenAliasService(
  externalCalls: () => external,
  useTor: () => false,
  lookup: lookup,
  now: now,
);

OpenAliasService _answering(Duration ttl, DateTime Function() now) => _service(
  (alias, {required isValidAddress, required application, required proxy}) =>
      CsOpenAliasOperation(
        Future.value(
          CsOpenAliasRecipient(
            domain: 'alice.example.com',
            address: 'resolved',
            fields: const {'recipient_address': 'resolved'},
            ttl: ttl,
          ),
        ),
        () {},
      ),
  now: now,
);

final _start = DateTime.utc(2026, 10, 28, 12);

OpenAliasResolution _resolve(OpenAliasService service) => service.resolve(
  ' Alice@Example.com',
  isValidAddress: (_) => true,
  application: 'xmr',
  coinName: 'Monero',
);

void main() {
  test('isOpenAlias accepts names and rejects addresses', () {
    for (final input in ['Alice@Example.com', 'donate.getmonero.org.']) {
      expect(isOpenAlias(input), isTrue, reason: input);
    }
    for (final input in [
      '',
      'alice',
      'a@b@example.com',
      'alice example.com',
      '4AeRgkWZsMJhAWKMeCZ3h4ZSPnAcW5VBtRFyLd6gBEf6GgJU2FH',
    ]) {
      expect(isOpenAlias(input), isFalse, reason: input);
    }
  });

  test('every lookup failure has a user message', () {
    const alias = 'alice.example.com';
    final messages = {
      for (final e in <CsOpenAliasException>[
        const CsOpenAliasInvalidAliasException('', alias: alias),
        const CsOpenAliasNoRecordException('', alias: alias),
        const CsOpenAliasInvalidRecordException('', alias: alias),
        const CsOpenAliasDnssecException(
          '',
          alias: alias,
          status: CsOpenAliasDnssecStatus.bogus,
        ),
        const CsOpenAliasNetworkException('', alias: alias),
        const CsOpenAliasCancelledException('', alias: alias),
      ])
        openAliasErrorMessage(e, 'Monero'),
    };
    expect(messages, hasLength(6));
    expect(
      messages,
      contains('No Monero OpenAlias record was found for alice.example.com.'),
    );
  });

  test('Incognito mode sends nothing and names the setting', () {
    final calls = _Calls();
    final service = OpenAliasService(
      externalCalls: () => false,
      useTor: () => false,
      lookup: calls.lookup,
    );
    expect(service.unavailableReason(), incognito);
    expect(
      () => service.lookup(
        'alice@example.com',
        isValidAddress: (_) => true,
        application: 'xmr',
      ),
      throwsA(
        isA<OpenAliasUnavailableException>().having(
          (e) => e.message,
          'message',
          incognito,
        ),
      ),
    );
    expect(calls.aliases, isEmpty);
  });

  test('Tor that is unsupported or not connected has no direct fallback', () {
    final calls = _Calls();
    for (final (supported, torProxy)
        in <(bool, ({InternetAddress host, int port}) Function())>[
          (false, () => (host: InternetAddress.loopbackIPv4, port: 9050)),
          (true, () => throw Exception('Tor is not connected')),
        ]) {
      final service = OpenAliasService(
        externalCalls: () => true,
        useTor: () => true,
        supportsTor: () => supported,
        torProxy: torProxy,
        lookup: calls.lookup,
      );
      expect(service.unavailableReason(), torUnavailable);
      expect(
        () => service.lookup(
          'alice@example.com',
          isValidAddress: (_) => true,
          application: 'xmr',
        ),
        throwsA(
          isA<OpenAliasUnavailableException>().having(
            (e) => e.message,
            'message',
            torUnavailable,
          ),
        ),
      );
    }
    expect(calls.aliases, isEmpty);
  });

  test('the Tor proxy is passed only when Tor is on', () {
    for (final tor in [true, false]) {
      final calls = _Calls();
      final service = OpenAliasService(
        externalCalls: () => true,
        useTor: () => tor,
        supportsTor: () => true,
        torProxy: () => (host: InternetAddress.loopbackIPv4, port: 9050),
        lookup: calls.lookup,
      );
      expect(service.unavailableReason(), isNull);
      service.lookup(
        'alice@example.com',
        isValidAddress: (_) => true,
        application: 'xmr',
      );
      expect(calls.proxies.single?.address, tor ? '127.0.0.1' : null);
      expect(calls.proxies.single?.port, tor ? 9050 : null);
    }
  });

  test('the facade operation and arguments pass through unchanged', () {
    final calls = _Calls();
    final service = OpenAliasService(
      externalCalls: () => true,
      useTor: () => false,
      lookup: calls.lookup,
    );
    bool validate(String address) => address == 'valid';
    final operation = service.lookup(
      ' Alice@Example.com',
      isValidAddress: validate,
      application: 'btc',
    );
    expect(calls.aliases.single, ' Alice@Example.com');
    expect(calls.validators.single, same(validate));
    expect(calls.applications.single, 'btc');
    expect(operation, same(calls.operations.single));
  });

  test('the settings are read once for every lookup', () {
    final calls = _Calls();
    var reads = 0;
    var external = true;
    final service = OpenAliasService(
      externalCalls: () {
        reads++;
        return external;
      },
      useTor: () => false,
      lookup: calls.lookup,
    );
    service.lookup(
      'alice@example.com',
      isValidAddress: (_) => true,
      application: 'xmr',
    );
    expect(reads, 1);
    external = false;
    expect(
      () => service.lookup(
        'alice@example.com',
        isValidAddress: (_) => true,
        application: 'xmr',
      ),
      throwsA(isA<OpenAliasUnavailableException>()),
    );
    expect(reads, 2);
    expect(calls.aliases, hasLength(1));
  });

  group('resolve', () {
    test('returns the normalized alias and the address', () async {
      final aliases = <String>[];
      final service = _service((
        alias, {
        required isValidAddress,
        required application,
        required proxy,
      }) {
        aliases.add(alias);
        return CsOpenAliasOperation(
          Future.value(
            CsOpenAliasRecipient(
              domain: 'alice.example.com',
              address: 'resolved',
              fields: const {'recipient_address': 'resolved'},
              ttl: const Duration(minutes: 5),
            ),
          ),
          () {},
        );
      });
      final outcome = await _resolve(service).outcome;
      expect(aliases.single, ' Alice@Example.com');
      expect(
        outcome,
        isA<OpenAliasResolved>()
            .having((e) => e.alias, 'alias', 'alice@example.com')
            .having((e) => e.address, 'address', 'resolved'),
      );
    });

    test('the answer expires after its TTL', () async {
      final outcome = await _resolve(
        _answering(const Duration(seconds: 60), () => _start),
      ).outcome;
      expect(
        outcome,
        isA<OpenAliasResolved>().having(
          (e) => e.expiresAt,
          'expiresAt',
          _start.add(const Duration(seconds: 60)),
        ),
      );
    });

    test('a TTL over an hour is cut to an hour', () async {
      final outcome = await _resolve(
        _answering(const Duration(days: 2), () => _start),
      ).outcome;
      expect(
        outcome,
        isA<OpenAliasResolved>().having(
          (e) => e.expiresAt,
          'expiresAt',
          _start.add(const Duration(hours: 1)),
        ),
      );
    });

    test('a zero TTL is never current', () async {
      final service = _answering(Duration.zero, () => _start);
      final outcome = await _resolve(service).outcome as OpenAliasResolved;
      expect(outcome.expiresAt, _start);
      expect(service.isCurrent(outcome), isFalse);
    });

    test('isCurrent follows the clock', () async {
      var now = _start;
      final service = _answering(const Duration(seconds: 60), () => now);
      final outcome = await _resolve(service).outcome as OpenAliasResolved;
      expect(service.isCurrent(outcome), isTrue);
      now = _start.add(const Duration(seconds: 59));
      expect(service.isCurrent(outcome), isTrue);
      now = _start.add(const Duration(seconds: 60));
      expect(service.isCurrent(outcome), isFalse);
    });

    test('a lookup failure becomes its user message', () async {
      final service = _service((
        alias, {
        required isValidAddress,
        required application,
        required proxy,
      }) {
        return CsOpenAliasOperation(
          Future.error(
            const CsOpenAliasNoRecordException('', alias: 'alice.example.com'),
          ),
          () {},
        );
      });
      final outcome = await _resolve(service).outcome;
      expect(
        outcome,
        isA<OpenAliasFailed>()
            .having((e) => e.title, 'title', openAliasLookupFailedTitle)
            .having(
              (e) => e.message,
              'message',
              'No Monero OpenAlias record was found for alice.example.com.',
            ),
      );
    });

    test('an unavailable lookup shows the reason', () async {
      final calls = _Calls();
      final outcome = await _resolve(_service(calls.lookup, external: false))
          .outcome;
      expect(
        outcome,
        isA<OpenAliasFailed>().having((e) => e.message, 'message', incognito),
      );
      expect(calls.aliases, isEmpty);
    });

    test('any other error is logged, not shown', () async {
      final service = _service((
        alias, {
        required isValidAddress,
        required application,
        required proxy,
      }) {
        throw ArgumentError('bad application');
      });
      final logged = <String>[];
      final outcome = await runZoned(
        () => _resolve(service).outcome,
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => logged.add(line),
        ),
      );
      expect(
        outcome,
        isA<OpenAliasFailed>().having(
          (e) => e.message,
          'message',
          'The OpenAlias lookup failed.',
        ),
      );
      expect(logged.single, contains('bad application'));
    });

    test('cancel cancels the lookup', () async {
      final result = Completer<CsOpenAliasRecipient>();
      var cancels = 0;
      final service = _service((
        alias, {
        required isValidAddress,
        required application,
        required proxy,
      }) {
        return CsOpenAliasOperation(result.future, () {
          cancels++;
          result.completeError(
            CsOpenAliasCancelledException('cancelled', alias: alias),
          );
        });
      });
      final resolution = _resolve(service);
      resolution.cancel();
      expect(cancels, 1);
      expect(await resolution.outcome, isA<OpenAliasCancelled>());
    });
  });
}
