import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/exceptions/exchange/exchange_exception.dart';
import 'package:stackwallet/models/exchange/change_now/cn_exchange_transaction.dart';
import 'package:stackwallet/models/exchange/change_now/cn_exchange_transaction_status.dart';
import 'package:stackwallet/models/exchange/response_objects/estimate.dart';
import 'package:stackwallet/networking/http.dart';
import 'package:stackwallet/services/exchange/change_now/change_now_api.dart';

import 'change_now_sample_data.dart';
import 'change_now_test.mocks.dart';

@GenerateMocks([HTTP])
void main() {
  const testApiKey = 'testAPIKEY';

  Uri buildV2Uri(String path, [Map<String, String>? params]) {
    return Uri.https('api.changenow.io', '/v2$path', params);
  }

  Map<String, String> changeNowHeaders([String apiKey = '']) {
    return {'Content-Type': 'application/json', 'x-changenow-api-key': apiKey};
  }

  String buildCreateExchangeBody({
    required String fromCurrency,
    required String fromNetwork,
    required String toCurrency,
    required String toNetwork,
    required String fromAmount,
    required String toAmount,
    required String flow,
    required String type,
    required String address,
    String extraId = '',
    String refundAddress = '',
    String refundExtraId = '',
    String userId = '',
    String payload = '',
    String contactEmail = '',
    String rateId = '',
  }) {
    return jsonEncode({
      'fromCurrency': fromCurrency,
      'fromNetwork': fromNetwork,
      'toCurrency': toCurrency,
      'toNetwork': toNetwork,
      'fromAmount': fromAmount,
      'toAmount': toAmount,
      'flow': flow,
      'type': type,
      'address': address,
      'extraId': extraId,
      'refundAddress': refundAddress,
      'refundExtraId': refundExtraId,
      'userId': userId,
      'payload': payload,
      'contactEmail': contactEmail,
      'rateId': rateId,
    });
  }

  group('getAvailableCurrencies', () {
    test('getAvailableCurrencies succeeds without options', () async {
      final client = MockHTTP();
      final instance = ChangeNowAPI(http: client);

      when(
        client.get(
          url: buildV2Uri('/exchange/currencies', {'flow': 'standard'}),
          headers: changeNowHeaders(testApiKey),
          proxyInfo: null,
        ),
      ).thenAnswer(
        (_) async =>
            Response(utf8.encode(jsonEncode(availableCurrenciesJSON)), 200),
      );

      final result = await instance.getAvailableCurrencies(apiKey: testApiKey);

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value!.length, 538);
    });

    test('getAvailableCurrencies succeeds with active option', () async {
      final client = MockHTTP();
      final instance = ChangeNowAPI(http: client);

      when(
        client.get(
          url: buildV2Uri('/exchange/currencies', {
            'flow': 'standard',
            'active': 'true',
          }),
          headers: changeNowHeaders(testApiKey),
          proxyInfo: null,
        ),
      ).thenAnswer(
        (_) async => Response(
          utf8.encode(jsonEncode(availableCurrenciesJSONActive)),
          200,
        ),
      );

      final result = await instance.getAvailableCurrencies(
        active: true,
        apiKey: testApiKey,
      );

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value!.length, 531);
    });

    test('getAvailableCurrencies succeeds with fixedRate option', () async {
      final client = MockHTTP();
      final instance = ChangeNowAPI(http: client);

      when(
        client.get(
          url: buildV2Uri('/exchange/currencies', {'flow': 'fixed-rate'}),
          headers: changeNowHeaders(testApiKey),
          proxyInfo: null,
        ),
      ).thenAnswer(
        (_) async => Response(
          utf8.encode(jsonEncode(availableCurrenciesJSONFixedRate)),
          200,
        ),
      );

      final result = await instance.getAvailableCurrencies(
        flow: CNFlow.fixedRate,
        apiKey: testApiKey,
      );

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value!.length, 410);
    });

    test(
      'getAvailableCurrencies succeeds with fixedRate and active options',
      () async {
        final client = MockHTTP();
        final instance = ChangeNowAPI(http: client);

        when(
          client.get(
            url: buildV2Uri('/exchange/currencies', {
              'flow': 'fixed-rate',
              'active': 'true',
            }),
            headers: changeNowHeaders(testApiKey),
            proxyInfo: null,
          ),
        ).thenAnswer(
          (_) async => Response(
            utf8.encode(jsonEncode(availableCurrenciesJSONActiveFixedRate)),
            200,
          ),
        );

        final result = await instance.getAvailableCurrencies(
          active: true,
          flow: CNFlow.fixedRate,
          apiKey: testApiKey,
        );

        expect(result.exception, null);
        expect(result.value == null, false);
        expect(result.value!.length, 410);
      },
    );

    test(
      'getAvailableCurrencies fails with ChangeNowExceptionType.serializeResponseError',
      () async {
        final client = MockHTTP();
        final instance = ChangeNowAPI(http: client);

        when(
          client.get(
            url: buildV2Uri('/exchange/currencies', {'flow': 'standard'}),
            headers: changeNowHeaders(testApiKey),
            proxyInfo: null,
          ),
        ).thenAnswer(
          (_) async => Response(
            utf8.encode('{"some unexpected": "but valid json data"}'),
            200,
          ),
        );

        final result = await instance.getAvailableCurrencies(
          apiKey: testApiKey,
        );

        expect(
          result.exception!.type,
          ExchangeExceptionType.serializeResponseError,
        );
        expect(result.value == null, true);
      },
    );

    test('getAvailableCurrencies fails for any other reason', () async {
      final client = MockHTTP();
      final instance = ChangeNowAPI(http: client);

      when(
        client.get(
          url: buildV2Uri('/exchange/currencies', {'flow': 'standard'}),
          headers: changeNowHeaders(testApiKey),
          proxyInfo: null,
        ),
      ).thenAnswer((_) async => Response(utf8.encode(''), 400));

      final result = await instance.getAvailableCurrencies(apiKey: testApiKey);

      expect(result.exception!.type, ExchangeExceptionType.generic);
      expect(result.value == null, true);
    });
  });

  group('getMinimalExchangeAmount', () {
    test('getMinimalExchangeAmount succeeds', () async {
      final client = MockHTTP();
      final instance = ChangeNowAPI(http: client);

      when(
        client.get(
          url: buildV2Uri('/exchange/min-amount', {
            'fromCurrency': 'xmr',
            'toCurrency': 'btc',
            'flow': 'standard',
          }),
          headers: changeNowHeaders('testAPIKEY'),
          proxyInfo: null,
        ),
      ).thenAnswer(
        (_) async => Response(utf8.encode('{"minAmount": 42}'), 200),
      );

      final result = await instance.getMinimalExchangeAmount(
        fromCurrency: 'xmr',
        toCurrency: 'btc',
        apiKey: 'testAPIKEY',
      );

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value, Decimal.fromInt(42));
    });

    test(
      'getMinimalExchangeAmount fails with ChangeNowExceptionType.serializeResponseError',
      () async {
        final client = MockHTTP();
        final instance = ChangeNowAPI(http: client);

        when(
          client.get(
            url: buildV2Uri('/exchange/min-amount', {
              'fromCurrency': 'xmr',
              'toCurrency': 'btc',
              'flow': 'standard',
            }),
            headers: changeNowHeaders('testAPIKEY'),
            proxyInfo: null,
          ),
        ).thenAnswer((_) async => Response(utf8.encode('{"error": 42}'), 200));

        final result = await instance.getMinimalExchangeAmount(
          fromCurrency: 'xmr',
          toCurrency: 'btc',
          apiKey: 'testAPIKEY',
        );

        expect(
          result.exception!.type,
          ExchangeExceptionType.serializeResponseError,
        );
        expect(result.value == null, true);
      },
    );

    test('getMinimalExchangeAmount fails for any other reason', () async {
      final client = MockHTTP();
      final instance = ChangeNowAPI(http: client);

      when(
        client.get(
          url: buildV2Uri('/exchange/min-amount', {
            'fromCurrency': 'xmr',
            'toCurrency': 'btc',
            'flow': 'standard',
          }),
          headers: changeNowHeaders('testAPIKEY'),
          proxyInfo: null,
        ),
      ).thenAnswer((_) async => Response(utf8.encode(''), 400));

      final result = await instance.getMinimalExchangeAmount(
        fromCurrency: 'xmr',
        toCurrency: 'btc',
        apiKey: 'testAPIKEY',
      );

      expect(result.exception!.type, ExchangeExceptionType.generic);
      expect(result.value == null, true);
    });
  });

  group('getEstimatedExchangeAmount', () {
    test('getEstimatedExchangeAmount succeeds', () async {
      final client = MockHTTP();
      final instance = ChangeNowAPI(http: client);

      when(
        client.get(
          url: buildV2Uri('/exchange/estimated-amount', {
            'fromCurrency': 'xmr',
            'toCurrency': 'btc',
            'fromAmount': '42',
            'flow': 'standard',
            'type': 'direct',
          }),
          headers: changeNowHeaders('testAPIKEY'),
          proxyInfo: null,
        ),
      ).thenAnswer(
        (_) async => Response(
          utf8.encode(
            jsonEncode({
              'fromCurrency': 'xmr',
              'fromNetwork': 'xmr',
              'toCurrency': 'btc',
              'toNetwork': 'btc',
              'flow': 'standard',
              'type': 'direct',
              'validUntil': '2019-09-09T14:01:04.921Z',
              'transactionSpeedForecast': '10-60',
              'warningMessage': 'Rates may shift while the order is pending.',
              'depositFee': '0',
              'withdrawalFee': '0.0001',
              'fromAmount': '42',
              'toAmount': '58.4142873',
            }),
          ),
          200,
        ),
      );

      final result = await instance.getEstimatedExchangeAmount(
        fromCurrency: 'xmr',
        toCurrency: 'btc',
        fromAmount: Decimal.fromInt(42),
        apiKey: 'testAPIKEY',
      );

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value, isA<Estimate>());
    });

    test(
      'getEstimatedExchangeAmount fails with ChangeNowExceptionType.serializeResponseError',
      () async {
        final client = MockHTTP();
        final instance = ChangeNowAPI(http: client);

        when(
          client.get(
            url: buildV2Uri('/exchange/estimated-amount', {
              'fromCurrency': 'xmr',
              'toCurrency': 'btc',
              'fromAmount': '42',
              'flow': 'standard',
              'type': 'direct',
            }),
            headers: changeNowHeaders('testAPIKEY'),
            proxyInfo: null,
          ),
        ).thenAnswer((_) async => Response(utf8.encode('{"error": 42}'), 200));

        final result = await instance.getEstimatedExchangeAmount(
          fromCurrency: 'xmr',
          toCurrency: 'btc',
          fromAmount: Decimal.fromInt(42),
          apiKey: 'testAPIKEY',
        );

        expect(
          result.exception!.type,
          ExchangeExceptionType.serializeResponseError,
        );
        expect(result.value == null, true);
      },
    );

    test('getEstimatedExchangeAmount fails for any other reason', () async {
      final client = MockHTTP();
      final instance = ChangeNowAPI(http: client);

      when(
        client.get(
          url: buildV2Uri('/exchange/estimated-amount', {
            'fromCurrency': 'xmr',
            'toCurrency': 'btc',
            'fromAmount': '42',
            'flow': 'standard',
            'type': 'direct',
          }),
          headers: changeNowHeaders('testAPIKEY'),
          proxyInfo: null,
        ),
      ).thenAnswer((_) async => Response(utf8.encode(''), 400));

      final result = await instance.getEstimatedExchangeAmount(
        fromCurrency: 'xmr',
        toCurrency: 'btc',
        fromAmount: Decimal.fromInt(42),
        apiKey: 'testAPIKEY',
      );

      expect(result.exception!.type, ExchangeExceptionType.generic);
      expect(result.value == null, true);
    });
  });

  group('createExchangeTransaction standard flow', () {
    test('createExchangeTransaction succeeds', () async {
      final client = MockHTTP();
      final instance = ChangeNowAPI(http: client);

      when(
        client.post(
          url: buildV2Uri('/exchange'),
          headers: changeNowHeaders('testAPIKEY'),
          proxyInfo: null,
          body: buildCreateExchangeBody(
            fromCurrency: 'xmr',
            fromNetwork: 'xmr',
            toCurrency: 'btc',
            toNetwork: '',
            fromAmount: '0.3',
            toAmount: '',
            flow: 'standard',
            type: 'direct',
            address: 'bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5',
            refundAddress:
                '888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H',
          ),
          encoding: null,
        ),
      ).thenAnswer(
        (_) async => Response(
          utf8.encode(jsonEncode(createStandardTransactionResponse)),
          200,
        ),
      );

      final result = await instance.createExchangeTransaction(
        fromCurrency: 'xmr',
        toCurrency: 'btc',
        address: 'bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5',
        fromAmount: Decimal.parse('0.3'),
        refundAddress:
            '888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H',
        apiKey: 'testAPIKEY',
        fromNetwork: 'xmr',
        toNetwork: '',
        rateId: '',
      );

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value, isA<CNExchangeTransaction>());
    });

    test(
      'createExchangeTransaction fails with ChangeNowExceptionType.serializeResponseError',
      () async {
        final client = MockHTTP();
        final instance = ChangeNowAPI(http: client);

        when(
          client.post(
            url: buildV2Uri('/exchange'),
            headers: changeNowHeaders('testAPIKEY'),
            proxyInfo: null,
            body: buildCreateExchangeBody(
              fromCurrency: 'xmr',
              fromNetwork: 'xmr',
              toCurrency: 'btc',
              toNetwork: '',
              fromAmount: '0.3',
              toAmount: '',
              flow: 'standard',
              type: 'direct',
              address: 'bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5',
              refundAddress:
                  '888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H',
            ),
            encoding: null,
          ),
        ).thenAnswer((_) async => Response(utf8.encode('{"error": 42}'), 200));

        final result = await instance.createExchangeTransaction(
          fromCurrency: 'xmr',
          toCurrency: 'btc',
          address: 'bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5',
          fromAmount: Decimal.parse('0.3'),
          refundAddress:
              '888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H',
          apiKey: 'testAPIKEY',
          fromNetwork: 'xmr',
          toNetwork: '',
          rateId: '',
        );

        expect(
          result.exception!.type,
          ExchangeExceptionType.serializeResponseError,
        );
        expect(result.value == null, true);
      },
    );

    test('createExchangeTransaction fails for any other reason', () async {
      final client = MockHTTP();
      final instance = ChangeNowAPI(http: client);

      when(
        client.post(
          url: buildV2Uri('/exchange'),
          headers: changeNowHeaders('testAPIKEY'),
          proxyInfo: null,
          body: buildCreateExchangeBody(
            fromCurrency: 'xmr',
            fromNetwork: 'xmr',
            toCurrency: 'btc',
            toNetwork: '',
            fromAmount: '0.3',
            toAmount: '',
            flow: 'standard',
            type: 'direct',
            address: 'bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5',
            refundAddress:
                '888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H',
          ),
          encoding: null,
        ),
      ).thenAnswer((_) async => Response(utf8.encode(''), 400));

      final result = await instance.createExchangeTransaction(
        fromCurrency: 'xmr',
        toCurrency: 'btc',
        address: 'bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5',
        fromAmount: Decimal.parse('0.3'),
        refundAddress:
            '888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H',
        apiKey: 'testAPIKEY',
        fromNetwork: 'xmr',
        toNetwork: '',
        rateId: '',
      );

      expect(result.exception!.type, ExchangeExceptionType.generic);
      expect(result.value == null, true);
    });
  });

  group('createExchangeTransaction fixed-rate flow', () {
    test('createExchangeTransaction succeeds', () async {
      final client = MockHTTP();
      final instance = ChangeNowAPI(http: client);

      when(
        client.post(
          url: buildV2Uri('/exchange'),
          headers: changeNowHeaders('testAPIKEY'),
          proxyInfo: null,
          body: buildCreateExchangeBody(
            fromCurrency: 'btc',
            fromNetwork: 'xmr',
            toCurrency: 'eth',
            toNetwork: '',
            fromAmount: '0.3',
            toAmount: '',
            flow: 'fixed-rate',
            type: 'direct',
            address: '0x57f31ad4b64095347F87eDB1675566DAfF5EC886',
          ),
          encoding: null,
        ),
      ).thenAnswer(
        (_) async => Response(
          utf8.encode(
            jsonEncode({
              'fromAmount': '0.3',
              'toAmount': '62.9737711',
              'flow': 'fixed-rate',
              'type': 'direct',
              'payinAddress': '33eFX2jfeWbXMSmRe9ewUUTrmSVSxZi5cj',
              'payoutAddress': '0x57f31ad4b64095347F87eDB1675566DAfF5EC886',
              'payoutExtraId': '',
              'fromCurrency': 'btc',
              'toCurrency': 'eth',
              'refundAddress': '',
              'refundExtraId': '',
              'fromNetwork': 'xmr',
              'toNetwork': '',
              'validUntil': '2019-09-09T14:01:04.921Z',
              'id': 'a5c73e2603f40d',
            }),
          ),
          200,
        ),
      );

      final result = await instance.createExchangeTransaction(
        fromCurrency: 'btc',
        toCurrency: 'eth',
        address: '0x57f31ad4b64095347F87eDB1675566DAfF5EC886',
        fromAmount: Decimal.parse('0.3'),
        refundAddress: '',
        apiKey: 'testAPIKEY',
        rateId: '',
        flow: CNFlow.fixedRate,
        type: CNExchangeType.direct,
        fromNetwork: 'xmr',
        toNetwork: '',
      );

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value, isA<CNExchangeTransaction>());
    });

    test(
      'createExchangeTransaction fails with ChangeNowExceptionType.serializeResponseError',
      () async {
        final client = MockHTTP();
        final instance = ChangeNowAPI(http: client);

        when(
          client.post(
            url: buildV2Uri('/exchange'),
            headers: changeNowHeaders('testAPIKEY'),
            proxyInfo: null,
            body: buildCreateExchangeBody(
              fromCurrency: 'btc',
              fromNetwork: 'xmr',
              toCurrency: 'eth',
              toNetwork: '',
              fromAmount: '0.3',
              toAmount: '',
              flow: 'fixed-rate',
              type: 'direct',
              address: '0x57f31ad4b64095347F87eDB1675566DAfF5EC886',
            ),
            encoding: null,
          ),
        ).thenAnswer(
          (_) async => Response(
            utf8.encode('{"id": "a5c73e2603f40d", "amount": 62.9737711}'),
            200,
          ),
        );

        final result = await instance.createExchangeTransaction(
          fromCurrency: 'btc',
          toCurrency: 'eth',
          address: '0x57f31ad4b64095347F87eDB1675566DAfF5EC886',
          fromAmount: Decimal.parse('0.3'),
          refundAddress: '',
          apiKey: 'testAPIKEY',
          rateId: '',
          flow: CNFlow.fixedRate,
          type: CNExchangeType.direct,
          fromNetwork: 'xmr',
          toNetwork: '',
        );

        expect(
          result.exception!.type,
          ExchangeExceptionType.serializeResponseError,
        );
        expect(result.value == null, true);
      },
    );

    test('createExchangeTransaction fails for any other reason', () async {
      final client = MockHTTP();
      final instance = ChangeNowAPI(http: client);

      when(
        client.post(
          url: buildV2Uri('/exchange'),
          headers: changeNowHeaders('testAPIKEY'),
          proxyInfo: null,
          body: buildCreateExchangeBody(
            fromCurrency: 'xmr',
            fromNetwork: 'xmr',
            toCurrency: 'btc',
            toNetwork: '',
            fromAmount: '0.3',
            toAmount: '',
            flow: 'fixed-rate',
            type: 'direct',
            address: 'bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5',
            refundAddress:
                '888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H',
          ),
          encoding: null,
        ),
      ).thenAnswer((_) async => Response(utf8.encode(''), 400));

      final result = await instance.createExchangeTransaction(
        fromCurrency: 'xmr',
        toCurrency: 'btc',
        address: 'bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5',
        fromAmount: Decimal.parse('0.3'),
        refundAddress:
            '888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H',
        apiKey: 'testAPIKEY',
        rateId: '',
        flow: CNFlow.fixedRate,
        type: CNExchangeType.direct,
        fromNetwork: 'xmr',
        toNetwork: '',
      );

      expect(result.exception!.type, ExchangeExceptionType.generic);
      expect(result.value == null, true);
    });
  });

  group('getTransactionStatus', () {
    test('getTransactionStatus succeeds', () async {
      final client = MockHTTP();
      final instance = ChangeNowAPI(http: client);

      when(
        client.get(
          url: buildV2Uri('/exchange/by-id', {
            'id': '47F87eDB1675566DAfF5EC886',
          }),
          headers: changeNowHeaders('testAPIKEY'),
          proxyInfo: null,
        ),
      ).thenAnswer(
        (_) async => Response(
          utf8.encode(
            jsonEncode({
              'status': 'waiting',
              'id': '50727663e5d9a4',
              'actionsAvailable': false,
              'fromCurrency': 'btc',
              'fromNetwork': 'btc',
              'toCurrency': 'eth',
              'toNetwork': 'eth',
              'expectedAmountFrom': '1',
              'expectedAmountTo': '52.31667',
              'payinAddress': '32Ge2ci26rj1sRGw2NjiQa9L7Xvxtgzhrj',
              'payoutAddress': '0x57f31ad4b64095347F87eDB1675566DAfF5EC886',
              'createdAt': '2019-08-22T14:47:49.943Z',
              'updatedAt': '2019-08-22T14:47:49.943Z',
              'fromLegacyTicker': 'btc',
              'toLegacyTicker': 'eth',
            }),
          ),
          200,
        ),
      );

      final result = await instance.getTransactionStatus(
        id: '47F87eDB1675566DAfF5EC886',
        apiKey: 'testAPIKEY',
      );

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value, isA<CNExchangeTransactionStatus>());
    });

    test(
      'getTransactionStatus fails with ChangeNowExceptionType.serializeResponseError',
      () async {
        final client = MockHTTP();
        final instance = ChangeNowAPI(http: client);

        when(
          client.get(
            url: buildV2Uri('/exchange/by-id', {
              'id': '47F87eDB1675566DAfF5EC886',
            }),
            headers: changeNowHeaders('testAPIKEY'),
            proxyInfo: null,
          ),
        ).thenAnswer((_) async => Response(utf8.encode('{"error": 42}'), 200));

        final result = await instance.getTransactionStatus(
          id: '47F87eDB1675566DAfF5EC886',
          apiKey: 'testAPIKEY',
        );

        expect(
          result.exception!.type,
          ExchangeExceptionType.serializeResponseError,
        );
        expect(result.value == null, true);
      },
    );

    test('getTransactionStatus fails for any other reason', () async {
      final client = MockHTTP();
      final instance = ChangeNowAPI(http: client);

      when(
        client.get(
          url: buildV2Uri('/exchange/by-id', {
            'id': '47F87eDB1675566DAfF5EC886',
          }),
          headers: changeNowHeaders('testAPIKEY'),
          proxyInfo: null,
        ),
      ).thenAnswer((_) async => Response(utf8.encode(''), 400));

      final result = await instance.getTransactionStatus(
        id: '47F87eDB1675566DAfF5EC886',
        apiKey: 'testAPIKEY',
      );

      expect(result.exception!.type, ExchangeExceptionType.generic);
      expect(result.value == null, true);
    });
  });
}
