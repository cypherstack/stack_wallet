import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:opencryptopay/opencryptopay.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/open_crypto_pay/open_crypto_pay_send_handler.dart';
import 'package:stackwallet/providers/ui/preview_tx_button_state_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import '../../sample_data/theme_json.dart';

// LNURL from the library's own sample data; decodes to
// https://api.dfx.swiss/v1/lnurlp/pl_beeddb41cd4b6d9e
const _lnurl =
    'LNURL1DP68GURN8GHJ7CTSDYHXGENC9EEHW6TNWVHHVVF0D3H82UNVWQHHQMZLVFJK2ERYV'
    'G6RZCMYX33RVEPEV5YEJ9WT';
const _qrLink = 'https://app.dfx.swiss/pl/?lightning=$_lnurl';
const _callbackUrl = 'https://api.dfx.swiss/v1/lnurlp/cb/pl_beeddb41cd4b6d9e';

const _btcAddress = 'bc1qzx3ug7j0e64207fe2m424hvxmvd496q8gdytt6';
const _erc20Recipient = '0x9C2242a0B71FD84661Fd4bC56b75c90Fac6d10FC';

const _hexHint =
    'Use this data to create a transaction and sign it. Send the signed '
    'transaction back as HEX via the endpoint '
    'https://api.dfx.swiss/v1/lnurlp/tx/plp_test. We check the transferred '
    'HEX and broadcast the transaction to the blockchain.';
const _hashHint =
    'Use this data to create a transaction, sign and broadcast it. Then '
    'send the transaction id back via the endpoint.';

Map<String, dynamic> _paymentInfoJson({required String quoteExpiration}) => {
  "id": "pl_test",
  "tag": "payRequest",
  "callback": _callbackUrl,
  "displayName": "Test Shop",
  "quote": {
    "id": "plq_test",
    "expiration": quoteExpiration,
    "payment": "plp_test",
  },
  "transferAmounts": [
    {
      "method": "Bitcoin",
      "minFee": 0,
      "assets": [
        {"asset": "BTC", "amount": "0.00001947"},
      ],
      "available": true,
    },
    {
      "method": "Ethereum",
      "minFee": 0,
      "assets": [
        {"asset": "USDT", "amount": "1.246858"},
      ],
      "available": true,
    },
  ],
};

Map<String, dynamic> _btcDetailsJson({required String hint}) => {
  "expiryDate": "2100-01-01T00:00:00.000Z",
  "blockchain": "Bitcoin",
  "uri": "bitcoin:$_btcAddress?amount=0.00001947&label=DFX Payment",
  "hint": hint,
};

Map<String, dynamic> _erc20DetailsJson() => {
  "expiryDate": "2100-01-01T00:00:00.000Z",
  "blockchain": "Ethereum",
  "uri":
      "ethereum:0xdac17f958d2ee523a2206206994597c13d831ec7@1/transfer"
      "?address=$_erc20Recipient&uint256=1246858",
  "hint": _hexHint,
};

String _futureExpiration() =>
    DateTime.now().toUtc().add(const Duration(days: 365)).toIso8601String();

String _pastExpiration() => "2000-01-01T00:00:00.000Z";

/// Mock the OpenCryptoPay requests flow plus the proof callback endpoint.
MockClient _mockOcpServer({
  required Map<String, dynamic> paymentInfo,
  Map<String, dynamic>? txDetails,
  int paymentInfoStatus = 200,
  int proofStatus = 200,
  void Function(Uri url)? onRequest,
}) {
  return MockClient((request) async {
    onRequest?.call(request.url);
    // Proof submissions go to the callback URL with /cb/ replaced by /tx/.
    if (request.url.path.contains('/tx/')) {
      return Response(
        proofStatus == 200 ? '{"status": "ok"}' : '{}',
        proofStatus,
      );
    }
    if (request.url.queryParameters.containsKey('method')) {
      return Response(jsonEncode(txDetails), 200);
    }
    return Response(jsonEncode(paymentInfo), paymentInfoStatus);
  });
}

