import 'dart:io';

import 'package:dnssec_resolver/dnssec_resolver.dart';
import 'package:doh_resolver/doh_resolver_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/services/openalias/open_alias.dart';
import 'package:stackwallet/services/openalias/open_alias_service.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

void main() {
  final skip = Platform.environment['OPENALIAS_LIVE_TESTS'] != '1';
  final service = OpenAliasService(
    externalCalls: () => true,
    useTor: () => false,
  );
  final validate = Monero(CryptoCurrencyNetwork.main).validateAddress;
  test('native DNSSEC and Monero address validation run in Flutter', () async {
    final transport = IoDohTransport();
    addTearDown(transport.close);
    final dns = await DnssecResolver(
      transport: transport,
    ).lookupTxt('donate.getmonero.org');
    expect(dns.authentication, DnsAuthentication.locallyValidated);
    final record = dns.records
        .map((r) => r.text)
        .firstWhere((r) => r.startsWith('oa1:xmr '));
    final address = RegExp(r'recipient_address=([^;]+)')
        .firstMatch(record)![1]!;
    expect(validate(address), isTrue);
  }, skip: skip);
  test(
    'live signed alias resolves to a valid Monero mainnet address',
    () async {
      final result = await service.resolve(
        'donate.getmonero.org',
        validateAddress: validate,
      );
      expect(result.domain, 'donate.getmonero.org');
      expect(validate(result.address), isTrue);
    },
    skip: skip,
  );
  test('live nonexistent name is reported with the alias', () async {
    await expectLater(
      service.resolve('dan@cypherstack', validateAddress: validate),
      throwsA(
        isA<OpenAliasException>().having(
          (e) => e.message,
          'message',
          'No OpenAlias record exists for dan.cypherstack.',
        ),
      ),
    );
  }, skip: skip);
  for (final domain in ['openalias.org', 'dnssec-failed.org']) {
    test('live unsigned or bogus DNS is rejected: $domain', () async {
      await expectLater(
        service.resolve(domain, validateAddress: validate),
        throwsA(isA<OpenAliasException>()),
      );
    }, skip: skip);
  }
}
