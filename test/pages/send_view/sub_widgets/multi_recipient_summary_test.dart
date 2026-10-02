import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/multi_recipient_summary.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';

import '../../../sample_data/theme_json.dart';

/// Monero that validates addresses without the native library.
class _TestMonero extends Monero {
  _TestMonero() : super(CryptoCurrencyNetwork.main);

  @override
  bool validateAddress(String address) => address.startsWith("address");
}

void main() {
  final monero = Monero(CryptoCurrencyNetwork.main);

  PaymentUriData uri(List<String?> amounts, {List<String>? addresses}) =>
      PaymentUriData(
        scheme: "monero",
        recipients: [
          for (int i = 0; i < amounts.length; i++)
            PaymentUriRecipient(
              address: addresses?[i] ?? "address$i",
              amount: amounts[i],
              label: i == 0 ? "Alice" : null,
            ),
        ],
        additionalParams: const {},
      );

  test("parses each recipient's amount in the coin's units", () {
    final recipients = parseUriRecipients(
      uri(["1.5", "0.000000000001"]),
      monero,
    );

    expect(recipients, isNotNull);
    expect(recipients!.map((e) => e.address), ["address0", "address1"]);
    expect(recipients.map((e) => e.label), ["Alice", null]);
    expect(recipients.map((e) => e.amount.raw), [
      BigInt.from(1500000000000),
      BigInt.one,
    ]);
    expect(recipients.total.raw, BigInt.from(1500000000001));
  });

  test("truncates amounts more precise than the coin", () {
    final recipients = parseUriRecipients(
      uri(["0.1234567890129", "1"]),
      monero,
    );

    expect(recipients!.first.amount.raw, BigInt.from(123456789012));
  });

  test("rejects missing and zero amounts", () {
    expect(parseUriRecipients(uri(["1", null]), monero), isNull);
    expect(parseUriRecipients(uri(["1", "0"]), monero), isNull);
    expect(parseUriRecipients(uri(["1", "0.0000000000001"]), monero), isNull);
  });

  test("builds one transaction output per recipient", () {
    final coin = _TestMonero();
    final recipients = parseUriRecipients(uri(["1", "2"]), coin)!;

    expect(recipients.allValidFor(coin), isTrue);

    final outputs = recipients.toTxRecipients(coin);
    expect(outputs.map((e) => e.address), ["address0", "address1"]);
    expect(outputs.map((e) => e.amount.raw), [
      BigInt.from(1000000000000),
      BigInt.from(2000000000000),
    ]);
    expect(outputs.map((e) => e.isChange), [false, false]);
    expect(outputs.map((e) => e.addressType), [
      AddressType.cryptonote,
      AddressType.cryptonote,
    ]);
  });

  test("is invalid if any recipient address is invalid", () {
    final coin = _TestMonero();
    final recipients = parseUriRecipients(
      uri(["1", "2"], addresses: ["address0", "bad"]),
      coin,
    )!;

    expect(recipients.allValidFor(coin), isFalse);
  });

  group("MultiRecipientSummary", () {
    final coin = _TestMonero();
    final formatter = AmountFormatter(
      unit: AmountUnit.normal,
      locale: "en_US",
      coin: coin,
      maxDecimals: 12,
    );

    tearDown(() => Util.screenWidth = null);

    Future<void> pumpSummary(
      WidgetTester tester,
      List<SendRecipient> recipients, {
      VoidCallback? onClear,
    }) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          pAmountFormatter.overrideWithProvider(
            (_) => Provider((_) => formatter),
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: MultiRecipientSummary(
                coin: coin,
                recipients: recipients,
                onClear: onClear ?? () {},
              ),
            ),
          ),
        ),
      ),
    );

    for (final isDesktop in [true, false]) {
      testWidgets(
        "lists every recipient on ${isDesktop ? "desktop" : "mobile"}",
        (tester) async {
          Util.screenWidth = isDesktop ? null : 400;
          final recipients = parseUriRecipients(
            uri(["1.5", "0.25"], addresses: ["address0", "bad"]),
            coin,
          )!;

          await pumpSummary(tester, recipients);

          expect(find.text("2 recipients"), findsOneWidget);
          expect(find.text("Alice"), findsOneWidget);
          expect(find.text("address0"), findsOneWidget);
          expect(find.text("bad"), findsOneWidget);
          for (final recipient in recipients) {
            expect(
              find.text(formatter.format(recipient.amount)),
              findsOneWidget,
            );
          }
          expect(find.text("Invalid address"), findsOneWidget);
        },
      );

      testWidgets(
        "Clear calls onClear on ${isDesktop ? "desktop" : "mobile"}",
        (tester) async {
          Util.screenWidth = isDesktop ? null : 400;
          int cleared = 0;
          await pumpSummary(
            tester,
            parseUriRecipients(uri(["1", "2"]), coin)!,
            onClear: () => cleared++,
          );

          await tester.tap(find.text("Clear", findRichText: true));
          await tester.pumpAndSettle();

          expect(cleared, 1);
        },
      );
    }
  });
}
