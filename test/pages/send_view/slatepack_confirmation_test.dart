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
  _Wallet() : super(CryptoCurrencyNetwork.main);
  int created = 0;
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
    return SlatepackResult(
      success: true,
      slatepack: '{}',
      slateId: 'slate-1',
      state: SlateState.s1,
    );
  }
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
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final previousThemes = StackFileSystem.themesDir;
      StackFileSystem.themesDir = Directory('test/sample_data').absolute;
      addTearDown(() => StackFileSystem.themesDir = previousThemes);
      final wallet = _Wallet();
      final coin = wallet.cryptoCurrency;
      final notes = _Notes(fail: failNote);
      final theme = StackTheme.fromJson(json: lightThemeJsonMap);
      var succeeded = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mainDBProvider.overrideWithValue(notes),
            pWallets.overrideWithValue(ConfirmationWallets(wallet)),
            pWalletCoin('wallet-1').overrideWithValue(coin),
            prefsChangeNotifierProvider.overrideWithValue(ConfirmationPrefs()),
            themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
            pAmountFormatter(coin).overrideWithValue(
              AmountFormatter(
                unit: AmountUnit.normal,
                locale: 'en_US',
                coin: coin,
                maxDecimals: coin.fractionDigits,
              ),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [StackColors.fromStackColorTheme(theme)],
            ),
            home: Scaffold(
              body: ConfirmTransactionView(
                walletId: 'wallet-1',
                onSuccess: () => succeeded = true,
                onSuccessInsteadOfRouteOnSuccess: () {},
                txData: TxData(
                  note: 'local note',
                  fee: Amount(rawValue: BigInt.one, fractionDigits: 8),
                  recipients: [
                    TxRecipient(
                      address: '',
                      amount: Amount(
                        rawValue: BigInt.from(100),
                        fractionDigits: 8,
                      ),
                      isChange: false,
                      addressType: AddressType.mimbleWimble,
                    ),
                  ],
                  otherData: slatepackMethodOtherData(
                    SlatepackMethod.slatepack,
                  ),
                ),
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
}
