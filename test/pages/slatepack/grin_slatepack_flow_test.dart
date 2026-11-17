import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grin_native/grin_native.dart';
import 'package:isar_community/isar.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/pages/slatepack/pay_invoice_confirm_view.dart';
import 'package:stackwallet/pages/pinpad_views/lock_screen_view.dart';
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
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';
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

  ({Amount amount, Amount fee, bool isSend, bool isCancelled})? local;
  bool repostable = false;
  final reposted = <String>[];
  var finalizeInvoiceCalls = 0;
  var finalizeSlatepackCalls = 0;
  FinalizeResult invoiceFinalizeResult = FinalizeResult(
    success: true,
    slateId: 'slate-x',
    posted: true,
  );
  FinalizeResult slateFinalizeResult = FinalizeResult(
    success: true,
    slateId: 'slate-x',
    posted: true,
  );

  /// What paying an invoice returns, if not the library's answer.
  SlatepackResult? payment;
  int paymentCalls = 0;

  /// What a cancel answers: "" or the failure.
  String cancelResult = '';
  final cancelled = <String>[];

  @override
  Future<void> refresh() async {}

  @override
  Future<({Amount amount, Amount fee, bool isSend, bool isCancelled})?>
  localTxForSlate(String slateId) async => local;

  @override
  Future<bool> canRepost(String txid) async => repostable;

  @override
  Future<void> repost(String txid) async => reposted.add(txid);

  @override
  Future<FinalizeResult> finalizeInvoice(String i2) async {
    finalizeInvoiceCalls++;
    return invoiceFinalizeResult;
  }

  @override
  Future<FinalizeResult> finalizeSlatepack(
    String s2, {
    SlateInspection? inspection,
  }) async {
    finalizeSlatepackCalls++;
    return slateFinalizeResult;
  }

  @override
  Future<SlatepackResult> processInvoice(
    String i1, {
    required Amount confirmedAmount,
  }) async {
    paymentCalls++;
    return payment ??
        SlatepackResult(
          success: true,
          slatepack: 'BEGINSLATEPACK. paid ENDSLATEPACK.',
          state: SlateState.i2,
          slateId: 'slate-i2',
          amount: confirmedAmount,
          fee: _grin(23500000),
        );
  }

  @override
  Future<String> cancelPendingTransactionAndPost(String slateId) async {
    cancelled.add(slateId);
    return cancelResult;
  }
}

class _FlowPrefs extends ConfirmationPrefs {
  @override
  bool get isInitialized => true;

  @override
  bool get autoPin => false;

  @override
  bool get useBiometrics => false;

  @override
  bool get randomizePIN => false;
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

  Future<void> runFlow(
    WidgetTester tester, {
    Size size = const Size(1400, 2000),
    bool mobile = false,
  }) async {
    final oldPlatform = Util.layoutPlatform;
    if (mobile) {
      Util.layoutPlatform = platform.FakePlatform(operatingSystem: 'android');
    }
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => Util.layoutPlatform = oldPlatform);
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
          prefsChangeNotifierProvider.overrideWithValue(_FlowPrefs()),
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

