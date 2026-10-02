import 'dart:async';
import 'dart:io';

import 'package:doh_resolver/doh_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/openalias/open_alias.dart';
import 'package:stackwallet/services/openalias/open_alias_service.dart';

import 'open_alias_test_fixtures.dart';

void main() {
  test('privacy revocation blocks subsequent DNSSEC key requests', () async {
    var allowed = true;
    final underlying = _CountingTransport();
    final transport = OpenAliasDnsTransport(underlying, () => allowed);
    final endpoint = Uri.https('resolver.example', '/dns-query');
    await transport
        .startWire(endpoint, List.filled(12, 0), maxResponseBytes: 65535)
        .result;
    allowed = false;
    expect(
      () => transport.startWire(
        endpoint,
        List.filled(12, 0),
        maxResponseBytes: 65535,
      ),
      throwsA(
        isA<DnsException>().having((e) => e.code, 'code', DnsError.cancelled),
      ),
    );
    expect(underlying.calls, 1);
  });
  test(
    'remote AD assertion cannot satisfy the wallet local-validation policy',
    () async {
      final remote = DnsResponse.fromJson(
        {
          'Status': 0,
          'AD': true,
          'CD': false,
          'TC': false,
          'Question': [
            {'name': 'alice.example', 'type': 16},
          ],
          'Answer': [
            {
              'name': 'alice.example',
              'type': 16,
              'TTL': 60,
              'data': 'oa1:xmr recipient_address=valid;',
            },
          ],
        },
        resolver: Uri.https('resolver.example', '/resolve'),
      ).authenticatedTxt('alice.example');
      final resolver = OpenAliasService(
        externalCalls: () => true,
        useTor: () => false,
        lookup: (_, _) async => remote,
      );
      await expectLater(
        resolver.resolve('alice.example', validateAddress: (_) => true),
        throwsA(
          isA<OpenAliasException>().having(
            (e) => e.message,
            'message',
            contains('Local DNSSEC'),
          ),
        ),
      );
    },
  );
  OpenAliasService service(List<String> records) => OpenAliasService(
    externalCalls: () => true,
    useTor: () => false,
    lookup: (name, _) async => authenticatedTxt(name, records),
    trustedValidators: testValidators,
  );
  for (final records in [
    ['oa1:btc recipient_address=valid;'],
    ['oa1:xmr recipient_address=wrong-network;'],
    ['oa1:xmr recipient_address=valid;tx_payment_id=123;'],
    ['oa1:xmr recipient_address=valid;', 'oa1:xmr recipient_address=second;'],
    ['oa1:xmr recipient_address=valid;recipient_address=second;'],
  ]) {
    test(
      'package migration retains wallet rejection policy: $records',
      () async {
        await expectLater(
          service(records).resolve(
            'alice.example',
            validateAddress: (s) => s == 'valid' || s == 'second',
          ),
          throwsA(isA<OpenAliasException>()),
        );
      },
    );
  }
  test('payment ID aliases keep the wallet message', () async {
    await expectLater(
      service(['oa1:xmr recipient_address=valid;tx_payment_id=123;'])
          .resolve('alice.example', validateAddress: (_) => true),
      throwsA(
        isA<OpenAliasException>().having(
          (e) => e.message,
          'message',
          contains('separate payment ID'),
        ),
      ),
    );
  });
  test('only the on-device validator is trusted by default', () async {
    final resolver = OpenAliasService(
      externalCalls: () => true,
      useTor: () => false,
      lookup: (name, _) async =>
          authenticatedTxt(name, ['oa1:xmr recipient_address=valid;']),
    );
    await expectLater(
      resolver.resolve('alice.example', validateAddress: (_) => true),
      throwsA(
        isA<OpenAliasException>().having(
          (e) => e.message,
          'message',
          contains('Local DNSSEC'),
        ),
      ),
    );
  });
  test('DNS metadata does not replace the literal recipient', () async {
    final result = await service([
      'oa1:xmr recipient_address=valid;tx_amount=999;recipient_name=Someone;',
    ]).resolve('Alice@Example.', validateAddress: (s) => s == 'valid');
    expect(result.address, 'valid');
    expect(result.domain, 'alice.example');
    expect(result.dns!.authentication, DnsAuthentication.locallyValidated);
    expect(result.displayAlias, 'alice.example');
  });
  test('quotes inside an unquoted recipient name are literal', () async {
    final result = await service([
      'oa1:xmr recipient_address=valid; recipient_name=Alice "Vendor" Smith;',
    ]).resolve('alice.example', validateAddress: (s) => s == 'valid');
    expect(result.address, 'valid');
    expect(result.record!.fields['recipient_name'], 'Alice "Vendor" Smith');
  });
  test(
    'parses quoted values with semicolons and skips other prefixes',
    () async {
      final result = await service([
        'oa1:btc recipient_address=bad;',
        'oa1:xmrfoo recipient_address=bad;',
        'oa1:xmr recipient_name="Alice; Example";recipient_address="valid";',
      ]).resolve('alice.example', validateAddress: (s) => s == 'valid');
      expect(result.address, 'valid');
      expect(result.record!.fields['recipient_name'], 'Alice; Example');
    },
  );
  test('missing records name the alias', () async {
    await expectLater(
      service(['oa1:btc recipient_address=valid;'])
          .resolve('Alice@Example', validateAddress: (_) => true),
      throwsA(
        isA<OpenAliasException>().having(
          (e) => e.message,
          'message',
          'No Monero OpenAlias record was found for alice.example.',
        ),
      ),
    );
  });
  test('a nonexistent name is reported apart from a failed query', () async {
    for (final (code, message) in [
      (DnsError.noRecords, 'No OpenAlias record exists for alice.example.'),
      (
        DnsError.queryFailed,
        'The DNS lookup for alice.example failed. No address was accepted.',
      ),
    ]) {
      final resolver = OpenAliasService(
        externalCalls: () => true,
        useTor: () => false,
        lookup: (_, _) async => throw DnsException(code, 'failed'),
      );
      await expectLater(
        resolver.resolve('alice@example', validateAddress: (_) => true),
        throwsA(
          isA<OpenAliasException>().having(
            (e) => e.message,
            'message',
            message,
          ),
        ),
      );
    }
  });
  test('revoked external calls reject an in-flight result', () async {
    var allowed = true;
    final pending = Completer<AuthenticatedTxtResult>();
    final resolver = OpenAliasService(
      externalCalls: () => allowed,
      useTor: () => false,
      lookup: (_, _) => pending.future,
    );
    final future = resolver.resolve(
      'alice.example',
      validateAddress: (_) => true,
    );
    allowed = false;
    pending.complete(
      authenticatedTxt('alice.example', ['oa1:xmr recipient_address=valid;']),
    );
    await expectLater(
      future,
      throwsA(
        isA<OpenAliasException>().having(
          (e) => e.message,
          'message',
          contains('Privacy settings changed'),
        ),
      ),
    );
  });
  test(
    'package authentication failure is translated into a visible UI failure',
    () async {
      final resolver = OpenAliasService(
        externalCalls: () => true,
        useTor: () => false,
        lookup: (_, _) async => throw const DnsException(
          DnsError.authenticationUnavailable,
          'untrusted',
        ),
      );
      await expectLater(
        resolver.resolve('alice.example', validateAddress: (_) => true),
        throwsA(
          isA<OpenAliasException>().having(
            (e) => e.message,
            'message',
            contains('DNSSEC'),
          ),
        ),
      );
    },
  );
  test('each Tor lookup uses its own SOCKS isolation credentials', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final usernames = <String>[];
    server.listen((socket) {
      final buffer = <int>[];
      var greeted = false;
      socket.listen((data) {
        buffer.addAll(data);
        if (!greeted) {
          if (buffer.length < 2 || buffer.length < 2 + buffer[1]) return;
          final methods = buffer.sublist(2, 2 + buffer[1]);
          buffer.removeRange(0, 2 + buffer[1]);
          greeted = true;
          if (!methods.contains(2)) {
            socket.destroy();
            return;
          }
          socket.add([5, 2]);
        }
        if (buffer.length < 2 || buffer.length < 3 + buffer[1]) return;
        final userLength = buffer[1];
        if (buffer.length < 3 + userLength + buffer[2 + userLength]) return;
        usernames.add(String.fromCharCodes(buffer.sublist(2, 2 + userLength)));
        socket.add([1, 1]);
        socket.destroy();
      }, onError: (_) {});
    });
    final resolver = OpenAliasService(
      externalCalls: () => true,
      useTor: () => true,
      supportsTor: () => true,
      torProxy: () => (host: InternetAddress.loopbackIPv4, port: server.port),
    );
    for (var i = 1; i <= 2; i++) {
      await expectLater(
        resolver.resolve('alice.example', validateAddress: (_) => true),
        throwsA(isA<OpenAliasException>()),
      );
      expect(usernames.toSet(), hasLength(i));
    }
  });
  test('unavailable Tor produces no direct lookup fallback', () async {
    var calls = 0;
    final resolver = OpenAliasService(
      externalCalls: () => true,
      useTor: () => true,
      supportsTor: () => true,
      lookup: (_, tor) async {
        calls++;
        expect(tor, isTrue);
        throw StateError('Tor unavailable');
      },
    );
    await expectLater(
      resolver.resolve('alice.example', validateAddress: (_) => true),
      throwsA(isA<OpenAliasException>()),
    );
    expect(calls, 1);
  });
}

class _CountingTransport implements DohWireTransport {
  int calls = 0;
  @override
  DnsOperation<DohHttpResponse> startWire(
    Uri uri,
    List<int> query, {
    required int maxResponseBytes,
  }) {
    calls++;
    return DnsOperation(Future.value(DohHttpResponse(200, [])), () {});
  }
}
