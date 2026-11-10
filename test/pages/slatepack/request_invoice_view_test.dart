import 'dart:io';

import 'package:stackwallet/pages/slatepack/request_invoice_view.dart';
import 'package:stackwallet/providers/global/price_provider.dart';
import 'package:stackwallet/services/price_service.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/grin_fakes.dart';
import '../../wallets/support/xelis_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dataRoot;
  late Directory isarRoot;
  late Isar isar;
  late GrinHarness h;

  setUpAll(() async => dataRoot = await setUpGrinTests());
  tearDownAll(() => dataRoot.delete(recursive: true));
  setUp(() async {
    isarRoot = await Directory.systemTemp.createTemp('stack_grin_isar_');
    isar = await openTestIsar(isarRoot);
    h = await GrinHarness.create();
    await h.wallet.init();
  });
  tearDown(() async {
    try {
      await h.dispose();
    } catch (_) {}
    await isar.close();
    await isarRoot.delete(recursive: true);
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousThemesDir = StackFileSystem.themesDir;
    addTearDown(() => StackFileSystem.themesDir = previousThemesDir);
    StackFileSystem.themesDir = Directory('test/sample_data').absolute;
    final coin = h.wallet.cryptoCurrency;
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(ConfirmationWallets(h.wallet)),
          prefsChangeNotifierProvider.overrideWithValue(ConfirmationPrefs()),
          priceAnd24hChangeNotifierProvider.overrideWithValue(
            PriceService('USD'),
          ),
          themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
          pAmountFormatter(coin).overrideWithValue(
            AmountFormatter(
              unit: AmountUnit.normal,
              locale: 'en_US',
              coin: coin,
              maxDecimals: 9,
            ),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('invoice address edits update the create button', (tester) async {
    await pump(tester, RequestInvoiceView(walletId: h.walletId));
    await tester.enterText(
      find.byKey(const Key('slatepackRecipientFieldKey')),
      'invalid',
    );
    await tester.enterText(find.byKey(const Key('requestInvoiceAmount')), '1');
    await tester.pump();
    expect(
      tester
          .widget<PrimaryButton>(find.byKey(const Key('requestInvoiceCreate')))
          .enabled,
      isFalse,
    );
    await tester.enterText(
      find.byKey(const Key('slatepackRecipientFieldKey')),
      '',
    );
    await tester.pump();
    expect(
      tester
          .widget<PrimaryButton>(find.byKey(const Key('requestInvoiceCreate')))
          .enabled,
      isTrue,
    );
  });

  testWidgets('invoice address edits disable the create button', (
    tester,
  ) async {
    await pump(tester, RequestInvoiceView(walletId: h.walletId));
    await tester.enterText(find.byKey(const Key('requestInvoiceAmount')), '1');
    await tester.pump();
    expect(
      tester
          .widget<PrimaryButton>(find.byKey(const Key('requestInvoiceCreate')))
          .enabled,
      isTrue,
    );
    await tester.enterText(
      find.byKey(const Key('slatepackRecipientFieldKey')),
      'invalid',
    );
    await tester.pump();
    expect(
      tester
          .widget<PrimaryButton>(find.byKey(const Key('requestInvoiceCreate')))
          .enabled,
      isFalse,
    );
  });
  testWidgets('invoice payer accepts only a slatepack address', (tester) async {
    await pump(tester, RequestInvoiceView(walletId: h.walletId));
    await tester.enterText(find.byKey(const Key('requestInvoiceAmount')), '1');
    for (final address in ['https://payer.example', 'http://payer.onion']) {
      await tester.enterText(
        find.byKey(const Key('slatepackRecipientFieldKey')),
        address,
      );
      await tester.pump();
      expect(
        tester
            .widget<PrimaryButton>(
              find.byKey(const Key('requestInvoiceCreate')),
            )
            .enabled,
        isFalse,
      );
    }
    await tester.enterText(
      find.byKey(const Key('slatepackRecipientFieldKey')),
      'grin1payer',
    );
    await tester.pump();
    expect(
      tester
          .widget<PrimaryButton>(find.byKey(const Key('requestInvoiceCreate')))
          .enabled,
      isTrue,
    );
  });
}
