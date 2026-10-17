import 'dart:io';

import 'package:cs_openalias/cs_openalias.dart';
import 'package:flutter_test/flutter_test.dart';
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
    'live signed alias uses native DNSSEC and Monero address validation',
    () async {
      final result = await service
          .lookup(
            'donate.getmonero.org',
            isValidAddress: validate,
            application: 'xmr',
          )
          .result;
      expect(result.domain, 'donate.getmonero.org');
      expect(validate(result.address), isTrue);
    },
    skip: skip,
  );

  test('live nonexistent name is reported with the alias', () async {
    await expectLater(
      service
          .lookup(
            'dan@cypherstack',
            isValidAddress: validate,
            application: 'xmr',
          )
          .result,
      throwsA(
        isA<CsOpenAliasNoRecordException>().having(
          (error) => error.userMessage,
          'userMessage',
          'No OpenAlias address was found for dan.cypherstack.',
        ),
      ),
    );
  }, skip: skip);

  for (final domain in ['openalias.org', 'dnssec-failed.org']) {
    test('live unsigned or bogus DNS is rejected: $domain', () async {
      await expectLater(
        service
            .lookup(domain, isValidAddress: validate, application: 'xmr')
            .result,
        throwsA(isA<CsOpenAliasException>()),
      );
    }, skip: skip);
  }
}
