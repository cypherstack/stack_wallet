import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:opencryptopay/opencryptopay.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/pages/open_crypto_pay/open_crypto_pay_send_fee.dart';
import 'package:stackwallet/pages/open_crypto_pay/open_crypto_pay_send_handler.dart';
import 'package:stackwallet/providers/ui/preview_tx_button_state_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/eth_commons.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/impl/ethereum_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/eth_token_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';
import 'package:stackwallet/widgets/eth_fee_form.dart';

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

const _recipientJson = {
  "name": "Test Shop AG",
  "address": {
    "street": "Bahnhofstrasse",
    "houseNumber": "7",
    "city": "Zug",
    "zip": "6300",
    "country": "CH",
  },
  "phone": "+41792684224",
  "mail": "mail@example.org",
  "website": "https://example.org/",
  "registrationNumber": "CHE-429.856.521",
};

Map<String, dynamic> _paymentInfoJson({
  required String quoteExpiration,
  Map<String, dynamic>? recipient,
  num btcMinFee = 0,
  num ethMinFee = 0,
}) => {
  "id": "pl_test",
  "tag": "payRequest",
  "callback": _callbackUrl,
  "displayName": "Test Shop",
  if (recipient != null) "recipient": recipient,
  "quote": {
    "id": "plq_test",
    "expiration": quoteExpiration,
    "payment": "plp_test",
  },
  "transferAmounts": [
    {
      "method": "Bitcoin",
      "minFee": btcMinFee,
      "assets": [
        {"asset": "BTC", "amount": "0.00001947"},
      ],
      "available": true,
    },
    {
      "method": "Ethereum",
      "minFee": ethMinFee,
      "assets": [
        {"asset": "USDT", "amount": "1.246858"},
      ],
      "available": true,
    },
  ],
};

