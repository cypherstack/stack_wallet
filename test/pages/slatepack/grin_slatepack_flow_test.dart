import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grin/grin.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/slatepack/pay_invoice_confirm_view.dart';
import 'package:stackwallet/pages/slatepack/slatepack_import_flow.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/grin_fakes.dart';
import '../../wallets/support/xelis_test_fakes.dart';

Amount _grin(int nano) =>
    Amount(rawValue: BigInt.from(nano), fractionDigits: 9);

/// A Grin test wallet whose Isar reads and refreshes are canned, so the
/// flow can run inside a widget test.
class _FlowWallet extends GrinTestWallet {
  _FlowWallet(GrinHarness h)
    : super(
        testWalletId: h.walletId,
        backend: h.backend,
        tor: h.tor,
        bus: h.bus,
        secrets: h.secrets,
        testPrefs: h.prefs,
      );

  ({Amount amount, Amount fee})? local;
  bool repostable = false;
  final reposted = <String>[];

  @override
  Future<void> refresh() async {}

  @override
  Future<({Amount amount, Amount fee})?> localTxForSlate(
    String slateId,
  ) async => local;

  @override
  Future<bool> canRepost(String txid) async => repostable;

  @override
  Future<void> repost(String txid) async => reposted.add(txid);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dataRoot;
  late Directory isarRoot;
  late Isar isar;
  late GrinHarness h;
  late _FlowWallet wallet;

  setUpAll(() async => dataRoot = await setUpGrinTests());
  tearDownAll(() => dataRoot.delete(recursive: true));
  setUp(() async {
    isarRoot = await Directory.systemTemp.createTemp('stack_grin_isar_');
    isar = await openTestIsar(isarRoot);
    h = await GrinHarness.create();
    wallet = _FlowWallet(h);
    await wallet.init();
  });
  tearDown(() async {
    try {
      await wallet.exit();
    } catch (_) {}
    await isar.close();
    await isarRoot.delete(recursive: true);
  });

  GrinSlateInfo decoded(GrinSlateState state, {int amount = 0}) =>
      GrinSlateInfo(
        slateId: 'slate-x',
        state: state,
        amount: BigInt.from(amount),
        fee: BigInt.zero,
        kernelExcess: null,
        sender: 'grin1payee',
        recipients: const [],
        ttlCutoffHeight: null,
        numParticipants: 2,
        isEncrypted: false,
        slateJson: '{}',
      );

  Future<void> runFlow(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousThemesDir = StackFileSystem.themesDir;
    addTearDown(() => StackFileSystem.themesDir = previousThemesDir);
    StackFileSystem.themesDir = Directory('test/sample_data').absolute;

    final coin = wallet.cryptoCurrency;
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pWallets.overrideWithValue(ConfirmationWallets(wallet)),
          pWalletCoin(h.walletId).overrideWithValue(coin),
          pWalletBalance(h.walletId).overrideWithValue(
            Balance(
              total: _grin(100000),
              spendable: _grin(100000),
              blockedTotal: _grin(0),
              pendingSpendable: _grin(0),
            ),
          ),
          prefsChangeNotifierProvider.overrideWithValue(ConfirmationPrefs()),
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
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => SlatepackImportFlow.run(
                  context: context,
                  wallet: wallet,
                  text: 'BEGINSLATEPACK. x ENDSLATEPACK.',
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  testWidgets('Grin routes an I1 to the pay invoice screen', (tester) async {
    expect(wallet, isA<SlatepackInterface>());
    h.backend.api.decoded = decoded(GrinSlateState.i1, amount: 5000);
    await runFlow(tester);
    expect(find.byType(PayInvoiceConfirmView), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is SelectableText && w.data == '0.000005000 GRIN',
      ),
      findsOneWidget,
    );
    // The fee comes from the wallet's estimate; nothing is paid yet.
    expect(h.backend.api.calls, contains('estimateFee'));
    expect(h.backend.api.calls, isNot(contains('processInvoice')));
  });

  testWidgets('an I1 without an amount is refused', (tester) async {
    h.backend.api.decoded = decoded(GrinSlateState.i1);
    await runFlow(tester);
    expect(find.byType(PayInvoiceConfirmView), findsNothing);
    expect(
      find.text('This invoice does not say how much to pay.'),
      findsOneWidget,
    );
  });

  testWidgets('Grin finalizes an I2 with the issued invoice as summary', (
    tester,
  ) async {
    h.backend.api.decoded = decoded(GrinSlateState.i2);
    wallet.local = (amount: _grin(5000), fee: _grin(0));
    await runFlow(tester);
    expect(find.text('Finalize invoice'), findsOneWidget);
    expect(find.text('0.000005000 GRIN'), findsOneWidget);
    await tester.tap(find.text('Finalize'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(h.backend.api.calls, contains('finalizeInvoice'));
    expect(h.backend.api.calls, isNot(contains('finalizeSlatepack')));
  });

  testWidgets('a finalize the node refused offers repost', (tester) async {
    h.backend.api.decoded = decoded(GrinSlateState.s2);
    h.backend.api.finalizeError = grinError(
      9,
      details: {'slate_id': 'slate-x'},
    );
    wallet.local = (amount: _grin(5000), fee: _grin(100));
    await runFlow(tester);
    await tester.tap(find.text('Finalize'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find.text('Finalized, not broadcast'), findsOneWidget);
    await tester.tap(find.text('Repost'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(wallet.reposted, ['slate-x']);
  });

  testWidgets('an S3 with a stored transaction offers repost', (tester) async {
    h.backend.api.decoded = decoded(GrinSlateState.s3);
    wallet.repostable = true;
    await runFlow(tester);
    expect(find.text('Already finalized'), findsOneWidget);
    expect(find.text('Repost'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(wallet.reposted, isEmpty);
  });

  testWidgets('an S3 without a stored transaction is only a message', (
    tester,
  ) async {
    h.backend.api.decoded = decoded(GrinSlateState.s3);
    await runFlow(tester);
    expect(find.text('Already finalized'), findsOneWidget);
    expect(find.text('Repost'), findsNothing);
  });
}
