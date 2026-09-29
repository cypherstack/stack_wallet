import 'dart:io';

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
  for (final domain in ['openalias.org', 'dnssec-failed.org']) {
    test('live unsigned or bogus DNS is rejected: $domain', () async {
      await expectLater(
        service.resolve(domain, validateAddress: validate),
        throwsA(isA<OpenAliasException>()),
      );
    }, skip: skip);
  }
}
