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
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/widgets/desktop/qr_code_scanner_dialog.dart';

import '../../../sample_data/theme_json.dart';

/// Monero that validates addresses without the native library.
class _TestMonero extends Monero {
  _TestMonero() : super(CryptoCurrencyNetwork.main);

  @override
  bool validateAddress(String address) => address.startsWith("address");
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
  final coin = _TestMonero();
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
    container = ProviderContainer(
      overrides: [
        pAmountUnit.overrideWithProvider(
          (_) => Provider((ref) => ref.watch(unit)),
        ),
        pAmountFormatter.overrideWithProvider(
          (coin) => Provider(
            (ref) => AmountFormatter(
              unit: ref.watch(pAmountUnit(coin)),
              locale: "en_US",
              coin: coin,
              maxDecimals: coin.fractionDigits,
            ),
          ),
        ),
        localeServiceChangeNotifierProvider.overrideWithProvider(
          ChangeNotifierProvider((_) => LocaleService()),
        ),
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
    await pumpRecipient(
      tester,
      initial: (address: "address0", amount: xmr("1"), label: "Alice"),
    );

    expect(find.text("Alice"), findsOneWidget);
    expect(find.text("Invalid address"), findsNothing);

    await tester.enterText(addressField(), "bad");
    await tester.pump();

    expect(find.text("Alice"), findsNothing);
    expect(find.text("Recipient 1"), findsOneWidget);
    expect(find.text("Invalid address"), findsOneWidget);
    expect(recipient(), (address: "bad", amount: xmr("1"), label: null));
  });

  testWidgets("keeps the amount when the display unit changes", (tester) async {
    container.read(unit.notifier).state = AmountUnit.milli;
    await pumpRecipient(
      tester,
      initial: (address: "address0", amount: xmr("1"), label: null),
    );
    expect(text(tester, amountField()), "1000");

    container.read(unit.notifier).state = AmountUnit.normal;
    await tester.pump();
    expect(text(tester, amountField()), "1");

    // Editing the recipient afterwards must not read "1000" as XMR.
    await tester.enterText(addressField(), "address1");
    await tester.pump();
    expect(recipient()!.amount, xmr("1"));
  });

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
    expect(find.text("Bob"), findsOneWidget);
    expect(recipient(), (
      address: "address5",
      amount: xmr("0.25"),
      label: "Bob",
    ));
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

  const multiRecipientUri =
      "monero:address1;address2?tx_amount=1;2&recipient_name=A;B";

  testWidgets("hands a request for several recipients to the screen", (
    tester,
  ) async {
    await pumpRecipient(
      tester,
      initial: (address: "address0", amount: xmr("1"), label: null),
    );

    await tester.enterText(addressField(), multiRecipientUri);
    await tester.pump();

    expect(multiRecipientUris.single.recipients.length, 2);
    // The recipient is left as it was until the screen replaces it.
    expect(text(tester, addressField()), "address0");
    expect(recipient(), (address: "address0", amount: xmr("1"), label: null));
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
    await pumpRecipient(
      tester,
      initial: (address: "address0", amount: xmr("1"), label: "Alice"),
    );

    await tester.tap(
      find.byKey(const Key("sendViewClearAddressFieldButtonKey")),
    );
    await tester.pump();

    expect(text(tester, addressField()), "");
    expect(find.text("Recipient 1"), findsOneWidget);
    expect(recipient(), (address: "", amount: xmr("1"), label: null));
  });

  testWidgets("scans with the mobile scanner on mobile", (tester) async {
    await pumpRecipient(tester);

    await tester.tap(find.byKey(const Key("sendViewScanQrButtonKey")));
    await tester.pumpAndSettle();

    expect(scanner.scans, 1);
    expect(find.byType(QrCodeScannerDialog), findsNothing);
    expect(recipient(), (
      address: "address7",
      amount: xmr("0.5"),
      label: "Eve",
    ));
  });

  test("keeps each wallet's recipients separate", () {
    const RecipientId other = (walletId: "other", index: 1);
    container.read(pRecipient(id).notifier).state = (
      address: "address0",
      amount: null,
      label: null,
    );

    expect(container.read(pRecipient(other)), isNull);
  });
}