  testWidgets('an invoice created by this wallet cannot be paid here', (
    tester,
  ) async {
    wallet.local = (
      amount: _grin(5000),
      fee: _grin(0),
      isSend: false,
      isCancelled: false,
    );
    h.backend.api.decoded = decoded(GrinSlateState.i1, amount: 5000);

    await runFlow(tester);

    expect(find.text('Cannot pay this invoice'), findsOneWidget);
    expect(find.byType(PayInvoiceConfirmView), findsNothing);
    expect(h.backend.api.calls, isNot(contains('processInvoice')));
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  bool payEnabled(WidgetTester tester) => tester
      .widget<PrimaryButton>(find.byKey(const Key('payInvoiceButton')))
      .enabled;

  /// Opens the pay screen on an invoice the wallet can afford.
  Future<void> openInvoice(
    WidgetTester tester, {
    Size size = const Size(1400, 2000),
    bool mobile = false,
  }) async {
    spendable = 1000000000;
    h.backend.api.decoded = decoded(GrinSlateState.i1, amount: 5000);
    await runFlow(tester, size: size, mobile: mobile);
    expect(find.byType(PayInvoiceConfirmView), findsOneWidget);
  }

  /// Presses Pay and passes the unlock step.
  Future<void> pay(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('payInvoiceButton')));
    await settle(tester);
    final desktopAuth = find.byType(DesktopAuthSend);
    final auth = desktopAuth.evaluate().isNotEmpty
        ? desktopAuth
        : find.byType(LockscreenView);
    Navigator.of(tester.element(auth)).pop(true);
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
    expect(wallet.paymentCalls, 1);
    expect(find.text('Higher fee'), findsNothing);
    expect(find.byType(SlatepackDialog), findsOneWidget);
    expect(wallet.cancelled, isEmpty);
  });

  testWidgets('mobile waits for PIN dismissal before starting payment', (
    tester,
  ) async {
    await openInvoice(tester, mobile: true);
    await tester.tap(find.byKey(const Key('payInvoiceButton')));
    await settle(tester);
    final lock = find.byType(LockscreenView);
    expect(lock, findsOneWidget);

    Navigator.of(tester.element(lock)).pop(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LockscreenView), findsOneWidget);
    expect(find.byType(CustomLoadingOverlay), findsNothing);
    expect(wallet.paymentCalls, 0);

    await settle(tester);
    expect(find.byType(LockscreenView), findsNothing);
    expect(wallet.paymentCalls, 1);
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

  testWidgets('invoice and higher-fee UI fit a 320px mobile screen', (
    tester,
  ) async {
    wallet.payment = paidWith(fee: 30000000, slateId: 'slate-p');
    await openInvoice(tester, size: const Size(320, 640), mobile: true);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const Key('payInvoiceButton')));
    await pay(tester);
    expect(find.text('Higher fee'), findsOneWidget);
    await tester.ensureVisible(find.text('Cancel'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(wallet.cancelled, ['slate-p']);
  });

  testWidgets('leaving during the higher-fee question still cancels', (
    tester,
  ) async {
    wallet.payment = paidWith(fee: 30000000, slateId: 'slate-p');
    await openInvoice(tester);
    await pay(tester);
    expect(find.text('Higher fee'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await settle(tester);

    expect(wallet.cancelled, ['slate-p']);
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

  testWidgets('a payment that failed after the wallet recorded it closes the '
      'screen', (tester) async {
    wallet.payment = SlatepackResult(
      success: false,
      error: 'The payment failed. Open it in the transaction history.',
      slateId: 'slate-p',
    );
    await openInvoice(tester);
    await pay(tester);

    expect(find.text('Invoice payment failed'), findsOneWidget);
    expect(find.textContaining('transaction history'), findsOneWidget);
    expect(find.byType(SlatepackDialog), findsNothing);
    expect(wallet.cancelled, isEmpty);
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.byType(PayInvoiceConfirmView), findsNothing);
  });

  testWidgets('a payment that failed and left nothing keeps the screen', (
    tester,
  ) async {
    wallet.payment = SlatepackResult(success: false, error: 'No.');
    await openInvoice(tester);
    await pay(tester);

    expect(find.text('Invoice payment failed'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.byType(PayInvoiceConfirmView), findsOneWidget);
    expect(payEnabled(tester), isTrue);
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
    wallet.local = (
      amount: _grin(5000),
      fee: _grin(0),
      isSend: false,
      isCancelled: false,
    );
    await runFlow(tester);
    expect(find.text('Finalize invoice'), findsOneWidget);
    expect(find.text('0.000005000 GRIN'), findsOneWidget);
    await tester.tap(find.text('Finalize'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(wallet.finalizeInvoiceCalls, 1);
    expect(wallet.finalizeSlatepackCalls, 0);
  });

  testWidgets('a finalize the node refused offers repost', (tester) async {
    h.backend.api.decoded = decoded(GrinSlateState.s2);
    wallet.slateFinalizeResult = FinalizeResult(
      success: true,
      slateId: 'slate-x',
      posted: false,
    );
    wallet.local = (
      amount: _grin(5000),
      fee: _grin(100),
      isSend: true,
      isCancelled: false,
    );
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
