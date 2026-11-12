import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grin/grin.dart';
import 'package:isar_community/isar.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/pages/slatepack/pay_invoice_confirm_view.dart';
import 'package:stackwallet/pages/slatepack/slatepack_dialog.dart';
import 'package:stackwallet/pages/slatepack/slatepack_import_flow.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_auth_send.dart';
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
import 'package:stackwallet/widgets/desktop/primary_button.dart';

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

  ({Amount amount, Amount fee, bool isSend})? local;
  bool repostable = false;
  final reposted = <String>[];

  /// What paying an invoice returns, if not the library's answer.
  SlatepackResult? payment;

  /// What a cancel answers: "" or the failure.
  String cancelResult = '';
  final cancelled = <String>[];

  @override
  Future<void> refresh() async {}

  @override
  Future<({Amount amount, Amount fee, bool isSend})?> localTxForSlate(
    String slateId,
  ) async => local;

  @override
  Future<bool> canRepost(String txid) async => repostable;

  @override
  Future<void> repost(String txid) async => reposted.add(txid);

  @override
  Future<SlatepackResult> processInvoice(
    String i1, {
    required Amount confirmedAmount,
  }) async =>
      payment ??
      await super.processInvoice(i1, confirmedAmount: confirmedAmount);

  @override
  Future<String> cancelPendingTransactionAndPost(String slateId) async {
    cancelled.add(slateId);
    return cancelResult;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dataRoot;
  late Directory isarRoot;
  late Isar isar;
  late GrinHarness h;
  late _FlowWallet wallet;
  var spendable = 100000;

  setUpAll(() async => dataRoot = await setUpGrinTests());
  tearDownAll(() => dataRoot.delete(recursive: true));
  setUp(() async {
    isarRoot = await Directory.systemTemp.createTemp('stack_grin_isar_');
    isar = await openTestIsar(isarRoot);
    h = await GrinHarness.create();
    spendable = 100000;
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
              total: _grin(spendable),
              spendable: _grin(spendable),
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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  bool payEnabled(WidgetTester tester) => tester
      .widget<PrimaryButton>(find.byKey(const Key('payInvoiceButton')))
      .enabled;

  /// Opens the pay screen on an invoice the wallet can afford.
  Future<void> openInvoice(WidgetTester tester) async {
    spendable = 1000000000;
    h.backend.api.decoded = decoded(GrinSlateState.i1, amount: 5000);
    await runFlow(tester);
    expect(find.byType(PayInvoiceConfirmView), findsOneWidget);
  }

  /// Presses Pay and passes the unlock step.
  Future<void> pay(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('payInvoiceButton')));
    await settle(tester);
    Navigator.of(tester.element(find.byType(DesktopAuthSend))).pop(true);
    await settle(tester);
  }

  SlatepackResult paidWith({required int fee, String? slateId}) =>
      SlatepackResult(
        success: true,
        slatepack: 'BEGINSLATEPACK. paid ENDSLATEPACK.',
        state: SlateState.i2,
        slateId: slateId,
        amount: _grin(5000),
        fee: _grin(fee),
      );

  testWidgets('a failed fee estimate can be tried again', (tester) async {
    h.backend.api.estimateError = grinError(9);
    await openInvoice(tester);
    expect(find.text('Could not estimate'), findsOneWidget);
    expect(find.byKey(const Key('payInvoiceButton')), findsNothing);

    h.backend.api.estimateError = null;
    await tester.tap(find.byKey(const Key('payInvoiceRetryEstimate')));
    await settle(tester);
    expect(find.text('Could not estimate'), findsNothing);
    expect(find.byKey(const Key('payInvoiceRetryEstimate')), findsNothing);
    expect(payEnabled(tester), isTrue);
  });

  testWidgets('paying at the estimated fee shows the payment Slatepack', (
    tester,
  ) async {
    await openInvoice(tester);
    await pay(tester);
    expect(h.backend.api.calls, contains('processInvoice'));
    expect(find.text('Higher fee'), findsNothing);
    expect(find.byType(SlatepackDialog), findsOneWidget);
    expect(wallet.cancelled, isEmpty);
  });

  testWidgets('declining a higher fee cancels the payment', (tester) async {
    wallet.payment = paidWith(fee: 30000000, slateId: 'slate-p');
    await openInvoice(tester);
    await pay(tester);
    expect(find.text('Higher fee'), findsOneWidget);
    await tester.tap(find.text('Cancel payment'));
    await settle(tester);

    expect(wallet.cancelled, ['slate-p']);
    expect(find.byType(SlatepackDialog), findsNothing);
    expect(find.text('Payment cancelled'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.byType(PayInvoiceConfirmView), findsNothing);
  });

  for (final slateId in [null, 'slate-p']) {
    testWidgets('a payment that could not be cancelled closes the screen and '
        'points at the transaction details, slate id $slateId', (tester) async {
      wallet.payment = paidWith(fee: 30000000, slateId: slateId);
      wallet.cancelResult = 'The node did not answer.';
      await openInvoice(tester);
      await pay(tester);
      await tester.tap(find.text('Cancel payment'));
      await settle(tester);

      expect(wallet.cancelled, slateId == null ? isEmpty : ['slate-p']);
      expect(find.text('Cancel failed'), findsOneWidget);
      expect(
        find.textContaining(
          slateId == null
              ? 'Could not cancel automatically.'
              : 'The node did not answer.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Cancel the payment from the transaction details'),
        findsOneWidget,
      );
      await tester.tap(find.text('OK'));
      await settle(tester);
      // Paying again from here would be a second payment.
      expect(find.byType(PayInvoiceConfirmView), findsNothing);
    });
  }

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
    wallet.local = (amount: _grin(5000), fee: _grin(0), isSend: false);
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
      details: {'slate_id': 'slate-x', 'finalized': true},
    );
    wallet.local = (amount: _grin(5000), fee: _grin(100), isSend: true);
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