Map<String, dynamic> _btcDetailsJson({
  required String hint,
  bool withAmount = true,
}) => {
  "expiryDate": "2100-01-01T00:00:00.000Z",
  "blockchain": "Bitcoin",
  "uri":
      "bitcoin:$_btcAddress?${withAmount ? "amount=0.00001947&" : ""}"
      "label=DFX Payment",
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
  bool proofUnreachable = false,
  void Function(Uri url)? onRequest,
}) {
  return MockClient((request) async {
    onRequest?.call(request.url);
    // Proof submissions go to the callback URL with /cb/ replaced by /tx/.
    if (request.url.path.contains('/tx/')) {
      if (proofUnreachable) throw Exception("socket closed");
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

/// UTXO wallet exposing only fee estimates, in sat/kB.
class _FakeUtxoWallet implements ElectrumXInterface<Bitcoin> {
  _FakeUtxoWallet.offline() : _fees = null;

  _FakeUtxoWallet({required int fast, required int medium, required int slow})
    : _fees = FeeObject(
        numberOfBlocksFast: 1,
        numberOfBlocksAverage: 5,
        numberOfBlocksSlow: 20,
        fast: BigInt.from(fast),
        medium: BigInt.from(medium),
        slow: BigInt.from(slow),
      );

  final FeeObject? _fees;

  @override
  Future<FeeObject> get fees async =>
      _fees ?? (throw Exception("estimateFee failed"));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// EVM fee estimates in wei; medium is the midpoint of fast and slow.
EthFeeObject _ethFees({
  required int baseFee,
  required int fast,
  required int slow,
}) => EthFeeObject(
  suggestBaseFee: BigInt.from(baseFee),
  numberOfBlocksFast: 1,
  numberOfBlocksAverage: 3,
  numberOfBlocksSlow: 6,
  fast: BigInt.from(fast),
  medium: BigInt.from((fast + slow) ~/ 2),
  slow: BigInt.from(slow),
);

/// Token wallet exposing only fee estimates.
class _FakeTokenWallet implements EthTokenWallet {
  _FakeTokenWallet(this._fees);

  final EthFeeObject _fees;

  @override
  Future<EthFeeObject> get fees async => _fees;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Ethereum wallet exposing only fee estimates.
class _FakeEthWallet implements EthereumWallet {
  _FakeEthWallet(this._fees);

  final EthFeeObject _fees;

  @override
  Future<EthFeeObject> get fees async => _fees;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Wallet with fixed fee levels; the fee object holds level ids and the
/// estimate returns a fee amount per id.
class _FakeLevelWallet implements Wallet<Monero> {
  _FakeLevelWallet(this._feeByLevel);

  final Map<int, int> _feeByLevel;

  @override
  Monero get cryptoCurrency => Monero(CryptoCurrencyNetwork.main);

  @override
  Future<FeeObject> get fees async => FeeObject(
    numberOfBlocksFast: 10,
    numberOfBlocksAverage: 15,
    numberOfBlocksSlow: 20,
    fast: BigInt.from(3),
    medium: BigInt.from(2),
    slow: BigInt.from(1),
  );

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async => Amount(
    rawValue: BigInt.from(_feeByLevel[feeRate.toInt()]!),
    fractionDigits: 12,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

Future<void> _tapButton(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
}

/// Dismiss a visible StackOkDialog via its OK button.
Future<void> _tapOk(WidgetTester tester) => _tapButton(tester, "OK");

Amount _btc(int sats) => Amount(rawValue: BigInt.from(sats), fractionDigits: 8);

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
      expect(setup.handler.businessDetails, [
        (label: "Name", value: "Test Shop", uri: null),
      ]);
    });

    testWidgets("lists the business information of the pending payment", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = _makeHandler(
        harness: harness,
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        client: _mockOcpServer(
          paymentInfo: _paymentInfoJson(
            quoteExpiration: _futureExpiration(),
            recipient: _recipientJson,
          ),
          txDetails: _btcDetailsJson(hint: _hashHint),
        ),
      );

      await _handle(tester, harness, setup.handler);

      expect(setup.handler.businessDetails, [
        (label: "Legal name", value: "Test Shop AG", uri: null),
        (
          label: "Postal address",
          value: "Bahnhofstrasse 7\n6300 Zug\nCH",
          uri: null,
        ),
        (
          label: "Phone number",
          value: "+41792684224",
          uri: Uri.parse("tel:+41792684224"),
        ),
        (
          label: "Email",
          value: "mail@example.org",
          uri: Uri.parse("mailto:mail@example.org"),
        ),
        (
          label: "Website",
          value: "https://example.org/",
          uri: Uri.parse("https://example.org/"),
        ),
        (label: "Registration number", value: "CHE-429.856.521", uri: null),
      ]);
    });

    testWidgets("skips empty and missing business fields", (tester) async {
      final harness = await _pumpHarness(tester);
      final setup = _makeHandler(
        harness: harness,
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        client: _mockOcpServer(
          paymentInfo: _paymentInfoJson(
            quoteExpiration: _futureExpiration(),
            recipient: {
              "name": "Test Shop",
              "address": {
                "street": "Bahnhofstrasse",
                "houseNumber": "",
                "city": "Zug",
              },
              "phone": "",
              "registrationNumber": "",
            },
          ),
          txDetails: _btcDetailsJson(hint: _hashHint),
        ),
      );

      await _handle(tester, harness, setup.handler);

      expect(setup.handler.businessDetails, [
        (label: "Legal name", value: "Test Shop", uri: null),
        (label: "Postal address", value: "Bahnhofstrasse\nZug", uri: null),
      ]);
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

    testWidgets("network failure shows a generic dialog without details", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = _makeHandler(
        harness: harness,
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        client: MockClient((_) async => throw Exception("socket closed")),
      );

      final fut = setup.handler.handle(harness.context, _qrLink);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(OpenCryptoPayStrings.genericErrorTitle), findsOneWidget);
      expect(
        find.text(OpenCryptoPayStrings.genericErrorMessage),
        findsOneWidget,
      );
      expect(find.textContaining("socket closed"), findsNothing);
      await _tapOk(tester);
      await fut;

      expect(setup.sendTo.text, isEmpty);
      expect(setup.handler.isActivePaymentFor(_btcAddress), isFalse);
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

  group("OpenCryptoPaySendHandler.confirmSend", () {
    final dialogTitle = find.textContaining(" changed");

    Future<_HandlerSetup> pendingPayment(
      WidgetTester tester,
      _Harness harness, {
      bool withAmount = true,
      String? quoteExpiration,
      List<Uri>? requests,
    }) async {
      final setup = _makeHandler(
        harness: harness,
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        client: _mockOcpServer(
          paymentInfo: _paymentInfoJson(
            quoteExpiration: quoteExpiration ?? _futureExpiration(),
          ),
          txDetails: _btcDetailsJson(hint: _hashHint, withAmount: withAmount),
          onRequest: requests?.add,
        ),
      );
      await _handle(tester, harness, setup.handler);
      return setup;
    }

    testWidgets("passes silently without a pending payment", (tester) async {
      final harness = await _pumpHarness(tester);
      final setup = _makeHandler(
        harness: harness,
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        client: _mockOcpServer(paymentInfo: const {}),
      );

      final fut = setup.handler.confirmSend(
        harness.context,
        "bc1qother",
        _btc(1),
      );
      await tester.pump();
      expect(dialogTitle, findsNothing);
      expect(await fut, isTrue);
    });

    testWidgets("passes silently for the quoted recipient and amount", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingPayment(tester, harness);

      final fut = setup.handler.confirmSend(
        harness.context,
        _btcAddress,
        _btc(1947),
      );
      await tester.pump();
      expect(dialogTitle, findsNothing);
      expect(await fut, isTrue);
      expect(setup.handler.isActivePaymentFor(_btcAddress), isTrue);
    });

    testWidgets("an open-amount request binds only the recipient", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingPayment(tester, harness, withAmount: false);
      expect(setup.amount.text, isEmpty);

      final fut = setup.handler.confirmSend(
        harness.context,
        _btcAddress,
        _btc(99999),
      );
      await tester.pump();
      expect(dialogTitle, findsNothing);
      expect(await fut, isTrue);
    });

    testWidgets("another amount asks and keeps the payment on Continue", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingPayment(tester, harness);

      var fut = setup.handler.confirmSend(
        harness.context,
        _btcAddress,
        _btc(1948),
      );
      await tester.pump();
      expect(dialogTitle, findsOneWidget);
      expect(find.text("Amount changed"), findsOneWidget);
      expect(
        find.textContaining("asked for a different amount."),
        findsOneWidget,
      );
      await _tapButton(tester, "Cancel");
      expect(await fut, isFalse);
      expect(setup.handler.isActivePaymentFor(_btcAddress), isTrue);

      fut = setup.handler.confirmSend(harness.context, _btcAddress, _btc(1948));
      await tester.pump();
      await _tapButton(tester, "Continue");
      expect(await fut, isTrue);
      expect(setup.handler.isActivePaymentFor(_btcAddress), isTrue);
    });

    testWidgets("another recipient asks and marks the request overridden", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingPayment(tester, harness);
      expect(setup.handler.quoteOverridden, isFalse);

      final fut = setup.handler.confirmSend(
        harness.context,
        "bc1qother",
        _btc(1947),
      );
      await tester.pump();
      expect(dialogTitle, findsOneWidget);
      expect(find.text("Recipient changed"), findsOneWidget);
      expect(
        find.textContaining("asked for a different recipient."),
        findsOneWidget,
      );
      await _tapButton(tester, "Continue");
      expect(await fut, isTrue);

      expect(setup.handler.quoteOverridden, isTrue);
      expect(setup.handler.isActivePaymentFor(_btcAddress), isTrue);
    });

    testWidgets("reset drops the request without a network call", (
      tester,
    ) async {
      final requests = <Uri>[];
      final harness = await _pumpHarness(tester);
      final setup = await pendingPayment(tester, harness, requests: requests);
      final requestsBefore = requests.length;

      setup.handler.reset();

      expect(setup.handler.quoteOverridden, isFalse);
      expect(setup.handler.isActivePaymentFor(_btcAddress), isFalse);
      expect(
        await setup.handler.submitProof(harness.context, "some_txid"),
        isTrue,
      );
      expect(requests.length, requestsBefore);

      final fut = setup.handler.confirmSend(
        harness.context,
        "bc1qother",
        _btc(1),
      );
      await tester.pump();
      expect(dialogTitle, findsNothing);
      expect(await fut, isTrue);
    });

    testWidgets("both changed names recipient and amount", (tester) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingPayment(tester, harness);

      final fut = setup.handler.confirmSend(
        harness.context,
        "bc1qother",
        _btc(1948),
      );
      await tester.pump();
      expect(find.text("Recipient and amount changed"), findsOneWidget);
      expect(
        find.textContaining("asked for a different recipient and amount."),
        findsOneWidget,
      );
      await _tapButton(tester, "Cancel");
      expect(await fut, isFalse);
    });

    testWidgets("an expired request does not ask", (tester) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingPayment(
        tester,
        harness,
        quoteExpiration: DateTime.now()
            .toUtc()
            .add(const Duration(seconds: 2))
            .toIso8601String(),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(setup.handler.isQuoteExpired, isTrue);

      final fut = setup.handler.confirmSend(
        harness.context,
        _btcAddress,
        _btc(1948),
      );
      await tester.pump();
      expect(dialogTitle, findsNothing);
      expect(await fut, isTrue);
    });
  });

  group("OpenCryptoPaySendHandler.sendFee", () {
    const title = "High network fee";

    Future<_HandlerSetup> pendingBtc(
      WidgetTester tester,
      _Harness harness, {
      num minFee = 0,
    }) async {
      final setup = _makeHandler(
        harness: harness,
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        client: _mockOcpServer(
          paymentInfo: _paymentInfoJson(
            quoteExpiration: _futureExpiration(),
            btcMinFee: minFee,
          ),
          txDetails: _btcDetailsJson(hint: _hashHint),
        ),
      );
      await _handle(tester, harness, setup.handler);
      return setup;
    }

    Future<_HandlerSetup> pendingErc20(
      WidgetTester tester,
      _Harness harness, {
      num minFee = 0,
    }) async {
      final setup = _makeHandler(
        harness: harness,
        coin: Ethereum(CryptoCurrencyNetwork.main),
        tokenSymbol: "USDT",
        tokenDecimals: 6,
        client: _mockOcpServer(
          paymentInfo: _paymentInfoJson(
            quoteExpiration: _futureExpiration(),
            ethMinFee: minFee,
          ),
          txDetails: _erc20DetailsJson(),
        ),
      );
      await _handle(tester, harness, setup.handler);
      return setup;
    }

    Future<OpenCryptoPaySendFee?> feeFor(
      WidgetTester tester,
      _Harness harness,
      OpenCryptoPaySendHandler handler,
      Wallet wallet, {
      String? address = _btcAddress,
      FeeRateType feeRateType = FeeRateType.average,
      int? satsPerVByte,
      EthEIP1559Fee? ethFee,
      bool feeRateApplies = true,
      String? tap,
      String? message,
    }) async {
      final fut = handler.sendFee(
        harness.context,
        wallet,
        address: address,
        amount: _btc(1000),
        feeRateType: feeRateType,
        satsPerVByte: satsPerVByte,
        ethFee: ethFee,
        feeRateApplies: feeRateApplies,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      if (tap != null) {
        expect(find.text(title), findsOneWidget);
        if (message != null) expect(find.text(message), findsOneWidget);
        await _tapButton(tester, tap);
        await tester.pumpAndSettle();
      } else {
        expect(find.text(title), findsNothing);
      }
      return fut;
    }

    // sat/kB estimates: fast 5 sat/vB, average 3, slow 1.
    final utxoWallet = _FakeUtxoWallet(fast: 5000, medium: 3000, slow: 1000);
    const average = (
      feeRateType: FeeRateType.average,
      satsPerVByte: null,
      ethFee: null,
    );

    testWidgets("no override without a pending payment or a minimum", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final none = await pendingBtc(tester, harness);
      final floor = await feeFor(tester, harness, none.handler, utxoWallet);
      expect(floor, average);

      final other = await pendingBtc(tester, harness, minFee: 4);
      final elsewhere = await feeFor(
        tester,
        harness,
        other.handler,
        utxoWallet,
        address: "bc1qother",
      );
      expect(elsewhere, average);
    });

    testWidgets("a send building its own fee keeps the chosen one", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingBtc(tester, harness, minFee: 20);
      final floor = await feeFor(
        tester,
        harness,
        setup.handler,
        utxoWallet,
        feeRateApplies: false,
      );
      expect(floor, average);
    });

    testWidgets("a preset at or above the minimum is kept", (tester) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingBtc(tester, harness, minFee: 3);
      final floor = await feeFor(tester, harness, setup.handler, utxoWallet);
      expect(floor, average);

      final custom = await feeFor(
        tester,
        harness,
        setup.handler,
        utxoWallet,
        feeRateType: FeeRateType.custom,
        satsPerVByte: 7,
      );
      expect(custom!.satsPerVByte, 7);
    });

    testWidgets("a preset below the minimum is raised without asking", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingBtc(tester, harness, minFee: 4.2);
      final floor = await feeFor(
        tester,
        harness,
        setup.handler,
        utxoWallet,
        feeRateType: FeeRateType.slow,
      );
      expect(floor!.feeRateType, FeeRateType.custom);
      expect(floor.satsPerVByte, 5);
    });

    testWidgets("a custom rate below the minimum is raised", (tester) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingBtc(tester, harness, minFee: 4.2);
      final floor = await feeFor(
        tester,
        harness,
        setup.handler,
        utxoWallet,
        feeRateType: FeeRateType.custom,
        satsPerVByte: 2,
      );
      expect(floor!.satsPerVByte, 5);
    });

    testWidgets("the minimum is compared in sat/kB", (tester) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingBtc(tester, harness, minFee: 2.146);
      final wallet = _FakeUtxoWallet(fast: 5000, medium: 2146, slow: 2100);

      final exact = await feeFor(tester, harness, setup.handler, wallet);
      expect(exact, average);

      final under = await feeFor(
        tester,
        harness,
        setup.handler,
        wallet,
        feeRateType: FeeRateType.slow,
      );
      expect(under!.feeRateType, FeeRateType.custom);
      expect(under.satsPerVByte, 3);
    });

    testWidgets("a minimum above the fast estimate asks first", (tester) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingBtc(tester, harness, minFee: 12);

      final cancelled = await feeFor(
        tester,
        harness,
        setup.handler,
        utxoWallet,
        tap: "Cancel",
        message:
            "The payment request requires a network fee of at least "
            "12 sats/vByte, above the current fast estimate of 5.00 sats/vByte.",
      );
      expect(cancelled, isNull);

      final accepted = await feeFor(
        tester,
        harness,
        setup.handler,
        utxoWallet,
        tap: "Continue",
      );
      expect(accepted!.feeRateType, FeeRateType.custom);
      expect(accepted.satsPerVByte, 12);
    });

    // Fee amounts per level id: slow 1, average 2, fast 3.
    final levelWallet = _FakeLevelWallet({1: 1000, 2: 2000, 3: 3000});

    testWidgets("a fee level at or above the minimum is kept", (tester) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingBtc(tester, harness, minFee: 1500);
      final floor = await feeFor(tester, harness, setup.handler, levelWallet);
      expect(floor, average);
    });

    testWidgets("the lowest fee level reaching the minimum is chosen", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingBtc(tester, harness, minFee: 2500);
      final floor = await feeFor(
        tester,
        harness,
        setup.handler,
        levelWallet,
        feeRateType: FeeRateType.slow,
      );
      expect(floor!.feeRateType, FeeRateType.fast);
    });

    testWidgets("a minimum above the fastest level blocks the send", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingBtc(tester, harness, minFee: 3500);
      final fut = setup.handler.sendFee(
        harness.context,
        levelWallet,
        address: _btcAddress,
        amount: _btc(1000),
        feeRateType: FeeRateType.fast,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text("Network fee too low"), findsOneWidget);
      expect(
        find.text(
          "The payment request requires a network fee of at least "
          "0.0000000035 XMR, above this wallet's fastest fee of "
          "0.000000003 XMR.",
        ),
        findsOneWidget,
      );
      await _tapOk(tester);
      await tester.pumpAndSettle();
      expect(await fut, isNull);
      expect(setup.handler.isActivePaymentFor(_btcAddress), isTrue);
    });

    testWidgets("an unavailable fee estimate keeps the chosen fee", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingBtc(tester, harness, minFee: 12);
      final floor = await feeFor(
        tester,
        harness,
        setup.handler,
        _FakeUtxoWallet.offline(),
      );
      expect(floor, average);
    });

    // base 10 gwei, fast 12 gwei, slow 10.5 gwei.
    final ethFees = _ethFees(
      baseFee: 10000000000,
      fast: 12000000000,
      slow: 10500000000,
    );
    final tokenWallet = _FakeTokenWallet(ethFees);
    final gwei = BigInt.from(1000000000);

    testWidgets("an EVM preset at or above the minimum is kept", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingErc20(tester, harness, minFee: 12000000000);
      const fast = (
        feeRateType: FeeRateType.fast,
        satsPerVByte: null,
        ethFee: null,
      );
      final floor = await feeFor(
        tester,
        harness,
        setup.handler,
        tokenWallet,
        address: _erc20Recipient,
        feeRateType: FeeRateType.fast,
      );
      expect(floor, fast);

      final customFee = EthEIP1559Fee(
        maxFeePerGasGwei: Decimal.fromInt(15),
        maxPriorityFeePerGasGwei: Decimal.one,
        gasLimit: 90000,
      );
      final custom = await feeFor(
        tester,
        harness,
        setup.handler,
        tokenWallet,
        address: _erc20Recipient,
        feeRateType: FeeRateType.custom,
        ethFee: customFee,
      );
      expect(custom!.ethFee, same(customFee));
    });

    testWidgets(
      "an EVM minimum below the fast estimate is raised without asking",
      (tester) async {
        final harness = await _pumpHarness(tester);
        final setup = await pendingErc20(tester, harness, minFee: 11000000000);
        final floor = await feeFor(
          tester,
          harness,
          setup.handler,
          tokenWallet,
          address: _erc20Recipient,
          feeRateType: FeeRateType.slow,
        );
        expect(floor!.feeRateType, FeeRateType.custom);
        final fee = floor.ethFee!;
        expect(fee.maxFeePerGasWei, gwei * BigInt.from(21));
        expect(fee.maxPriorityFeePerGasWei, gwei);
        expect(fee.gasLimit, kEthereumTokenMinGasLimit);
      },
    );

    testWidgets("an EVM custom fee below the minimum keeps its gas limit", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingErc20(tester, harness, minFee: 11000000000);
      final floor = await feeFor(
        tester,
        harness,
        setup.handler,
        tokenWallet,
        address: _erc20Recipient,
        feeRateType: FeeRateType.custom,
        ethFee: EthEIP1559Fee(
          maxFeePerGasGwei: Decimal.fromInt(5),
          maxPriorityFeePerGasGwei: Decimal.one,
          gasLimit: 90000,
        ),
      );
      final fee = floor!.ethFee!;
      expect(fee.maxFeePerGasWei, gwei * BigInt.from(21));
      expect(fee.maxPriorityFeePerGasWei, gwei);
      expect(fee.gasLimit, 90000);
    });

    testWidgets("an EVM minimum above the fast estimate asks first", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = await pendingErc20(tester, harness, minFee: 30000000000);
      const message =
          "The payment request requires a network fee of at least "
          "30.00 gwei, above the current fast estimate of 12.00 gwei.";

      final cancelled = await feeFor(
        tester,
        harness,
        setup.handler,
        _FakeEthWallet(ethFees),
        address: _erc20Recipient,
        feeRateType: FeeRateType.fast,
        tap: "Cancel",
        message: message,
      );
      expect(cancelled, isNull);

      final accepted = await feeFor(
        tester,
        harness,
        setup.handler,
        _FakeEthWallet(ethFees),
        address: _erc20Recipient,
        feeRateType: FeeRateType.fast,
        tap: "Continue",
        message: message,
      );
      expect(accepted!.feeRateType, FeeRateType.custom);
      final fee = accepted.ethFee!;
      expect(fee.maxFeePerGasWei, gwei * BigInt.from(40));
      expect(fee.maxPriorityFeePerGasWei, gwei * BigInt.from(20));
      expect(fee.gasLimit, kEthereumMinGasLimit);
    });
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

    testWidgets("failure shows a dialog and retains the payment for retry", (
      tester,
    ) async {
      final harness = await _pumpHarness(tester);
      final setup = _makeHandler(
        harness: harness,
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        client: _mockOcpServer(
          paymentInfo: _paymentInfoJson(quoteExpiration: _futureExpiration()),
          txDetails: _btcDetailsJson(hint: _hashHint),
          proofStatus: 500,
        ),
      );

      await _handle(tester, harness, setup.handler);

      final fut = setup.handler.submitProof(harness.context, "some_txid");
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(OpenCryptoPayStrings.proofFailedTitle), findsOneWidget);
      expect(find.text(OpenCryptoPayStrings.proofFailed), findsOneWidget);
      await _tapOk(tester);

      expect(await fut, isFalse);
      expect(setup.handler.isActivePaymentFor(_btcAddress), isTrue);
    });

    testWidgets("a lost response on hex-proof submission is reported as "
        "unconfirmed delivery", (tester) async {
      final harness = await _pumpHarness(tester);
      final setup = _makeHandler(
        harness: harness,
        coin: Bitcoin(CryptoCurrencyNetwork.main),
        client: _mockOcpServer(
          paymentInfo: _paymentInfoJson(quoteExpiration: _futureExpiration()),
          txDetails: _btcDetailsJson(hint: _hexHint),
          proofUnreachable: true,
        ),
      );
      await _handle(tester, harness, setup.handler);

      final fut = setup.handler.submitProof(harness.context, "deadbeef");
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text(OpenCryptoPayStrings.deliveryUnconfirmedTitle),
        findsOneWidget,
      );
      expect(find.textContaining("Nothing was sent"), findsNothing);
      await _tapOk(tester);
      expect(await fut, isFalse);
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
