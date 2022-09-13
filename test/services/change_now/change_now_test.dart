import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/exchange/change_now/available_floating_rate_pair.dart';
import 'package:stackwallet/models/exchange/change_now/change_now_response.dart';
import 'package:stackwallet/models/exchange/change_now/estimated_exchange_amount.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:stackwallet/services/change_now/change_now.dart';

import 'change_now_sample_data.dart';
import 'change_now_test.mocks.dart';

@GenerateMocks([Client])
void main() {
  group("getAvailableCurrencies", () {
    test("getAvailableCurrencies succeeds without options", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse("https://api.ChangeNow.io/v1/currencies"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async =>
          Response(jsonEncode(availableCurrenciesJSON), 200));

      final result = await ChangeNow.instance.getAvailableCurrencies();

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value!.length, 538);
    });

    test("getAvailableCurrencies succeeds with active option", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse("https://api.ChangeNow.io/v1/currencies?active=true"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async =>
          Response(jsonEncode(availableCurrenciesJSONActive), 200));

      final result =
          await ChangeNow.instance.getAvailableCurrencies(active: true);

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value!.length, 531);
    });

    test("getAvailableCurrencies succeeds with fixedRate option", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse("https://api.ChangeNow.io/v1/currencies?fixedRate=true"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async =>
          Response(jsonEncode(availableCurrenciesJSONFixedRate), 200));

      final result =
          await ChangeNow.instance.getAvailableCurrencies(fixedRate: true);

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value!.length, 410);
    });

    test("getAvailableCurrencies succeeds with fixedRate and active options",
        () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/currencies?fixedRate=true&active=true"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async =>
          Response(jsonEncode(availableCurrenciesJSONActiveFixedRate), 200));

      final result = await ChangeNow.instance
          .getAvailableCurrencies(active: true, fixedRate: true);

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value!.length, 410);
    });

    test(
        "getAvailableCurrencies fails with ChangeNowExceptionType.serializeResponseError",
        () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse("https://api.ChangeNow.io/v1/currencies"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async =>
          Response('{"some unexpected": "but valid json data"}', 200));

      final result = await ChangeNow.instance.getAvailableCurrencies();

      expect(result.exception!.type,
          ChangeNowExceptionType.serializeResponseError);
      expect(result.value == null, true);
    });

    test("getAvailableCurrencies fails for any other reason", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse("https://api.ChangeNow.io/v1/currencies"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async => Response("", 400));

      final result = await ChangeNow.instance.getAvailableCurrencies();

      expect(result.exception!.type, ChangeNowExceptionType.generic);
      expect(result.value == null, true);
    });
  });
  //
  // group("getPairedCurrencies", () {
  //   test("getPairedCurrencies succeeds without fixedRate option", () async {
  //     final client = MockClient();
  //     ChangeNow.instance.client = client;
  //
  //     when(client.get(
  //       Uri.parse("https://api.ChangeNow.io/v1/currencies-to/XMR"),
  //       headers: {'Content-Type': 'application/json'},
  //     )).thenAnswer((realInvocation) async =>
  //         Response(jsonEncode(getPairedCurrenciesJSON), 200));
  //
  //     final result =
  //         await ChangeNow.instance.getPairedCurrencies(ticker: "XMR");
  //
  //     expect(result.exception, null);
  //     expect(result.value == null, false);
  //     expect(result.value!.length, 537);
  //   });
  //
  //   test("getPairedCurrencies succeeds with fixedRate option", () async {
  //     final client = MockClient();
  //     ChangeNow.instance.client = client;
  //
  //     when(client.get(
  //       Uri.parse(
  //           "https://api.ChangeNow.io/v1/currencies-to/XMR?fixedRate=true"),
  //       headers: {'Content-Type': 'application/json'},
  //     )).thenAnswer((realInvocation) async =>
  //         Response(jsonEncode(getPairedCurrenciesJSONFixedRate), 200));
  //
  //     final result = await ChangeNow.instance
  //         .getPairedCurrencies(ticker: "XMR", fixedRate: true);
  //
  //     expect(result.exception, null);
  //     expect(result.value == null, false);
  //     expect(result.value!.length, 410);
  //   });
  //
  //   test(
  //       "getPairedCurrencies fails with ChangeNowExceptionType.serializeResponseError A",
  //       () async {
  //     final client = MockClient();
  //     ChangeNow.instance.client = client;
  //
  //     when(client.get(
  //       Uri.parse("https://api.ChangeNow.io/v1/currencies-to/XMR"),
  //       headers: {'Content-Type': 'application/json'},
  //     )).thenAnswer((realInvocation) async =>
  //         Response('[{"some unexpected": "but valid json data"}]', 200));
  //
  //     final result =
  //         await ChangeNow.instance.getPairedCurrencies(ticker: "XMR");
  //
  //     expect(result.exception!.type,
  //         ChangeNowExceptionType.serializeResponseError);
  //     expect(result.value == null, true);
  //   });
  //
  //   test("getPairedCurrencies fails for any other reason", () async {
  //     final client = MockClient();
  //     ChangeNow.instance.client = client;
  //
  //     when(client.get(
  //       Uri.parse("https://api.ChangeNow.io/v1/currencies"),
  //       headers: {'Content-Type': 'application/json'},
  //     )).thenAnswer((realInvocation) async => Response("", 400));
  //
  //     final result = await ChangeNow.instance
  //         .getPairedCurrencies(ticker: "XMR", fixedRate: true);
  //
  //     expect(result.exception!.type, ChangeNowExceptionType.generic);
  //     expect(result.value == null, true);
  //   });
  // });

  group("getMinimalExchangeAmount", () {
    test("getMinimalExchangeAmount succeeds", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/min-amount/xmr_btc?api_key=testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer(
          (realInvocation) async => Response('{"minAmount": 42}', 200));

      final result = await ChangeNow.instance.getMinimalExchangeAmount(
        fromTicker: "xmr",
        toTicker: "btc",
        apiKey: "testAPIKEY",
      );

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value, Decimal.fromInt(42));
    });

    test(
        "getMinimalExchangeAmount fails with ChangeNowExceptionType.serializeResponseError",
        () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/min-amount/xmr_btc?api_key=testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async => Response('{"error": 42}', 200));

      final result = await ChangeNow.instance.getMinimalExchangeAmount(
        fromTicker: "xmr",
        toTicker: "btc",
        apiKey: "testAPIKEY",
      );

      expect(result.exception!.type,
          ChangeNowExceptionType.serializeResponseError);
      expect(result.value == null, true);
    });

    test("getMinimalExchangeAmount fails for any other reason", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/min-amount/xmr_btc?api_key=testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async => Response('', 400));

      final result = await ChangeNow.instance.getMinimalExchangeAmount(
        fromTicker: "xmr",
        toTicker: "btc",
        apiKey: "testAPIKEY",
      );

      expect(result.exception!.type, ChangeNowExceptionType.generic);
      expect(result.value == null, true);
    });
  });

  group("getEstimatedExchangeAmount", () {
    test("getEstimatedExchangeAmount succeeds", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/exchange-amount/42/xmr_btc?api_key=testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async => Response(
          '{"estimatedAmount": 58.4142873, "transactionSpeedForecast": "10-60", "warningMessage": null}',
          200));

      final result = await ChangeNow.instance.getEstimatedExchangeAmount(
        fromTicker: "xmr",
        toTicker: "btc",
        fromAmount: Decimal.fromInt(42),
        apiKey: "testAPIKEY",
      );

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value, isA<EstimatedExchangeAmount>());
    });

    test(
        "getEstimatedExchangeAmount fails with ChangeNowExceptionType.serializeResponseError",
        () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/exchange-amount/42/xmr_btc?api_key=testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async => Response('{"error": 42}', 200));

      final result = await ChangeNow.instance.getEstimatedExchangeAmount(
        fromTicker: "xmr",
        toTicker: "btc",
        fromAmount: Decimal.fromInt(42),
        apiKey: "testAPIKEY",
      );

      expect(result.exception!.type,
          ChangeNowExceptionType.serializeResponseError);
      expect(result.value == null, true);
    });

    test("getEstimatedExchangeAmount fails for any other reason", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/exchange-amount/42/xmr_btc?api_key=testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async => Response('', 400));

      final result = await ChangeNow.instance.getEstimatedExchangeAmount(
        fromTicker: "xmr",
        toTicker: "btc",
        fromAmount: Decimal.fromInt(42),
        apiKey: "testAPIKEY",
      );

      expect(result.exception!.type, ChangeNowExceptionType.generic);
      expect(result.value == null, true);
    });
  });

  // group("getEstimatedFixedRateExchangeAmount", () {
  //   test("getEstimatedFixedRateExchangeAmount succeeds", () async {
  //     final client = MockClient();
  //     ChangeNow.instance.client = client;
  //
  //     when(client.get(
  //       Uri.parse(
  //           "https://api.ChangeNow.io/v1/exchange-amount/fixed-rate/10/xmr_btc?api_key=testAPIKEY&useRateId=true"),
  //       headers: {'Content-Type': 'application/json'},
  //     )).thenAnswer((realInvocation) async =>
  //         Response(jsonEncode(estFixedRateExchangeAmountJSON), 200));
  //
  //     final result =
  //         await ChangeNow.instance.getEstimatedFixedRateExchangeAmount(
  //       fromTicker: "xmr",
  //       toTicker: "btc",
  //       fromAmount: Decimal.fromInt(10),
  //       apiKey: "testAPIKEY",
  //     );
  //
  //     expect(result.exception, null);
  //     expect(result.value == null, false);
  //     expect(result.value.toString(),
  //         'EstimatedExchangeAmount: {estimatedAmount: 0.07271053, transactionSpeedForecast: 10-60, warningMessage: null, rateId: 1t2W5KBPqhycSJVYpaNZzYWLfMr0kSFe, networkFee: 0.00002408}');
  //   });
  //
  //   test(
  //       "getEstimatedFixedRateExchangeAmount fails with ChangeNowExceptionType.serializeResponseError",
  //       () async {
  //     final client = MockClient();
  //     ChangeNow.instance.client = client;
  //
  //     when(client.get(
  //       Uri.parse(
  //           "https://api.ChangeNow.io/v1/exchange-amount/fixed-rate/10/xmr_btc?api_key=testAPIKEY&useRateId=true"),
  //       headers: {'Content-Type': 'application/json'},
  //     )).thenAnswer((realInvocation) async => Response('{"error": 42}', 200));
  //
  //     final result =
  //         await ChangeNow.instance.getEstimatedFixedRateExchangeAmount(
  //       fromTicker: "xmr",
  //       toTicker: "btc",
  //       fromAmount: Decimal.fromInt(10),
  //       apiKey: "testAPIKEY",
  //     );
  //
  //     expect(result.exception!.type,
  //         ChangeNowExceptionType.serializeResponseError);
  //     expect(result.value == null, true);
  //   });
  //
  //   test("getEstimatedFixedRateExchangeAmount fails for any other reason",
  //       () async {
  //     final client = MockClient();
  //     ChangeNow.instance.client = client;
  //
  //     when(client.get(
  //       Uri.parse(
  //           "https://api.ChangeNow.io/v1/exchange-amount/fixed-rate/10/xmr_btc?api_key=testAPIKEY&useRateId=true"),
  //       headers: {'Content-Type': 'application/json'},
  //     )).thenAnswer((realInvocation) async => Response('', 400));
  //
  //     final result =
  //         await ChangeNow.instance.getEstimatedFixedRateExchangeAmount(
  //       fromTicker: "xmr",
  //       toTicker: "btc",
  //       fromAmount: Decimal.fromInt(10),
  //       apiKey: "testAPIKEY",
  //     );
  //
  //     expect(result.exception!.type, ChangeNowExceptionType.generic);
  //     expect(result.value == null, true);
  //   });
  // });

  group("getAvailableFixedRateMarkets", () {
    test("getAvailableFixedRateMarkets succeeds", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/market-info/fixed-rate/testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async =>
          Response(jsonEncode(fixedRateMarketsJSON), 200));

      final result = await ChangeNow.instance.getAvailableFixedRateMarkets(
        apiKey: "testAPIKEY",
      );

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value!.length, 237);
    });

    test(
        "getAvailableFixedRateMarkets fails with ChangeNowExceptionType.serializeResponseError",
        () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/market-info/fixed-rate/testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async => Response('{"error": 42}', 200));

      final result = await ChangeNow.instance.getAvailableFixedRateMarkets(
        apiKey: "testAPIKEY",
      );

      expect(result.exception!.type,
          ChangeNowExceptionType.serializeResponseError);
      expect(result.value == null, true);
    });

    test("getAvailableFixedRateMarkets fails for any other reason", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/market-info/fixed-rate/testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async => Response('', 400));

      final result = await ChangeNow.instance.getAvailableFixedRateMarkets(
        apiKey: "testAPIKEY",
      );

      expect(result.exception!.type, ChangeNowExceptionType.generic);
      expect(result.value == null, true);
    });
  });

  group("createStandardExchangeTransaction", () {
    test("createStandardExchangeTransaction succeeds", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.post(
        Uri.parse("https://api.ChangeNow.io/v1/transactions/testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
        body:
            '{"from":"xmr","to":"btc","address":"bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5","amount":"0.3","flow":"standard","extraId":"","userId":"","contactEmail":"","refundAddress":"888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H","refundExtraId":""}',
        encoding: null,
      )).thenAnswer((realInvocation) async =>
          Response(jsonEncode(createStandardTransactionResponse), 200));

      final result = await ChangeNow.instance.createStandardExchangeTransaction(
        fromTicker: "xmr",
        toTicker: "btc",
        receivingAddress: "bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5",
        amount: Decimal.parse("0.3"),
        refundAddress:
            "888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H",
        apiKey: "testAPIKEY",
      );

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value, isA<ExchangeTransaction>());
    });

    test(
        "createStandardExchangeTransaction fails with ChangeNowExceptionType.serializeResponseError",
        () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.post(
        Uri.parse("https://api.ChangeNow.io/v1/transactions/testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
        body:
            '{"from":"xmr","to":"btc","address":"bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5","amount":"0.3","flow":"standard","extraId":"","userId":"","contactEmail":"","refundAddress":"888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H","refundExtraId":""}',
        encoding: null,
      )).thenAnswer((realInvocation) async => Response('{"error": 42}', 200));

      final result = await ChangeNow.instance.createStandardExchangeTransaction(
        fromTicker: "xmr",
        toTicker: "btc",
        receivingAddress: "bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5",
        amount: Decimal.parse("0.3"),
        refundAddress:
            "888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H",
        apiKey: "testAPIKEY",
      );

      expect(result.exception!.type,
          ChangeNowExceptionType.serializeResponseError);
      expect(result.value == null, true);
    });

    test("createStandardExchangeTransaction fails for any other reason",
        () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.post(
        Uri.parse("https://api.ChangeNow.io/v1/transactions/testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
        body:
            '{"from":"xmr","to":"btc","address":"bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5","amount":"0.3","flow":"standard","extraId":"","userId":"","contactEmail":"","refundAddress":"888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H","refundExtraId":""}',
        encoding: null,
      )).thenAnswer((realInvocation) async => Response('', 400));

      final result = await ChangeNow.instance.createStandardExchangeTransaction(
        fromTicker: "xmr",
        toTicker: "btc",
        receivingAddress: "bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5",
        amount: Decimal.parse("0.3"),
        refundAddress:
            "888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H",
        apiKey: "testAPIKEY",
      );

      expect(result.exception!.type, ChangeNowExceptionType.generic);
      expect(result.value == null, true);
    });
  });

  group("createFixedRateExchangeTransaction", () {
    test("createFixedRateExchangeTransaction succeeds", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.post(
        Uri.parse(
            "https://api.ChangeNow.io/v1/transactions/fixed-rate/testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
        body:
            '{"from":"btc","to":"eth","address":"0x57f31ad4b64095347F87eDB1675566DAfF5EC886","amount":"0.3","flow":"fixed-rate","extraId":"","userId":"","contactEmail":"","refundAddress":"","refundExtraId":"","rateId":""}',
        encoding: null,
      )).thenAnswer((realInvocation) async => Response(
          '{"payinAddress": "33eFX2jfeWbXMSmRe9ewUUTrmSVSxZi5cj", "payoutAddress": "0x57f31ad4b64095347F87eDB1675566DAfF5EC886","payoutExtraId": "", "fromCurrency": "btc", "toCurrency": "eth", "refundAddress": "","refundExtraId": "","validUntil": "2019-09-09T14:01:04.921Z","id": "a5c73e2603f40d","amount": 62.9737711}',
          200));

      final result =
          await ChangeNow.instance.createFixedRateExchangeTransaction(
        fromTicker: "btc",
        toTicker: "eth",
        receivingAddress: "0x57f31ad4b64095347F87eDB1675566DAfF5EC886",
        amount: Decimal.parse("0.3"),
        refundAddress: "",
        apiKey: "testAPIKEY",
        rateId: '',
      );

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value, isA<ExchangeTransaction>());
    });

    test(
        "createFixedRateExchangeTransaction fails with ChangeNowExceptionType.serializeResponseError",
        () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.post(
        Uri.parse(
            "https://api.ChangeNow.io/v1/transactions/fixed-rate/testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
        body:
            '{"from":"btc","to":"eth","address":"0x57f31ad4b64095347F87eDB1675566DAfF5EC886","amount":"0.3","flow":"fixed-rate","extraId":"","userId":"","contactEmail":"","refundAddress":"","refundExtraId":"","rateId":""}',
        encoding: null,
      )).thenAnswer((realInvocation) async =>
          Response('{"id": "a5c73e2603f40d","amount": 62.9737711}', 200));

      final result =
          await ChangeNow.instance.createFixedRateExchangeTransaction(
        fromTicker: "btc",
        toTicker: "eth",
        receivingAddress: "0x57f31ad4b64095347F87eDB1675566DAfF5EC886",
        amount: Decimal.parse("0.3"),
        refundAddress: "",
        apiKey: "testAPIKEY",
        rateId: '',
      );

      expect(result.exception!.type,
          ChangeNowExceptionType.serializeResponseError);
      expect(result.value == null, true);
    });

    test("createFixedRateExchangeTransaction fails for any other reason",
        () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.post(
        Uri.parse(
            "https://api.ChangeNow.io/v1/transactions/fixed-rate/testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
        body:
            '{"from": "btc","to": "eth","address": "0x57f31ad4b64095347F87eDB1675566DAfF5EC886", "amount": "1.12345","extraId": "", "userId": "","contactEmail": "","refundAddress": "", "refundExtraId": "", "rateId": "" }',
        encoding: null,
      )).thenAnswer((realInvocation) async => Response('', 400));

      final result =
          await ChangeNow.instance.createFixedRateExchangeTransaction(
        fromTicker: "xmr",
        toTicker: "btc",
        receivingAddress: "bc1qu58svs9983e2vuyqh7gq7ratf8k5qehz5k0cn5",
        amount: Decimal.parse("0.3"),
        refundAddress:
            "888tNkZrPN6JsEgekjMnABU4TBzc2Dt29EPAvkRxbANsAnjyPbb3iQ1YBRk1UXcdRsiKc9dhwMVgN5S9cQUiyoogDavup3H",
        apiKey: "testAPIKEY",
        rateId: '',
      );

      expect(result.exception!.type, ChangeNowExceptionType.generic);
      expect(result.value == null, true);
    });
  });

  group("getTransactionStatus", () {
    test("getTransactionStatus succeeds", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/transactions/47F87eDB1675566DAfF5EC886/testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async => Response(
          '{"status": "waiting", "payinAddress": "32Ge2ci26rj1sRGw2NjiQa9L7Xvxtgzhrj", "payoutAddress": "0x57f31ad4b64095347F87eDB1675566DAfF5EC886", "fromCurrency": "btc", "toCurrency": "eth", "id": "50727663e5d9a4", "updatedAt": "2019-08-22T14:47:49.943Z", "expectedSendAmount": 1, "expectedReceiveAmount": 52.31667, "createdAt": "2019-08-22T14:47:49.943Z", "isPartner": false}',
          200));

      final result = await ChangeNow.instance.getTransactionStatus(
        id: "47F87eDB1675566DAfF5EC886",
        apiKey: "testAPIKEY",
      );

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value, isA<ExchangeTransactionStatus>());
    });

    test(
        "getTransactionStatus fails with ChangeNowExceptionType.serializeResponseError",
        () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/transactions/47F87eDB1675566DAfF5EC886/testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async => Response('{"error": 42}', 200));

      final result = await ChangeNow.instance.getTransactionStatus(
        id: "47F87eDB1675566DAfF5EC886",
        apiKey: "testAPIKEY",
      );

      expect(result.exception!.type,
          ChangeNowExceptionType.serializeResponseError);
      expect(result.value == null, true);
    });

    test("getTransactionStatus fails for any other reason", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/transactions/47F87eDB1675566DAfF5EC886/testAPIKEY"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async => Response('', 400));

      final result = await ChangeNow.instance.getTransactionStatus(
        id: "47F87eDB1675566DAfF5EC886",
        apiKey: "testAPIKEY",
      );

      expect(result.exception!.type, ChangeNowExceptionType.generic);
      expect(result.value == null, true);
    });
  });

  group("getAvailableFloatingRatePairs", () {
    test("getAvailableFloatingRatePairs succeeds", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/market-info/available-pairs?includePartners=false"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async =>
          Response('["btc_xmr","btc_firo","btc_doge","eth_ltc"]', 200));

      final result = await ChangeNow.instance.getAvailableFloatingRatePairs();

      expect(result.exception, null);
      expect(result.value == null, false);
      expect(result.value, isA<List<AvailableFloatingRatePair>>());
    });

    test(
        "getAvailableFloatingRatePairs fails with ChangeNowExceptionType.serializeResponseError",
        () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/market-info/available-pairs?includePartners=false"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async => Response('{"error": 42}', 200));

      final result = await ChangeNow.instance.getAvailableFloatingRatePairs();

      expect(result.exception!.type,
          ChangeNowExceptionType.serializeResponseError);
      expect(result.value == null, true);
    });

    test("getAvailableFloatingRatePairs fails for any other reason", () async {
      final client = MockClient();
      ChangeNow.instance.client = client;

      when(client.get(
        Uri.parse(
            "https://api.ChangeNow.io/v1/market-info/available-pairs?includePartners=false"),
        headers: {'Content-Type': 'application/json'},
      )).thenAnswer((realInvocation) async => Response('', 400));

      final result = await ChangeNow.instance.getAvailableFloatingRatePairs();

      expect(result.exception!.type, ChangeNowExceptionType.generic);
      expect(result.value == null, true);
    });
  });
}