class _FakeThemeService implements ThemeService {
  @override
  StackTheme? getTheme({required String themeId}) =>
      StackTheme.fromJson(json: lightThemeJsonMap);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Harness {
  late BuildContext context;
  late WidgetRef ref;
}

/// Pump a minimal app with the theme + providers the handler's UI needs and
/// capture a BuildContext/WidgetRef for driving the handler.
Future<_Harness> _pumpHarness(WidgetTester tester) async {
  final harness = _Harness();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pThemeService.overrideWithValue(_FakeThemeService()),
        pAmountFormatter.overrideWithProvider(
          (coin) => Provider<AmountFormatter>(
            (ref) => AmountFormatter(
              unit: AmountUnit.normal,
              locale: "en_US",
              coin: coin,
              maxDecimals: 18,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(json: lightThemeJsonMap),
            ),
          ],
        ),
        home: Material(
          child: Consumer(
            builder: (context, ref, _) {
              harness.context = context;
              harness.ref = ref;
              // Watch to keep the autoDispose provider alive for assertions.
              final amount = ref.watch(pSendAmount);
              return Text("pSendAmount:${amount?.raw}");
            },
          ),
        ),
      ),
    ),
  );
  return harness;
}

typedef _HandlerSetup = ({
  OpenCryptoPaySendHandler handler,
  TextEditingController sendTo,
  TextEditingController amount,
  List<String> validAddresses,
});

_HandlerSetup _makeHandler({
  required _Harness harness,
  required CryptoCurrency coin,
  required Client client,
  String? tokenSymbol,
  int? tokenDecimals,
  bool Function()? isMounted,
}) {
  final sendTo = TextEditingController();
  final amount = TextEditingController();
  final validAddresses = <String>[];
  final handler = OpenCryptoPaySendHandler(
    coin: coin,
    sendToController: sendTo,
    onAmountReceived: (parsed) {
      amount.text = harness.ref
          .read(pAmountFormatter(coin))
          .format(parsed, withUnitName: false);
      harness.ref.read(pSendAmount.notifier).state = parsed;
    },
    setValidAddress: validAddresses.add,
    isMounted: isMounted ?? () => true,
    tokenSymbol: tokenSymbol,
    tokenDecimals: tokenDecimals,
    controller: OpenCryptoPayController(
      service: OpenCryptoPayService(client: client),
    ),
  );
  return (
    handler: handler,
    sendTo: sendTo,
    amount: amount,
    validAddresses: validAddresses,
  );
}

/// Run handler.handle and pump enough frames for the loading dialog to open
/// and close. Only use when no blocking error dialog is expected.
Future<void> _handle(
  WidgetTester tester,
  _Harness harness,
  OpenCryptoPaySendHandler handler,
) async {
  final fut = handler.handle(harness.context, _qrLink);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await fut;
  await tester.pump();
}

/// Dismiss a visible StackOkDialog via its OK button.
Future<void> _tapOk(WidgetTester tester) async {
  await tester.tap(find.text("OK"));
  await tester.pump();
}

