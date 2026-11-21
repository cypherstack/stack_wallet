import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/frost_ms/recipient.dart';
import 'package:stackwallet/providers/global/barcode_scanner_provider.dart';
import 'package:stackwallet/providers/global/clipboard_provider.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/barcode_scanner_interface.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/qr_code_scanner_dialog.dart';

import '../../../sample_data/theme_json.dart';
import '../support/fake_wallets.dart' show TestMonero;

class _TestLocaleService extends LocaleService {
  String _locale = "en_US";

  @override
  String get locale => _locale;

  void setLocale(String locale) {
    _locale = locale;
    notifyListeners();
  }
}

/// The mobile camera scanner, returning [rawContent].
class _FakeScanner implements BarcodeScannerInterface {
  _FakeScanner(this.rawContent);

  final String rawContent;
  int scans = 0;

  @override
  Future<ScanResult> scan({required BuildContext context}) async {
    scans++;
    return ScanResult(rawContent: rawContent);
  }
}

void main() {
  RecipientData data(String address, Amount? amount, String? label) => (
    address: address,
    amount: amount,
    label: label,
    memoBytes: null,
    message: null,
    additionalParams: const {},
  );
  final coin = TestMonero();
  const RecipientId id = (walletId: "wallet", index: 1);

  Amount xmr(String value) => Amount.tryParseCanonicalAmount(
    value,
    fractionDigits: coin.fractionDigits,
  )!;

  late StateProvider<AmountUnit> unit;
  late FakeClipboard clipboard;
  late ProviderContainer container;
  late List<PaymentUriData> multiRecipientUris;
  late _FakeScanner scanner;
  late List<String> messages;
  late _TestLocaleService localeService;

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
    useLayout(desktop: false);

    scanner = _FakeScanner("monero:address7?tx_amount=0.5&recipient_name=Eve");
    unit = StateProvider((_) => AmountUnit.normal);
    clipboard = FakeClipboard();
    multiRecipientUris = [];
    messages = [];
    localeService = _TestLocaleService();
    container = ProviderContainer(
      overrides: [
        pAmountUnit.overrideWithProvider(
          (_) => Provider((ref) => ref.watch(unit)),
        ),
        // Use the production formatter so locale/provider ordering is tested.
        pMaxDecimals.overrideWithProvider(
          (coin) => Provider((_) => coin.fractionDigits),
        ),
        localeServiceChangeNotifierProvider.overrideWithValue(localeService),
        pClipboard.overrideWithValue(clipboard),
        pBarcodeScanner.overrideWithValue(scanner),
      ],
    );
  });

  tearDown(() => container.dispose());

  RecipientData? recipient() => container.read(pRecipient(id));

  Future<void> pumpRecipient(
    WidgetTester tester, {
    RecipientData? initial,
    bool single = false,
    bool handlesMultiRecipientUris = true,
  }) async {
    container.read(pRecipient(id).notifier).state = initial;
    await tester.pumpWidget(
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: Recipient(
                walletId: id.walletId,
                index: id.index,
                displayNumber: 1,
                coin: coin,
                remove: single ? null : () {},
                addAnotherRecipientTapped: () {},
                sendAllTapped: () => "",
                onMultiRecipientUri: handlesMultiRecipientUris
                    ? multiRecipientUris.add
                    : null,
                onMessage: messages.add,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Finder addressField() => find.byKey(const Key("sendViewAddressFieldKey"));
  Finder amountField() =>
      find.byKey(const Key("amountInputFieldCryptoTextFieldKey"));
  String text(WidgetTester tester, Finder finder) =>
      tester.widget<TextField>(finder).controller!.text;

  testWidgets("shows the request's name until the address is changed", (
    tester,
  ) async {
    await pumpRecipient(tester, initial: data("address0", xmr("1"), "Alice"));

    expect(find.text('Name in payment request: "Alice"'), findsOneWidget);
    expect(find.text("Recipient 1"), findsOneWidget);
    expect(find.text("Invalid address"), findsNothing);

    await tester.enterText(addressField(), "bad");
    await tester.pump();

    expect(find.text('Name in payment request: "Alice"'), findsNothing);
    expect(find.text("Recipient 1"), findsOneWidget);
    expect(find.text("Invalid address"), findsOneWidget);
    expect(recipient(), data("bad", xmr("1"), null));
  });

  for (final (name, request, amount) in [
    ("missing", "monero:address0?tx_amount=2", "2"),
    ("empty", "monero:address0?tx_amount=2&recipient_name=", "2"),
    ("whitespace", "monero:address0?tx_amount=2&recipient_name=%20%09%0A", "2"),
    ("missing without an amount", "monero:address0", "1"),
  ]) {
    testWidgets("clears the previous request's name when $name", (
      tester,
    ) async {
      await pumpRecipient(tester, initial: data("address0", xmr("1"), "Alice"));

      await tester.enterText(addressField(), request);
      await tester.pump();

      expect(recipient(), data("address0", xmr(amount), null));
      expect(text(tester, addressField()), "address0");
      expect(text(tester, amountField()), amount);
      expect(find.text('Name in payment request: "Alice"'), findsNothing);
      expect(find.byType(PaymentRequestName), findsNothing);
    });
  }

  testWidgets("replaces the name with the new request's trimmed name", (
    tester,
  ) async {
    await pumpRecipient(tester, initial: data("address0", xmr("1"), "Alice"));

    await tester.enterText(
      addressField(),
      "monero:address0?recipient_name=%20Bob%20",
    );
    await tester.pump();

    expect(recipient(), data("address0", xmr("1"), "Bob"));
    expect(find.text('Name in payment request: "Bob"'), findsOneWidget);
    expect(find.text('Name in payment request: "Alice"'), findsNothing);
  });

  testWidgets("keeps the request's name when the amount is edited", (
    tester,
  ) async {
    await pumpRecipient(tester, initial: data("address0", xmr("1"), "Alice"));

    await tester.enterText(amountField(), "2");
    await tester.pump();

    expect(recipient(), data("address0", xmr("2"), "Alice"));
    expect(find.text('Name in payment request: "Alice"'), findsOneWidget);
  });

  testWidgets("keeps the amount when the display unit changes", (tester) async {
    container.read(unit.notifier).state = AmountUnit.milli;
    await pumpRecipient(tester, initial: data("address0", xmr("1"), "Alice"));
    expect(text(tester, amountField()), "1000");

    container.read(unit.notifier).state = AmountUnit.normal;
    await tester.pump();
    expect(text(tester, amountField()), "1");
    expect(recipient()!.label, "Alice");

    // Editing the recipient afterwards must not read "1000" as XMR.
    await tester.enterText(addressField(), "address1");
    await tester.pump();
    expect(recipient()!.amount, xmr("1"));
    expect(recipient()!.label, isNull);
  });

  for (final desktop in [false, true]) {
    testWidgets("keeps the recipient amount across locale changes "
        "on ${desktop ? 'desktop' : 'mobile'}", (tester) async {
      useLayout(desktop: desktop);
      await pumpRecipient(
        tester,
        initial: data("address0", xmr("1.000000000001"), "Alice"),
      );

      localeService.setLocale("de_DE");
      await tester.pump();
      await tester.pump();
      expect(text(tester, amountField()), "1,000000000001");
      expect(
        recipient(),
        data("address0", xmr("1.000000000001"), "Alice"),
        reason:
            "Changing locale must preserve the stored amount, "
            "not just its text",
      );

      await tester.enterText(amountField(), "2,000000000001");
      await tester.pump();
      expect(recipient()?.amount, xmr("2.000000000001"));

      localeService.setLocale("en_US");
      await tester.pump();
      await tester.pump();
      expect(text(tester, amountField()), "2.000000000001");
      expect(recipient()?.amount, xmr("2.000000000001"));
      expect(recipient()?.label, "Alice");

      await tester.enterText(addressField(), "address1");
      await tester.pump();
      expect(recipient(), data("address1", xmr("2.000000000001"), null));
    });
  }

  testWidgets("fills the address, amount, and name from a pasted request", (
    tester,
  ) async {
    await pumpRecipient(tester);
    await clipboard.setData(
      const ClipboardData(
        text: "monero:address5?tx_amount=0.25&recipient_name=Bob",
      ),
    );

    await tester.tap(
      find.byKey(const Key("sendViewPasteAddressFieldButtonKey")),
    );
    await tester.pumpAndSettle();

    expect(text(tester, addressField()), "address5");
    expect(text(tester, amountField()), "0.25");
    expect(find.text('Name in payment request: "Bob"'), findsOneWidget);
    expect(recipient(), data("address5", xmr("0.25"), "Bob"));
  });

  testWidgets("fills in a request typed or pasted into the address field", (
    tester,
  ) async {
    await pumpRecipient(tester);

    await tester.enterText(addressField(), "monero:address5?tx_amount=2");
    await tester.pump();

    expect(text(tester, addressField()), "address5");
    expect(text(tester, amountField()), "2");
    expect(recipient()!.amount, xmr("2"));
  });

  testWidgets("passes a single request's message on", (tester) async {
    await pumpRecipient(tester);

    await tester.enterText(
      addressField(),
      "monero:address5?tx_amount=2&tx_description=Lunch",
    );
    await tester.pump();

    expect(messages, ["Lunch"]);
    expect(recipient()!.address, "address5");
  });

  testWidgets("shows a request's name on one line", (tester) async {
    await pumpRecipient(
      tester,
      initial: data(
        "address0",
        xmr("1"),
        "Alice\"\nYour wallet (change)\u202E",
      ),
    );

    expect(find.text("Recipient 1"), findsOneWidget);
    expect(
      find.text('Name in payment request: "Alice" Your wallet (change)"'),
      findsOneWidget,
    );
  });

  testWidgets("parses a typed request of the same length as the address", (
    tester,
  ) async {
    await pumpRecipient(tester, initial: data("address12", xmr("1"), null));

    await tester.enterText(addressField(), "monero:ab");
    await tester.pump();

    expect(recipient()!.address, "ab");
  });

  const multiRecipientUri =
      "monero:address1;address2?tx_amount=1;2&recipient_name=A;B";

  testWidgets("hands a request for several recipients to the screen", (
    tester,
  ) async {
    await pumpRecipient(tester, initial: data("address0", xmr("1"), null));

    await tester.enterText(addressField(), multiRecipientUri);
    await tester.pump();

    expect(multiRecipientUris.single.recipients.length, 2);
    expect(messages, isEmpty);
    // The recipient is left as it was until the screen replaces it.
    expect(text(tester, addressField()), "address0");
    expect(recipient(), data("address0", xmr("1"), null));
  });

  testWidgets("rejects requests for several recipients without a handler", (
    tester,
  ) async {
    await pumpRecipient(tester, single: true, handlesMultiRecipientUris: false);

    await tester.enterText(addressField(), multiRecipientUri);
    await tester.pump();

    expect(find.text("Send to"), findsOneWidget);
    expect(find.text("Invalid address"), findsOneWidget);
    expect(recipient()!.address, multiRecipientUri);
  });

  testWidgets("clearing the address drops the name", (tester) async {
    await pumpRecipient(tester, initial: data("address0", xmr("1"), "Alice"));

    await tester.tap(
      find.byKey(const Key("sendViewClearAddressFieldButtonKey")),
    );
    await tester.pump();

    expect(text(tester, addressField()), "");
    expect(find.text("Recipient 1"), findsOneWidget);
    expect(recipient(), data("", xmr("1"), null));
  });

  testWidgets("scans with the mobile scanner on mobile", (tester) async {
    await pumpRecipient(tester);

    await tester.tap(find.byKey(const Key("sendViewScanQrButtonKey")));
    await tester.pumpAndSettle();

    expect(scanner.scans, 1);
    expect(find.byType(QrCodeScannerDialog), findsNothing);
    expect(recipient(), data("address7", xmr("0.5"), "Eve"));
  });

  test("keeps each wallet's recipients separate", () {
    const RecipientId other = (walletId: "other", index: 1);
    container.read(pRecipient(id).notifier).state = data(
      "address0",
      null,
      null,
    );

    expect(container.read(pRecipient(other)), isNull);
  });
}
