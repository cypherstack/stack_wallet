import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/receive_view/generate_receiving_uri_qr_code_view.dart';
import 'package:stackwallet/pages/send_view/frost_ms/recipient.dart';
import 'package:stackwallet/pages/send_view/send_memo_support.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/multi_recipient.dart';
import 'package:stackwallet/providers/global/locale_provider.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';
import 'package:stackwallet/widgets/qr.dart';

import '../../sample_data/theme_json.dart';

const _shielded =
    'zs1zt3mq96vp65l8ch54r78nc50ml68qsyg3pkteq8pn8sfgzakhgw4vqn6px5w08hrf2uzuam5kmj';
const _shielded2 =
    'u1tcw2tuatlzdc4ncep4nef7v9h5q87jx7t4fzyj7sw5g6775u3fwkucjafgsl2dg6h3hfj'
    'tml85ggqakl5mf2c746ygk7qnp8kyhentqkcnpqwarfcceczd0drzuvtxaeak9kadkwp6sn5x'
    'pj40cwmpjcu8aqy6v8rueum0h9mvefhhfytvrq2dcwxsx4cdk7uzv99yhspftg72ut509';

void main() {
  final coin = Zcash(CryptoCurrencyNetwork.main);
  final theme = StackTheme.fromJson(json: lightThemeJsonMap);
  const recipientId = (walletId: 'wallet', index: 1);
  late ProviderContainer container;

  void useLayout({required bool desktop}) {
    Util.layoutPlatform = platform.FakePlatform(
      operatingSystem: desktop ? 'linux' : 'android',
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
              locale: 'en_US',
              coin: coin,
              maxDecimals: coin.fractionDigits,
            ),
          ),
        ),
        localeServiceChangeNotifierProvider.overrideWithProvider(
          ChangeNotifierProvider((_) => LocaleService()),
        ),
        themeProvider.overrideWithValue(StateController(theme)),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        home: Scaffold(body: child),
      ),
    ),
  );

  test('converts known ZIP-321 amounts without losing metadata', () {
    final request = AddressUtils.parsePaymentUri(
      'zcash:?address=$_shielded&amount=1&memo=SGVsbG8&message=First&note=one'
      '&address.2=$_shielded2&amount.2=0.00000001&memo.2=AAE'
      '&message.2=Second&note.2=two',
      allowMultipleRecipients: true,
    )!;

    final recipients = parseUriRecipients(request, coin)!;
    expect(recipients.map((e) => e.address), [_shielded, _shielded2]);
    expect(recipients.map((e) => e.amount?.raw), [
      BigInt.from(100000000),
      BigInt.one,
    ]);
    expect(request.recipients.map((e) => e.memoText), [
      'Hello',
      '\u0000\u0001',
    ]);
    expect(request.recipients.map((e) => e.message), ['First', 'Second']);
    expect(recipients.map((e) => e.memoBytes), [
      [72, 101, 108, 108, 111],
      [0, 1],
    ]);
    expect(recipients.map((e) => e.message), ['First', 'Second']);
    final outputs = recipients.toTxRecipients(coin);
    expect(outputs.map((e) => e.memoBytes), [
      [72, 101, 108, 108, 111],
      [0, 1],
    ]);
    expect(outputs.map((e) => e.message), ['First', 'Second']);
    expect(outputs.map((e) => e.additionalParams), [
      {'note': 'one'},
      {'note': 'two'},
    ]);
  });

  test('preserves ordered repeated addresses with distinct memos', () {
    final request = AddressUtils.parsePaymentUri(
      'zcash:?address=$_shielded&amount=1&memo=AQ'
      '&address.1=$_shielded&amount.1=1&memo.1=Ag',
      allowMultipleRecipients: true,
    )!;

    final outputs = parseUriRecipients(request, coin)!.toTxRecipients(coin);
    expect(outputs.map((output) => output.address), [_shielded, _shielded]);
    expect(outputs.map((output) => output.amount.raw), [
      BigInt.from(100000000),
      BigInt.from(100000000),
    ]);
    expect(outputs.map((output) => output.memoBytes), [
      [1],
      [2],
    ]);
  });

  test('only maps a losslessly decoded single memo into the text field', () {
    final text = AddressUtils.parsePaymentUri('zcash:$_shielded?memo=SGVsbG8')!;
    final binary = AddressUtils.parsePaymentUri('zcash:$_shielded?memo=_w')!;
    final multi = AddressUtils.parsePaymentUri(
      'zcash:?address=$_shielded&memo=SGVsbG8&address.1=$_shielded2',
      allowMultipleRecipients: true,
    )!;

    expect(paymentUriMemoText(coin, text), 'Hello');
    expect(paymentUriMemoText(coin, binary), isNull);
    expect(paymentUriMemoText(coin, multi), isNull);
  });

  for (final desktop in [false, true]) {
    final layout = desktop ? 'desktop' : 'mobile';

    testWidgets('hands a multi-payment ZIP-321 request to $layout flow', (
      tester,
    ) async {
      useLayout(desktop: desktop);
      final requests = <PaymentUriData>[];
      await pump(
        tester,
        Recipient(
          walletId: recipientId.walletId,
          index: recipientId.index,
          displayNumber: 1,
          coin: coin,
          remove: () {},
          addAnotherRecipientTapped: () {},
          sendAllTapped: () => '',
          onMultiRecipientUri: requests.add,
          onMessage: (_) {},
        ),
      );

      await tester.enterText(
        find.byKey(const Key('sendViewAddressFieldKey')),
        'zcash:?address=$_shielded&amount=1&memo=SGVsbG8'
        '&address.2=$_shielded2&amount.2=2&message.2=Second',
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(requests.single.recipients, hasLength(2));
      expect(requests.single.recipients.first.memoText, 'Hello');
      expect(requests.single.recipients.last.message, 'Second');
    });

    testWidgets('generates a canonical ZIP-321 QR on $layout', (tester) async {
      useLayout(desktop: desktop);
      await tester.binding.setSurfaceSize(
        desktop ? const Size(1200, 900) : const Size(400, 800),
      );
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pump(
        tester,
        GenerateUriQrCodeView(coin: coin, receivingAddress: _shielded),
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '1.23000000');
      await tester.enterText(fields.at(1), 'For lunch');
      final generate = find.widgetWithText(PrimaryButton, 'Generate QR code');
      await tester.ensureVisible(generate);
      await tester.tap(generate);
      await tester.pumpAndSettle();

      final qr = tester.widget<QR>(find.byType(QR).last);
      expect(qr.data, 'zcash:$_shielded?amount=1.23&message=For%20lunch');
    });
  }
}
