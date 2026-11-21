import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/pages/send_view/confirm_transaction_view.dart';
import 'package:stackwallet/pages/send_view/send_view.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_send.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/recoverable_prepared_send_interface.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';

import 'support/fake_wallets.dart';
import 'support/send_view_harness.dart';

void main() {
  testWidgets(
    'opening send resumes exact durable artifact and back discards it',
    (tester) async {
      final wallet = _RecoverableBitcoinWallet();

      await pumpSendView(
        tester,
        wallet: wallet,
        desktop: false,
        balance: testBalance('1', 8),
        view: SendView(walletId: wallet.walletId, coin: wallet.cryptoCurrency),
      );

      expect(wallet.recoveryRequests, 1);
      expect(find.byType(ConfirmTransactionView), findsOneWidget);
      expect(find.text('Confirm transaction'), findsOneWidget);
      expect(find.text(wallet.recipient), findsOneWidget);

      tester.view.physicalSize = const Size(900, 1700);
      await tester.pumpAndSettle();
      expect(wallet.recoveryRequests, 1);

      await tester.tap(find.byType(AppBarBackButton));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmTransactionView), findsNothing);
      expect(wallet.cancelled, same(wallet.recovered));
      expect(wallet.cancelRequests, 1);
    },
  );

  testWidgets(
    'opening desktop send resumes exact durable artifact in existing dialog',
    (tester) async {
      final wallet = _RecoverableBitcoinWallet();

      await pumpSendView(
        tester,
        wallet: wallet,
        desktop: true,
        balance: testBalance('1', 8),
        view: DesktopSend(walletId: wallet.walletId),
      );

      expect(wallet.recoveryRequests, 1);
      expect(find.byType(ConfirmTransactionView), findsOneWidget);
      expect(find.text('Confirm BTC transaction'), findsOneWidget);
      expect(find.text(wallet.recipient), findsOneWidget);

      tester.view.physicalSize = const Size(1500, 1100);
      await tester.pumpAndSettle();
      expect(wallet.recoveryRequests, 1);

      await tester.tap(find.byType(AppBarBackButton));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmTransactionView), findsNothing);
      expect(wallet.cancelled, same(wallet.recovered));
      expect(wallet.cancelRequests, 1);
    },
  );

  for (final desktop in [false, true]) {
    testWidgets(
      'ordinary wallet is unchanged on ${desktop ? 'desktop' : 'mobile'}',
      (tester) async {
        final wallet = FakeBitcoinWallet();
        await pumpSendView(
          tester,
          wallet: wallet,
          desktop: desktop,
          balance: testBalance('1', 8),
          view: desktop
              ? DesktopSend(walletId: wallet.walletId)
              : SendView(
                  walletId: wallet.walletId,
                  coin: wallet.cryptoCurrency,
                ),
        );

        expect(find.byType(ConfirmTransactionView), findsNothing);
      },
    );
  }

  testWidgets('failed recovery is contained and presents a generic error', (
    tester,
  ) async {
    final wallet = _RecoverableBitcoinWallet()
      ..recoveryError = StateError('sensitive persisted payload detail');

    await pumpSendView(
      tester,
      wallet: wallet,
      desktop: false,
      balance: testBalance('1', 8),
      view: SendView(walletId: wallet.walletId, coin: wallet.cryptoCurrency),
    );

    expect(wallet.recoveryRequests, 1);
    expect(find.text('Unable to resume transaction'), findsOneWidget);
    expect(
      find.textContaining('sensitive persisted payload detail'),
      findsNothing,
    );
  });

  testWidgets('failed desktop recovery uses the same generic error', (
    tester,
  ) async {
    final wallet = _RecoverableBitcoinWallet()
      ..recoveryError = StateError('sensitive persisted payload detail');

    await pumpSendView(
      tester,
      wallet: wallet,
      desktop: true,
      balance: testBalance('1', 8),
      view: DesktopSend(walletId: wallet.walletId),
    );

    expect(wallet.recoveryRequests, 1);
    expect(find.text('Unable to resume transaction'), findsOneWidget);
    expect(
      find.textContaining('sensitive persisted payload detail'),
      findsNothing,
    );
  });
}

final class _RecoverableBitcoinWallet extends FakeBitcoinWallet
    implements RecoverablePreparedSendWallet {
  @override
  String get walletId => 'bitcoin-recovery-flow';

  final recipient = btcAddress;
  late final recovered = TxData(
    raw: '00ff20',
    txid: '22' * 32,
    note: '',
    noteOnChain: '',
    fee: Amount(rawValue: BigInt.from(10000), fractionDigits: 8),
    recipients: [
      TxRecipient(
        address: recipient,
        amount: Amount(rawValue: BigInt.from(40000), fractionDigits: 8),
        isChange: false,
        addressType: AddressType.p2wpkh,
      ),
    ],
    vExtraData: Uint8List.fromList([1, 2, 3]),
  );

  int recoveryRequests = 0;
  int cancelRequests = 0;
  TxData? cancelled;
  Object? recoveryError;

  @override
  Future<FeeObject> get fees async => testFees;

  @override
  Future<Amount> estimateFeeFor(Amount amount, BigInt feeRate) async =>
      Amount(rawValue: BigInt.from(10000), fractionDigits: 8);

  @override
  bool get supportsMultiRecipient => true;

  @override
  Future<TxData?> recoverPreparedSend() async {
    recoveryRequests++;
    if (recoveryError case final error?) throw error;
    return recovered;
  }

  @override
  Future<void> cancelSend({required TxData txData}) async {
    cancelRequests++;
    cancelled = txData;
  }
}
