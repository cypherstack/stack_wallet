import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/transaction_note.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/models/slatepack_models.dart';
import 'package:stackwallet/pages/send_view/confirm_transaction_view.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/sending_transaction_dialog.dart';
import 'package:stackwallet/pages/slatepack/slatepack_dialog.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_auth_send.dart';
import 'package:stackwallet/providers/db/main_db_provider.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/enums/slatepack_method.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/epiccash_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/slatepack_interface.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/xelis_test_fakes.dart';

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

  /// What the created slate reports, in raw units.
  final int? createdAmount;
  final int? createdFee;

  final String? createError;
  final String cancelResult;

  /// When set, creation waits for it.
  final Completer<void>? gate;

  int created = 0;
  final cancelled = <String>[];

  @override
  WalletInfo get info => _Info(cryptoCurrency);
  @override
  Future<void> refresh({bool doScan = true}) async {}
  @override
  Future<SlatepackResult> createSlatepack({
    required Amount amount,
    String? recipientAddress,
    String? message,
    bool sendAll = false,
  }) async {
    created++;
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

/// Outlasts the minimum time the sending dialog is meant to stay up.
const _sendTimer = Duration(seconds: 3);

Amount _amount(int raw) =>
    Amount(rawValue: BigInt.from(raw), fractionDigits: 8);

AmountFormatter _formatter(CryptoCurrency coin) => AmountFormatter(
  unit: AmountUnit.normal,
  locale: 'en_US',
  coin: coin,
  maxDecimals: coin.fractionDigits,
);

/// Pumps the confirmation of a slate send of 100 with a fee of 1 and presses
/// Send. [shown] takes the view off screen when set to false.
Future<void> _confirmSend(
  WidgetTester tester,
  _Wallet wallet, {
  MainDB? db,
  void Function()? onSuccess,
  ValueNotifier<bool>? shown,
}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final previousThemes = StackFileSystem.themesDir;
  StackFileSystem.themesDir = Directory('test/sample_data').absolute;
  addTearDown(() => StackFileSystem.themesDir = previousThemes);
  final coin = wallet.cryptoCurrency;
  final theme = StackTheme.fromJson(json: lightThemeJsonMap);
  final view = ConfirmTransactionView(
    walletId: 'wallet-1',
    onSuccess: onSuccess ?? () {},
    onSuccessInsteadOfRouteOnSuccess: () {},
    txData: TxData(
      note: 'local note',
      fee: _amount(1),
      recipients: [
        TxRecipient(
          address: '',
          amount: _amount(100),
          isChange: false,
          addressType: AddressType.mimbleWimble,
        ),
      ],
      otherData: slatepackMethodOtherData(SlatepackMethod.slatepack),
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mainDBProvider.overrideWithValue(db ?? _Notes(fail: false)),
        pWallets.overrideWithValue(ConfirmationWallets(wallet)),
        pWalletCoin('wallet-1').overrideWithValue(coin),
        prefsChangeNotifierProvider.overrideWithValue(ConfirmationPrefs()),
        themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
        pAmountFormatter(coin).overrideWithValue(_formatter(coin)),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        home: Scaffold(
          body: shown == null
              ? view
              : ValueListenableBuilder(
                  valueListenable: shown,
                  builder: (_, isShown, _) => isShown ? view : const SizedBox(),
                ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Send'));
  await tester.tap(find.text('Send'));
  await tester.pumpAndSettle();
  Navigator.of(tester.element(find.byType(DesktopAuthSend))).pop(true);
}

class _Notes extends Fake implements MainDB {
  _Notes({required this.fail});
  final bool fail;
  final notes = <TransactionNote>[];
  @override
  Future<void> putTransactionNote(TransactionNote note) async {
    if (fail) throw StateError('note unavailable');
    notes.add(note);
  }
}

void main() {
  for (final failNote in [false, true]) {
    testWidgets('slate send keeps its result with note failure=$failNote', (
      tester,
    ) async {
      final wallet = _Wallet();
      final notes = _Notes(fail: failNote);
      var succeeded = false;
      await _confirmSend(
        tester,
        wallet,
        db: notes,
        onSuccess: () => succeeded = true,
      );
      await tester.pumpAndSettle();
      expect(wallet.created, 1);
      expect(find.byType(SlatepackDialog), findsOneWidget);
      if (!failNote) {
        expect(notes.notes, hasLength(1));
        expect(notes.notes.single.walletId, 'wallet-1');
        expect(notes.notes.single.txid, 'slate-1');
        expect(notes.notes.single.value, 'local note');
      } else {
        expect(notes.notes, isEmpty);
      }
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(succeeded, isTrue);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    });
  }

  for (final cancelResult in ['', 'node unreachable']) {
    testWidgets('a slate for another amount is cancelled and refused, cancel '
        'result "$cancelResult"', (tester) async {
      final wallet = _Wallet(createdAmount: 90, cancelResult: cancelResult);
      final format = _formatter(wallet.cryptoCurrency).format;
      final notes = _Notes(fail: false);
      var succeeded = false;
      await _confirmSend(
        tester,
        wallet,
        db: notes,
        onSuccess: () => succeeded = true,
      );
      await tester.pumpAndSettle();

      expect(wallet.cancelled, ['slate-1']);
      expect(find.byType(SlatepackDialog), findsNothing);
      expect(find.byType(SendingTransactionDialog), findsNothing);
      expect(find.text('Could not create the slate'), findsOneWidget);
      expect(
        find.textContaining(
          'created for ${format(_amount(90))} instead of the confirmed '
          '${format(_amount(100))}',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          cancelResult.isEmpty
              ? 'The transaction was cancelled.'
              : 'could not be cancelled (node unreachable)',
        ),
        findsOneWidget,
      );
      expect(notes.notes, isEmpty);
      expect(succeeded, isFalse);
      await tester.pump(_sendTimer);
    });
  }

  testWidgets('a slate with another fee is shown with a warning', (
    tester,
  ) async {
    final wallet = _Wallet(createdAmount: 100, createdFee: 3);
    final format = _formatter(wallet.cryptoCurrency).format;
    await _confirmSend(tester, wallet);
    await tester.pumpAndSettle();

    expect(wallet.cancelled, isEmpty);
    expect(find.byType(SlatepackDialog), findsOneWidget);
    expect(
      find.textContaining(
        'fee of ${format(_amount(3))} instead of the estimated '
        '${format(_amount(1))}',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('a slate matching the confirmation is shown without a warning', (
    tester,
  ) async {
    final wallet = _Wallet(createdAmount: 100, createdFee: 1);
    await _confirmSend(tester, wallet);
    await tester.pumpAndSettle();

    expect(wallet.cancelled, isEmpty);
    expect(find.byType(SlatepackDialog), findsOneWidget);
    expect(find.textContaining('instead of'), findsNothing);
    await tester.pump(_sendTimer);
  });

  testWidgets('a failed creation is not called a broadcast failure', (
    tester,
  ) async {
    final wallet = _Wallet(createError: 'not enough funds');
    await _confirmSend(tester, wallet);
    await tester.pumpAndSettle();

    expect(find.text('Could not create the slate'), findsOneWidget);
    expect(find.text('Broadcast transaction failed'), findsNothing);
    expect(find.textContaining('not enough funds'), findsOneWidget);
    expect(find.byType(SendingTransactionDialog), findsNothing);
    expect(wallet.cancelled, isEmpty);
    await tester.pump(_sendTimer);
  });

  testWidgets('the sending dialog closes when the view is gone before the '
      'slate is created', (tester) async {
    final gate = Completer<void>();
    final wallet = _Wallet(gate: gate);
    final shown = ValueNotifier(true);
    addTearDown(shown.dispose);
    var succeeded = false;
    await _confirmSend(
      tester,
      wallet,
      shown: shown,
      onSuccess: () => succeeded = true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SendingTransactionDialog), findsOneWidget);

    shown.value = false;
    await tester.pump();
    expect(find.byType(ConfirmTransactionView), findsNothing);

    gate.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SendingTransactionDialog), findsNothing);
    expect(find.byType(SlatepackDialog), findsNothing);
    expect(succeeded, isTrue);
    await tester.pump(_sendTimer);
    expect(tester.takeException(), isNull);
  });
}
