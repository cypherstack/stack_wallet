import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/v2/transaction_v2.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/pages/slatepack/verify_payment_proof_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/tx_v2/slatepack_tx_details.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/utilities/util.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/grin_fakes.dart';
import '../../wallets/support/xelis_test_fakes.dart';

class _DetailsWallet extends GrinTestWallet {
  _DetailsWallet(GrinHarness h)
    : super(
        testWalletId: h.walletId,
        backend: h.backend,
        tor: h.tor,
        bus: h.bus,
        secrets: h.secrets,
        testPrefs: h.prefs,
      );

  final reposted = <String>[];
  final exported = <String>[];

  @override
  Future<void> refresh() async {}

  @override
  Future<void> repost(String txid) async => reposted.add(txid);

  @override
  Future<String> exportPaymentProof(String txid) async {
    exported.add(txid);
    return '{"amount":1,"excess":"08ab"}';
  }

  @override
  Future<String?> pendingSlatepackFor(String txid) async =>
      'BEGINSLATEPACK. again ENDSLATEPACK.';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dataRoot;
  late Directory isarRoot;
  late Isar isar;
  late GrinHarness h;
  late _DetailsWallet wallet;

  setUpAll(() async => dataRoot = await setUpGrinTests());
  tearDownAll(() => dataRoot.delete(recursive: true));
  setUp(() async {
    isarRoot = await Directory.systemTemp.createTemp('stack_grin_isar_');
    isar = await openTestIsar(isarRoot);
    h = await GrinHarness.create();
    wallet = _DetailsWallet(h);
    await wallet.init();
  });
  tearDown(() async {
    try {
      await wallet.exit();
    } catch (_) {}
    await isar.close();
    await isarRoot.delete(recursive: true);
  });

  final tx = TransactionV2(
    walletId: 'w',
    blockHash: null,
    hash: '08ab',
    txid: 'slate-1',
    timestamp: 0,
    height: null,
    inputs: const [],
    outputs: const [],
    version: 0,
    type: TransactionType.outgoing,
    subType: TransactionSubType.none,
    otherData: null,
  );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
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
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  testWidgets('finalized, awaiting confirmation: rows and repost', (
    tester,
  ) async {
    await pump(
      tester,
      SlatepackTxDetails(
        wallet: wallet,
        transaction: tx,
        info: const SlatepackTxInfo(
          state: SlateState.s3,
          slateId: 'slate-1',
          kernelExcess: '08ab',
          counterpartyAddress: 'grin1friend',
          ttlCutoffHeight: 2500,
          finalizedAwaitingConfirmation: true,
          canRepost: true,
          hasPaymentProof: true,
        ),
      ),
    );
    expect(find.text('Finalized, awaiting confirmation'), findsOneWidget);
    expect(find.text('08ab'), findsOneWidget);
    expect(find.text('grin1friend'), findsOneWidget);
    expect(find.text('2500'), findsOneWidget);
    expect(find.textContaining('again'), findsNothing);

    await tester.tap(find.text('Repost'));
    await tester.pump(const Duration(milliseconds: 400));
    // Confirm in the dialog.
    await tester.tap(find.text('Repost').last);
    await settle(tester);
    expect(wallet.reposted, ['slate-1']);
  });

  testWidgets('a mined transaction does not show its expiry block', (
    tester,
  ) async {
    final mined = TransactionV2(
      walletId: 'w',
      blockHash: null,
      hash: '08ab',
      txid: 'slate-1',
      timestamp: 0,
      height: 1200,
      inputs: const [],
      outputs: const [],
      version: 0,
      type: TransactionType.outgoing,
      subType: TransactionSubType.none,
      otherData: null,
    );
    await pump(
      tester,
      SlatepackTxDetails(
        wallet: wallet,
        transaction: mined,
        info: const SlatepackTxInfo(
          state: SlateState.s3,
          slateId: 'slate-1',
          kernelExcess: '08ab',
          ttlCutoffHeight: 2500,
          hasPaymentProof: true,
        ),
      ),
    );
    expect(find.text('Expires at block'), findsNothing);
    expect(find.text('2500'), findsNothing);
    expect(find.text('08ab'), findsOneWidget);
  });

  testWidgets('a proof can be exported', (tester) async {
    await pump(
      tester,
      SlatepackTxDetails(
        wallet: wallet,
        transaction: tx,
        info: const SlatepackTxInfo(slateId: 'slate-1', hasPaymentProof: true),
      ),
    );
    expect(find.text('Repost'), findsNothing);
    await tester.tap(find.text('Export payment proof'));
    await settle(tester);
    expect(wallet.exported, ['slate-1']);
    expect(find.text('Payment proof'), findsOneWidget);
    expect(find.textContaining('"excess": "08ab"'), findsOneWidget);
  });