void main() {
  group("cryptoCoinFor", () {
    test("maps a native coin to the library's CryptoCoin", () {
      final btc = cryptoCoinFor(Bitcoin(CryptoCurrencyNetwork.main));
      expect(btc.ticker, "BTC");
      expect(btc.prettyName, "Bitcoin");
      expect(btc.displayName, "Bitcoin");

      final xmr = cryptoCoinFor(Monero(CryptoCurrencyNetwork.main));
      expect(xmr.ticker, "XMR");
      expect(xmr.prettyName, "Monero");
      expect(xmr.displayName, "Monero");

      final eth = cryptoCoinFor(Ethereum(CryptoCurrencyNetwork.main));
      expect(eth.ticker, "ETH");
      expect(eth.prettyName, "Ethereum");
      expect(eth.displayName, "Ethereum");
    });

    test("tokenSymbol overrides ticker so requests target the token asset", () {
      final erc20 = cryptoCoinFor(
        Ethereum(CryptoCurrencyNetwork.main),
        tokenSymbol: "USDT",
      );
      expect(erc20.ticker, "USDT");
      expect(erc20.prettyName, "Ethereum");
      expect(erc20.displayName, "USDT");

      final spl = cryptoCoinFor(
        Solana(CryptoCurrencyNetwork.main),
        tokenSymbol: "USDC",
      );
      expect(spl.ticker, "USDC");
      expect(spl.prettyName, "Solana");
    });
  });

  group("OpenCryptoPaySendHandler.handle", () {
    testWidgets("prefills the send form for a payable payment (txid flow)", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = _makeHandler(
        harness: harness,
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        client: _mockOcpServer(
          paymentInfo: _paymentInfoJson(quoteExpiration: _futureExpiration()),
          txDetails: _btcDetailsJson(hint: _hashHint),
        ),
      );

      await _handle(tester, harness, setup.handler);

      expect(setup.sendTo.text, _btcAddress);
      expect(setup.amount.text, "0.00001947");
      expect(setup.validAddresses, [_btcAddress]);
      expect(harness.ref.read(pSendAmount)?.raw, BigInt.from(1947));
      expect(harness.ref.read(pSendAmount)?.fractionDigits, 8);
      expect(setup.handler.isActivePaymentFor(_btcAddress), isTrue);
      expect(setup.handler.isActivePaymentFor("bc1qsomeotheraddress"), isFalse);
      expect(setup.handler.requiresBroadcast, isTrue);
      expect(setup.handler.isQuoteExpired, isFalse);
    });

    testWidgets("signed-hex hint results in requiresBroadcast false", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = _makeHandler(
        harness: harness,
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        client: _mockOcpServer(
          paymentInfo: _paymentInfoJson(quoteExpiration: _futureExpiration()),
          txDetails: _btcDetailsJson(hint: _hexHint),
        ),
      );

      await _handle(tester, harness, setup.handler);

      expect(setup.handler.isActivePaymentFor(_btcAddress), isTrue);
      expect(setup.handler.requiresBroadcast, isFalse);
    });

    testWidgets("raw (uint256) token amounts use the token's decimals", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = _makeHandler(
        harness: harness,
        coin: Ethereum(CryptoCurrencyNetwork.main),
        tokenSymbol: "USDT",
        tokenDecimals: 6,
        client: _mockOcpServer(
          paymentInfo: _paymentInfoJson(quoteExpiration: _futureExpiration()),
          txDetails: _erc20DetailsJson(),
        ),
      );

      await _handle(tester, harness, setup.handler);

      expect(setup.sendTo.text, _erc20Recipient);
      expect(setup.amount.text, "1.246858");
      expect(harness.ref.read(pSendAmount)?.raw, BigInt.from(1246858));
      expect(harness.ref.read(pSendAmount)?.fractionDigits, 6);
      expect(setup.handler.isActivePaymentFor(_erc20Recipient), isTrue);
    });

    testWidgets("expired quote at fetch shows the expiry dialog and does not "
        "prefill the form", (tester) async {
      final harness = await _pumpHarness(tester);
      final setup = _makeHandler(
        harness: harness,
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        client: _mockOcpServer(
          paymentInfo: _paymentInfoJson(quoteExpiration: _pastExpiration()),
          txDetails: _btcDetailsJson(hint: _hashHint),
        ),
      );

      final fut = setup.handler.handle(harness.context, _qrLink);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text("Payment quote expired"), findsOneWidget);
      await _tapOk(tester);
      await fut;

      expect(setup.sendTo.text, isEmpty);
      expect(setup.amount.text, isEmpty);
      expect(setup.validAddresses, isEmpty);
      expect(setup.handler.isActivePaymentFor(_btcAddress), isFalse);
      expect(setup.handler.isQuoteExpired, isFalse);
    });

    testWidgets(
      "no pending payment (404) shows a dialog and prefills nothing",
      (tester) async {
        final harness = await _pumpHarness(tester);
        final setup = _makeHandler(
          harness: harness,
          coin: Bitcoin(CryptoCurrencyNetwork.main),
          client: _mockOcpServer(paymentInfo: const {}, paymentInfoStatus: 404),
        );

        final fut = setup.handler.handle(harness.context, _qrLink);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(OpenCryptoPayStrings.noPendingTitle), findsOneWidget);
        await _tapOk(tester);
        await fut;

        expect(setup.sendTo.text, isEmpty);
        expect(setup.handler.isActivePaymentFor(_btcAddress), isFalse);
      },
    );
  });

  group("OpenCryptoPaySendHandler.submitProof", () {
    testWidgets(
      "success clears the active payment and later calls become no-ops",
      (tester) async {
        final requests = <Uri>[];
        final harness = await _pumpHarness(tester);
        final setup = _makeHandler(
          harness: harness,
          coin: Bitcoin(CryptoCurrencyNetwork.main),
          client: _mockOcpServer(
            paymentInfo: _paymentInfoJson(quoteExpiration: _futureExpiration()),
            txDetails: _btcDetailsJson(hint: _hashHint),
            onRequest: requests.add,
          ),
        );

        await _handle(tester, harness, setup.handler);
        expect(setup.handler.isActivePaymentFor(_btcAddress), isTrue);

        final ok = await setup.handler.submitProof(
          harness.context,
          "some_txid",
        );
        expect(ok, isTrue);
        expect(setup.handler.isActivePaymentFor(_btcAddress), isFalse);

        // A second call must not hit the network again.
        final proofRequests = requests
            .where((u) => u.path.contains('/tx/'))
            .length;
        expect(proofRequests, 1);
        final okAgain = await setup.handler.submitProof(
          harness.context,
          "some_txid",
        );
        expect(okAgain, isTrue);
        expect(
          requests.where((u) => u.path.contains('/tx/')).length,
          proofRequests,
        );
      },
    );

    testWidgets("failure retains the payment so the user can retry", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      var mounted = true;
      final setup = _makeHandler(
        harness: harness,
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        isMounted: () => mounted,
        client: _mockOcpServer(
          paymentInfo: _paymentInfoJson(quoteExpiration: _futureExpiration()),
          txDetails: _btcDetailsJson(hint: _hashHint),
          proofStatus: 500,
        ),
      );

      await _handle(tester, harness, setup.handler);

      // Unmounted so the failure flushbar is skipped; the state handling is
      // what is under test here.
      mounted = false;
      final ok = await setup.handler.submitProof(harness.context, "some_txid");
      expect(ok, isFalse);
      expect(setup.handler.isActivePaymentFor(_btcAddress), isTrue);
    });

    testWidgets("quote expiring before hex-proof submission aborts with a "
        "'NOT sent' dialog and retains the payment", (tester) async {
      final harness = await _pumpHarness(tester);
      final setup = _makeHandler(
        harness: harness,
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        client: _mockOcpServer(
          paymentInfo: _paymentInfoJson(
            quoteExpiration: DateTime.now()
                .toUtc()
                .add(const Duration(seconds: 2))
                .toIso8601String(),
          ),
          txDetails: _btcDetailsJson(hint: _hexHint),
        ),
      );

      // Quote is still valid while fetching...
      await _handle(tester, harness, setup.handler);
      expect(setup.handler.isActivePaymentFor(_btcAddress), isTrue);
      expect(setup.handler.requiresBroadcast, isFalse);

      // ...but expires before the user confirms the send. isQuoteExpired
      // reads package:clock's zone-aware clock, which testWidgets backs with
      // FakeAsync, so pumping the fake clock forward is what ages the quote.
      await tester.pump(const Duration(seconds: 3));
      expect(setup.handler.isQuoteExpired, isTrue);

      final fut = setup.handler.submitProof(harness.context, "deadbeef");
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text("Payment quote expired"), findsOneWidget);
      expect(find.textContaining("The payment was NOT sent"), findsOneWidget);
      await _tapOk(tester);

      expect(await fut, isFalse);
      // Retained: details are only cleared on successful submission.
      expect(setup.handler.isActivePaymentFor(_btcAddress), isTrue);
    });
  });
}
