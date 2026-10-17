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
    CsOpenAliasProxy? proxy,
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

void main() {
  test('isOpenAlias accepts only names that normalizeOpenAlias accepts', () {
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
}