  testWidgets('repost and proof dialogs fit a 320px mobile screen', (
    tester,
  ) async {
    await pump(
      tester,
      SlatepackTxDetails(
        wallet: wallet,
        transaction: tx,
        info: const SlatepackTxInfo(
          slateId: 'slate-1',
          canRepost: true,
          hasPaymentProof: true,
        ),
      ),
      size: const Size(320, 640),
      mobile: true,
    );
    await tester.ensureVisible(find.text('Repost'));
    await tester.tap(find.text('Repost'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Later'));
    await tester.tap(find.text('Later'));
    await settle(tester);

    await tester.ensureVisible(find.text('Export payment proof'));
    await tester.tap(find.text('Export payment proof'));
    await settle(tester);
    expect(find.text('Payment proof'), findsOneWidget);
    await tester.ensureVisible(find.text('Save'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rows and proofs are copied through the given clipboard', (
    tester,
  ) async {
    final clipboard = FakeClipboard();
    await pump(
      tester,
      SlatepackTxDetails(
        wallet: wallet,
        transaction: tx,
        clipboard: clipboard,
        info: const SlatepackTxInfo(
          slateId: 'slate-1',
          kernelExcess: '08ab',
          hasPaymentProof: true,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Copy').first);
    await settle(tester);
    expect((await clipboard.getData('text/plain'))!.text, '08ab');
    // The notice is gone before the next step.
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);

    await tester.tap(find.text('Export payment proof'));
    await settle(tester);
    await tester.tap(find.text('Copy'));
    await settle(tester);
    expect(
      (await clipboard.getData('text/plain'))!.text,
      contains('"excess": "08ab"'),
    );
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);
  });

  group('what cancelling says', () {
    SlatepackCancelPrompt prompt(SlateState? state, {required bool incoming}) =>
        SlatepackCancelPrompt.of(
          state == null ? null : SlatepackTxInfo(state: state),
          incoming: incoming,
        );
    const ends = 'The other party can no longer complete it';

    test('a send or an invoice this wallet still has to finalize ends '
        'with the cancel', () {
      expect(prompt(SlateState.s1, incoming: false).message, contains(ends));
      expect(prompt(SlateState.i1, incoming: true).message, contains(ends));
      expect(prompt(null, incoming: false).message, contains(ends));
      expect(
        prompt(SlateState.s1, incoming: false).confirmLabel,
        'Yes, cancel',
      );
    });

    test('a paid invoice can still be completed by the payee', () {
      final p = prompt(SlateState.i2, incoming: false);
      expect(p.title, 'Cancel this transaction?');
      expect(p.message, isNot(contains(ends)));
      expect(p.message, contains('changes this wallet only'));
      expect(p.message, contains('they can still complete it'));
    });

    test('an answered payment can still be completed by the sender', () {
      for (final p in [
        prompt(SlateState.s2, incoming: true),
        // Wallets that keep no slate state answer what they receive.
        prompt(null, incoming: true),
        prompt(SlateState.unknown, incoming: true),
      ]) {
        expect(p.message, isNot(contains(ends)));
        expect(p.message, contains('this wallet only'));
        expect(p.message, contains('they can still complete the payment'));
      }
    });

    test('only pending Slatepack states are offered cancellation', () {
      for (final state in [
        SlateState.s1,
        SlateState.s2,
        SlateState.i1,
        SlateState.i2,
        SlateState.unknown,
      ]) {
        expect(SlatepackTxInfo(state: state).canCancel, isTrue);
      }
      expect(const SlatepackTxInfo(state: SlateState.s3).canCancel, isFalse);
      expect(const SlatepackTxInfo(state: SlateState.i3).canCancel, isFalse);
      expect(
        const SlatepackTxInfo(
          state: SlateState.s2,
          finalizedAwaitingConfirmation: true,
        ).canCancel,
        isFalse,
      );
      expect(
        const SlatepackTxInfo(
          state: SlateState.s3,
          finalizedAwaitingConfirmation: true,
          broadcastPosted: true,
        ).canCancel,
        isFalse,
      );
      expect(
        const SlatepackTxInfo(
          state: SlateState.s3,
          finalizedAwaitingConfirmation: true,
          broadcastPosted: false,
        ).canCancel,
        isTrue,
      );
    });

    test('a rejected finalized transaction explains safe cancellation', () {
      final prompt = SlatepackCancelPrompt.of(
        const SlatepackTxInfo(
          state: SlateState.s3,
          finalizedAwaitingConfirmation: true,
          broadcastPosted: false,
        ),
        incoming: false,
      );
      expect(prompt.message, contains('node did not accept'));
      expect(prompt.message, contains('can still confirm'));
    });
  });

  testWidgets('an S1 waiting for an answer can be shown again', (tester) async {
    await pump(
      tester,
      SlatepackTxDetails(
        wallet: wallet,
        transaction: tx,
        info: const SlatepackTxInfo(
          state: SlateState.s1,
          slateId: 'slate-1',
          canShowSlatepack: true,
        ),
      ),
    );
    await tester.tap(find.text('Show Slatepack again'));
    await settle(tester);
    expect(find.text('Send Slatepack'), findsOneWidget);
    expect(find.text('Not encrypted'), findsNothing);
    expect(find.text("Encrypted to the other party's address"), findsNothing);
  });

  testWidgets('verify shows the node caveat and both sides', (tester) async {
    await pump(tester, VerifyPaymentProofView(walletId: h.walletId));
    await tester.enterText(
      find.byType(TextField),
      '{"amount": 1000, "excess": "08ab", '
      '"recipient_address": "grin1recipient", '
      '"sender_address": "grin1ownaddress", '
      '"recipient_sig": "r", "sender_sig": "s"}',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('verifyPaymentProofButton')));
    await settle(tester);
    expect(h.backend.api.calls, contains('verifyPaymentProof'));
    expect(
      find.textContaining('Kernel presence as reported by your node'),
      findsOneWidget,
    );
    expect(find.text('grin1recipient'), findsOneWidget);
    expect(find.text('0.000001000 GRIN'), findsOneWidget);
  });
}
