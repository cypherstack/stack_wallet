import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/transaction_note.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/pages/slatepack/slatepack_dialog.dart';
import 'package:stackwallet/pages/slatepack/slatepack_send_flow.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/mimblewimblecoin_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';

import '../../sample_data/theme_json.dart';

class _Info extends Fake implements WalletInfo {
  _Info(this.coin);

  @override
  final CryptoCurrency coin;
}

class _Wallet extends EpiccashWallet {
  _Wallet({
    this.createdAmount,
    this.createdFee,
    this.createError,
    this.cancelResult = '',
    this.gate,
  }) : super(CryptoCurrencyNetwork.main);

  final int? createdAmount;
  final int? createdFee;
  final String? createError;
  final String cancelResult;
  final Completer<void>? gate;

  int created = 0;
  int refreshed = 0;
  final cancelled = <String>[];
  Amount? requestedAmount;
  String? requestedRecipient;
  bool? requestedSendAll;

  @override
  String get walletId => 'wallet-1';

  @override
  WalletInfo get info => _Info(cryptoCurrency);

  @override
  Future<void> refresh({bool doScan = true}) async {
    refreshed++;
  }

  @override
  Future<SlatepackResult> createSlatepack({
    required Amount amount,
    String? recipientAddress,
    String? message,
    bool sendAll = false,
  }) async {
    created++;
    requestedAmount = amount;
    requestedRecipient = recipientAddress;
    requestedSendAll = sendAll;
    await gate?.future;
    if (createError != null) {
      return SlatepackResult(success: false, error: createError);
    }
    return SlatepackResult(
      success: true,
      slatepack: '{}',
      slateId: 'slate-1',
      state: SlateState.s1,
      amount: createdAmount == null ? null : _amount(createdAmount!),
      fee: createdFee == null ? null : _amount(createdFee!),
    );
  }

  @override
  Future<String> cancelPendingTransactionAndPost(String txSlateId) async {
    cancelled.add(txSlateId);
    return cancelResult;
  }
}

class _SynchronousMwcWallet extends MimblewimblecoinWallet {
  _SynchronousMwcWallet({required this.onCreate, required this.gate})
    : super(CryptoCurrencyNetwork.main);

  final VoidCallback onCreate;
  final Completer<void> gate;

  @override
  String get walletId => 'wallet-1';

  @override
  WalletInfo get info => _Info(cryptoCurrency);

  @override
  Future<SlatepackResult> createSlatepack({
    required Amount amount,
    String? recipientAddress,
    String? message,
    bool sendAll = false,
  }) async {
    onCreate();
    await gate.future;
    return SlatepackResult(
      success: true,
      slatepack: 'BEGINSLATEPACK. test. ENDSLATEPACK.',
      slateId: 'mwc-slate-1',
      state: SlateState.s1,
      amount: amount,
      fee: _amount(1),
    );
  }
}

class _Notes extends Fake implements MainDB {
  _Notes({this.fail = false});

  final bool fail;
  final notes = <TransactionNote>[];

  @override
  Future<void> putTransactionNote(TransactionNote note) async {
    if (fail) throw StateError('note unavailable');
    notes.add(note);
  }
}

Amount _amount(int raw) =>
    Amount(rawValue: BigInt.from(raw), fractionDigits: 8);

AmountFormatter _formatter(CryptoCurrency coin) => AmountFormatter(
  unit: AmountUnit.normal,
  locale: 'en_US',
  coin: coin,
  maxDecimals: coin.fractionDigits,
);

Future<ValueNotifier<bool>> _pumpSend(
  WidgetTester tester,
  SlatepackInterface wallet, {
  MainDB? db,
  Amount? creationAmount,
  String? recipientAddress,
  bool sendAll = false,
}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final previousThemes = StackFileSystem.themesDir;
  StackFileSystem.themesDir = Directory('test/sample_data').absolute;
  addTearDown(() => StackFileSystem.themesDir = previousThemes);

  final succeeded = ValueNotifier(false);
  addTearDown(succeeded.dispose);
  final theme = StackTheme.fromJson(json: lightThemeJsonMap);
  final format = _formatter(wallet.cryptoCurrency).format;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themeProvider.overrideWithProvider(StateProvider((_) => theme)),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const Key('createSlate'),
              onPressed: () {
                unawaited(
                  SlatepackSendFlow.run(
                    context: context,
                    wallet: wallet,
                    amount: _amount(100),
                    creationAmount: creationAmount,
                    recipientAddress: recipientAddress,
                    sendAll: sendAll,
                    message: 'on-chain note',
                    localNote: 'local note',
                    db: db ?? _Notes(),
                    format: format,
                  ).then((value) => succeeded.value = value),
                );
              },
              child: const Text('Create'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('createSlate')));
  await tester.pump();
  return succeeded;
}

