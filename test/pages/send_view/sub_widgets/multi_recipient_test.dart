import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/frost_ms/recipient.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/multi_recipient.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
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
  final coin = _TestMonero();

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

  Amount xmr(String value) => Amount.tryParseCanonicalAmount(
    value,
    fractionDigits: coin.fractionDigits,
  )!;

  test("parses each recipient's amount in the coin's units", () {
    final recipients = parseUriRecipients(uri(["1.5", "0.000000000001"]), coin);

    expect(recipients, [
      (address: "address0", amount: xmr("1.5"), label: "Alice"),
      (address: "address1", amount: xmr("0.000000000001"), label: null),
    ]);
    expect(recipients!.total, xmr("1.500000000001"));
  });

  test("truncates amounts more precise than the coin", () {
    final recipients = parseUriRecipients(uri(["0.1234567890129", "1"]), coin);

    expect(recipients!.first.amount, xmr("0.123456789012"));
  });

  test("rejects missing and zero amounts", () {
    expect(parseUriRecipients(uri(["1", null]), coin), isNull);
    expect(parseUriRecipients(uri(["1", "0"]), coin), isNull);
    expect(parseUriRecipients(uri(["1", "0.0000000000001"]), coin), isNull);
  });

  test("builds one transaction output per recipient", () {
    final recipients = parseUriRecipients(uri(["1", "2"]), coin)!;

    expect(recipients.isValidFor(coin), isTrue);

    final outputs = recipients.toTxRecipients(coin);
    expect(outputs.map((e) => e.address), ["address0", "address1"]);
    expect(outputs.map((e) => e.amount), [xmr("1"), xmr("2")]);
    expect(outputs.map((e) => e.isChange), [false, false]);
    expect(outputs.map((e) => e.addressType), [
      AddressType.cryptonote,
      AddressType.cryptonote,
    ]);
  });

  test("is invalid unless every recipient has an address and amount", () {
    final RecipientData valid = (
      address: "address0",
      amount: xmr("1"),
      label: null,
    );

    expect([valid, valid].isValidFor(coin), isTrue);
    for (final RecipientData invalid in [
      (address: "bad", amount: xmr("2"), label: null),
      (address: "address1", amount: null, label: null),
      (address: "address1", amount: xmr("0"), label: null),
    ]) {
      expect([valid, invalid].isValidFor(coin), isFalse);
    }
  });

  test("has no total while an amount is missing", () {
    expect(
      [
        (address: "address0", amount: xmr("1"), label: null),
        (address: "address1", amount: null, label: null),
      ].total,
      isNull,
    );
  });

  late ProviderContainer container;

  /// Lays widgets out for desktop or mobile on any host platform.
  void useLayout({required bool desktop}) {
    Util.layoutPlatform = platform.FakePlatform(
      operatingSystem: desktop ? "linux" : "android",
    );
    Util.screenWidth = null;
    Util.isIpad = false;
  }

  setUp(() {
    final previousPlatform = Util.layoutPlatform;
    final previousWidth = Util.screenWidth;
    final previousIsIpad = Util.isIpad;
    addTearDown(() {
      Util.layoutPlatform = previousPlatform;
      Util.screenWidth = previousWidth;
      Util.isIpad = previousIsIpad;
    });

    container = ProviderContainer(
      overrides: [
        pAmountUnit.overrideWithProvider(
          (_) => Provider((_) => AmountUnit.normal),
        ),
        pAmountFormatter.overrideWithProvider(
          (coin) => Provider(
            (_) => AmountFormatter(
              unit: AmountUnit.normal,
              locale: "en_US",
              coin: coin,
              maxDecimals: coin.fractionDigits,
            ),
          ),
        ),
        localeServiceChangeNotifierProvider.overrideWithProvider(
          ChangeNotifierProvider((_) => LocaleService()),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(json: lightThemeJsonMap),
            ),
          ],
        ),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );

  testWidgets("confirmation list shows names and amounts", (tester) async {
    await pump(
      tester,
      RecipientAmountList(
        coin: coin,
        recipients: parseUriRecipients(
          uri(["1", "2.50", "0.000000000001"]),
          coin,
        )!.toTxRecipients(coin),
        labels: const ["Alice", null, null],
        labelStyle: const TextStyle(),
        valueStyle: const TextStyle(),
      ),
    );

    expect(find.text("Alice"), findsOneWidget);
    expect(find.text("Recipient 2"), findsOneWidget);
    expect(find.text("Recipient 3"), findsOneWidget);
    expect(find.text("1 XMR"), findsOneWidget);
    expect(find.text("2.5 XMR"), findsOneWidget);
    expect(find.text("0.000000000001 XMR"), findsOneWidget);
  });

  for (final isDesktop in [true, false]) {
    final platform = isDesktop ? "desktop" : "mobile";

    testWidgets("lists a form per recipient on $platform", (tester) async {
      useLayout(desktop: isDesktop);
      for (final (index, address) in [(3, "address0"), (7, "bad")]) {
        container
            .read(pRecipient((walletId: "wallet", index: index)).notifier)
            .state = (
          address: address,
          amount: xmr("1"),
          label: null,
        );
      }
      int added = 0;
      final List<int> removed = [];

      await pump(
        tester,
        RecipientForms(
          walletId: "wallet",
          coin: coin,
          indexes: const [3, 7],
          onChanged: () {},
          onAdd: () => added++,
          onRemove: removed.add,
          onMultiRecipientUri: (_) {},
        ),
      );

      expect(find.text("Recipient 1"), findsOneWidget);
      expect(find.text("Recipient 2"), findsOneWidget);
      expect(find.widgetWithText(TextField, "address0"), findsOneWidget);
      expect(find.widgetWithText(TextField, "bad"), findsOneWidget);
      expect(find.text("Invalid address"), findsOneWidget);

      await tester.tap(find.text("Add recipient"));
      await tester.tap(find.text("Remove", findRichText: true).last);
      await tester.pump();

      expect(added, 1);
      expect(removed, [7]);
    });
  }

  for (final (button, replace) in [("Replace", true), ("Cancel", false)]) {
    testWidgets("asks before replacing recipients ($button)", (tester) async {
      useLayout(desktop: false);
      bool? result;
      await pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await confirmReplaceRecipients(context, count: 3),
            child: const Text("open"),
          ),
        ),
      );

      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
      expect(find.text("Replace recipients?"), findsOneWidget);
      expect(find.textContaining("has 3 recipients"), findsOneWidget);

      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      expect(result, replace);
    });
  }
}
