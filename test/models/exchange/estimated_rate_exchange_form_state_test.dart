// import 'package:decimal/decimal.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
// import 'package:epicmobile/models/exchange/estimated_rate_exchange_form_state.dart';
// import 'package:epicmobile/models/exchange/response_objects/currency.dart';
// import 'package:epicmobile/models/exchange/response_objects/estimate.dart';
// import 'package:epicmobile/services/exchange/change_now/change_now_api.dart';
// import 'package:epicmobile/services/exchange/exchange_response.dart';
//
// import 'estimated_rate_exchange_form_state_test.mocks.dart';
//
void main() {}

// @GenerateMocks([ChangeNowAPI])
// void main() {
//   final currencyA = Currency(
//     ticker: "btc",
//     name: "Bitcoin",
//     image: "image.url",
//     hasExternalId: false,
//     isFiat: false,
//     featured: false,
//     isStable: true,
//     supportsFixedRate: true,
//     network: '',
//   );
//   final currencyB = Currency(
//     ticker: "xmr",
//     name: "Monero",
//     image: "image.url",
//     hasExternalId: false,
//     isFiat: false,
//     featured: false,
//     isStable: true,
//     supportsFixedRate: true,
//     network: '',
//   );
//   final currencyC = Currency(
//     ticker: "firo",
//     name: "Firo",
//     image: "image.url",
//     hasExternalId: false,
//     isFiat: false,
//     featured: false,
//     isStable: true,
//     supportsFixedRate: true,
//     network: '',
//   );
//
//   test("EstimatedRateExchangeFormState constructor", () async {
//     final state = EstimatedRateExchangeFormState();
//
//     expect(state.from, null);
//     expect(state.to, null);
//     expect(state.canExchange, false);
//     expect(state.rate, null);
//     expect(state.rateDisplayString, "N/A");
//     expect(state.fromAmountString, "");
//     expect(state.toAmountString, "");
//     expect(state.minimumSendWarning, "");
//   });
//
//   test("init EstimatedRateExchangeFormState", () async {
//     final state = EstimatedRateExchangeFormState();
//
//     await state.init(currencyA, currencyB);
//
//     expect(state.from, currencyA);
//     expect(state.to, currencyB);
//     expect(state.canExchange, false);
//     expect(state.rate, null);
//     expect(state.rateDisplayString, "N/A");
//     expect(state.fromAmountString, "");
//     expect(state.toAmountString, "");
//     expect(state.minimumSendWarning, "");
//   });
//
//   test("updateTo on fresh state", () async {
//     final state = EstimatedRateExchangeFormState();
//
//     await state.updateTo(currencyA, false);
//
//     expect(state.from, null);
//     expect(state.to, currencyA);
//     expect(state.canExchange, false);
//     expect(state.rate, null);
//     expect(state.rateDisplayString, "N/A");
//     expect(state.fromAmountString, "");
//     expect(state.toAmountString, "");
//     expect(state.minimumSendWarning, "");
//   });
//
//   test(
//       "updateTo after updateFrom where amounts are null and getMinimalExchangeAmount succeeds",
//       () async {
//     final cn = MockChangeNowAPI();
//
//     final state = EstimatedRateExchangeFormState();
//     state.cnTesting = cn;
//
//     when(cn.getMinimalExchangeAmount(fromTicker: "btc", toTicker: "xmr"))
//         .thenAnswer((_) async => ExchangeResponse(value: Decimal.fromInt(42)));
//
//     await state.updateFrom(currencyA, true);
//     await state.updateTo(currencyB, true);
//
//     expect(state.from, currencyA);
//     expect(state.to, currencyB);
//     expect(state.canExchange, false);
//     expect(state.rate, null);
//     expect(state.rateDisplayString, "N/A");
//     expect(state.fromAmountString, "");
//     expect(state.toAmountString, "");
//     expect(state.minimumSendWarning, "");
//
//     verify(cn.getMinimalExchangeAmount(fromTicker: "btc", toTicker: "xmr"))
//         .called(1);
//   });
//
//   test(
//       "updateTo after updateFrom where amounts are null and getMinimalExchangeAmount fails",
//       () async {
//     final cn = MockChangeNowAPI();
//
//     final state = EstimatedRateExchangeFormState();
//     state.cnTesting = cn;
//
//     when(cn.getMinimalExchangeAmount(fromTicker: "btc", toTicker: "xmr"))
//         .thenAnswer((_) async => ExchangeResponse());
//
//     await state.updateFrom(currencyA, true);
//     await state.updateTo(currencyB, true);
//
//     expect(state.from, currencyA);
//     expect(state.to, currencyB);
//     expect(state.canExchange, false);
//     expect(state.rate, null);
//     expect(state.rateDisplayString, "N/A");
//     expect(state.fromAmountString, "");
//     expect(state.toAmountString, "");
//     expect(state.minimumSendWarning, "");
//
//     verify(cn.getMinimalExchangeAmount(fromTicker: "btc", toTicker: "xmr"))
//         .called(1);
//   });
//
//   test(
//       "updateTo after updateFrom and setFromAmountAndCalculateToAmount where fromAmount is less than the minimum required exchange amount",
//       () async {
//     final cn = MockChangeNowAPI();
//
//     final state = EstimatedRateExchangeFormState();
//     state.cnTesting = cn;
//
//     when(cn.getMinimalExchangeAmount(fromTicker: "btc", toTicker: "xmr"))
//         .thenAnswer((_) async => ExchangeResponse(value: Decimal.fromInt(42)));
//
//     await state.updateFrom(currencyA, true);
//     await state.setFromAmountAndCalculateToAmount(Decimal.parse("10.10"), true);
//     await state.updateTo(currencyB, true);
//
//     expect(state.from, currencyA);
//     expect(state.to, currencyB);
//     expect(state.canExchange, false);
//     expect(state.rate, null);
//     expect(state.rateDisplayString, "N/A");
//     expect(state.fromAmountString, "10.10000000");
//     expect(state.toAmountString, "");
//     expect(state.minimumSendWarning, "Minimum amount 42 BTC");
//
//     verify(cn.getMinimalExchangeAmount(fromTicker: "btc", toTicker: "xmr"))
//         .called(1);
//   });
//
//   test(
//       "updateTo after updateFrom and setFromAmountAndCalculateToAmount where fromAmount is greater than the minimum required exchange amount",
//       () async {
//     final cn = MockChangeNowAPI();
//
//     final state = EstimatedRateExchangeFormState();
//     state.cnTesting = cn;
//
//     when(cn.getMinimalExchangeAmount(fromTicker: "btc", toTicker: "xmr"))
//         .thenAnswer((_) async => ExchangeResponse(value: Decimal.fromInt(42)));
//     when(cn.getEstimatedExchangeAmount(
//             fromTicker: "btc",
//             toTicker: "xmr",
//             fromAmount: Decimal.parse("110.10")))
//         .thenAnswer((_) async => ExchangeResponse(
//                 value: Estimate(
//               reversed: false,
//               fixedRate: false,
//               rateId: 'some rate id',
//               warningMessage: '',
//               estimatedAmount: Decimal.parse("302.002348"),
//             )));
//
//     await state.updateFrom(currencyA, true);
//     await state.setFromAmountAndCalculateToAmount(
//         Decimal.parse("110.10"), true);
//     await state.updateTo(currencyB, true);
//
//     expect(state.from, currencyA);
//     expect(state.to, currencyB);
//     expect(state.canExchange, true);
//     expect(state.rate, Decimal.parse("2.742982270663"));
//     expect(state.rateDisplayString, "1 BTC ~2.74298227 XMR");
//     expect(state.fromAmountString, "110.10000000");
//     expect(state.toAmountString, "302.00234800");
//     expect(state.minimumSendWarning, "");
//
//     verify(cn.getMinimalExchangeAmount(fromTicker: "btc", toTicker: "xmr"))
//         .called(1);
//     verify(cn.getEstimatedExchangeAmount(
//             fromTicker: "btc",
//             toTicker: "xmr",
//             fromAmount: Decimal.parse("110.10")))
//         .called(1);
//   });
// }