void main() {
  testWidgets('creation options are forwarded but the confirmed amount is '
      'still checked', (tester) async {
    final wallet = _Wallet(createdAmount: 100, createdFee: 1);

    await _pumpSend(
      tester,
      wallet,
      creationAmount: _amount(110),
      recipientAddress: 'grin1recipient',
      sendAll: true,
    );
    await tester.pumpAndSettle();

    expect(wallet.requestedAmount, _amount(110));
    expect(wallet.requestedRecipient, 'grin1recipient');
    expect(wallet.requestedSendAll, isTrue);
    expect(find.byType(SlatepackDialog), findsOneWidget);
  });

  testWidgets('native creation starts after the progress route is visible', (
    tester,
  ) async {
    double? routeOpacity;
    final gate = Completer<void>();
    late final _SynchronousMwcWallet wallet;
    wallet = _SynchronousMwcWallet(
      gate: gate,
      onCreate: () {
        final overlays = find.byType(CustomLoadingOverlay).evaluate();
        routeOpacity = overlays.isEmpty
            ? -1
            : ModalRoute.of(overlays.single)!.animation!.value;
      },
    );

    await _pumpSend(tester, wallet);
    for (var i = 0; i < 10 && routeOpacity == null; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(routeOpacity, 1);
    expect(find.text('Building slatepack...'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(SlatepackDialog), findsOneWidget);
  });

  testWidgets(
    'the result shows the actual fee, saves its note and never refreshes',
    (tester) async {
      final wallet = _Wallet(createdAmount: 100, createdFee: 3);
      final notes = _Notes();
      final succeeded = await _pumpSend(tester, wallet, db: notes);
      await tester.pumpAndSettle();

      final format = _formatter(wallet.cryptoCurrency).format;
      final dialog = find.byType(SlatepackDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text(format(_amount(3)))),
        findsOneWidget,
      );
      expect(notes.notes.single.txid, 'slate-1');
      expect(notes.notes.single.value, 'local note');
      expect(wallet.refreshed, 0);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(succeeded.value, isTrue);
    },
  );

  testWidgets('a local-note failure does not hide the created slate', (
    tester,
  ) async {
    final wallet = _Wallet(createdAmount: 100, createdFee: 3);
    await _pumpSend(tester, wallet, db: _Notes(fail: true));
    await tester.pumpAndSettle();

    expect(find.byType(SlatepackDialog), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'The transaction was created successfully, but its local '
        'note could not be saved.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a slate for another amount is cancelled and not shown', (
    tester,
  ) async {
    final wallet = _Wallet(createdAmount: 90, createdFee: 1);
    final succeeded = await _pumpSend(tester, wallet);
    await tester.pumpAndSettle();

    expect(wallet.cancelled, ['slate-1']);
    expect(find.byType(SlatepackDialog), findsNothing);
    expect(find.text('Could not create the slate'), findsOneWidget);
    expect(find.textContaining('instead of the requested'), findsOneWidget);
    expect(succeeded.value, isFalse);
  });

  testWidgets('a failed cancellation is reported after an amount mismatch', (
    tester,
  ) async {
    final wallet = _Wallet(
      createdAmount: 90,
      createdFee: 1,
      cancelResult: 'wallet busy',
    );
    await _pumpSend(tester, wallet);
    await tester.pumpAndSettle();

    expect(wallet.cancelled, ['slate-1']);
    expect(find.textContaining('wallet busy'), findsOneWidget);
    expect(find.textContaining('Cancel it from its details'), findsOneWidget);
  });

  testWidgets('an incomplete native result is cancelled and not shown', (
    tester,
  ) async {
    final wallet = _Wallet();
    final succeeded = await _pumpSend(tester, wallet);
    await tester.pumpAndSettle();

    expect(wallet.cancelled, ['slate-1']);
    expect(find.byType(SlatepackDialog), findsNothing);
    expect(find.text('Could not create the slate'), findsOneWidget);
    expect(find.textContaining('complete amount'), findsOneWidget);
    expect(succeeded.value, isFalse);
  });

  testWidgets('a native error is shown without an exception prefix', (
    tester,
  ) async {
    final wallet = _Wallet(createError: 'Exception: wallet is locked');
    await _pumpSend(tester, wallet);
    await tester.pumpAndSettle();

    expect(find.text('wallet is locked'), findsOneWidget);
    expect(find.textContaining('Exception:'), findsNothing);
    expect(wallet.cancelled, isEmpty);
  });

  testWidgets('a completed slate waits below an intervening lock route', (
    tester,
  ) async {
    final gate = Completer<void>();
    final wallet = _Wallet(gate: gate, createdAmount: 100, createdFee: 1);
    await _pumpSend(tester, wallet);
    await tester.pump(const Duration(milliseconds: 500));

    final root = Navigator.of(
      tester.element(find.byType(CustomLoadingOverlay)),
      rootNavigator: true,
    );
    unawaited(
      root.push(
        MaterialPageRoute<void>(builder: (_) => const Text('lock route')),
      ),
    );
    await tester.pumpAndSettle();

    gate.complete();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('lock route'), findsOneWidget);
    expect(find.byType(SlatepackDialog), findsNothing);

    root.pop();
    await tester.pumpAndSettle();
    expect(find.byType(SlatepackDialog), findsOneWidget);
  });
}
