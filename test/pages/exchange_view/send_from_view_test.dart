import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/exchange_view/send_from_view.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/building_transaction_dialog.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/impl/firo_wallet.dart';

import '../../sample_data/theme_json.dart';

void main() {
  for (final desktop in [false, true]) {
    testWidgets(
      '${desktop ? 'desktop' : 'mobile'} cancellation permits a new build '
      'without losing its guard',
      (tester) async {
        final previousPlatform = Util.layoutPlatform;
        final previousWidth = Util.screenWidth;
        final previousIsIpad = Util.isIpad;
        final previousThemesDir = StackFileSystem.themesDir;
        addTearDown(() {
          Util.layoutPlatform = previousPlatform;
          Util.screenWidth = previousWidth;
          Util.isIpad = previousIsIpad;
          StackFileSystem.themesDir = previousThemesDir;
        });
        Util.layoutPlatform = platform.FakePlatform(
          operatingSystem: desktop ? 'macos' : 'android',
        );
        Util.screenWidth = desktop ? 1200 : 600;
        Util.isIpad = false;
        StackFileSystem.themesDir = Directory('test/sample_data').absolute;
        await tester.binding.setSurfaceSize(const Size(1200, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final wallet = _FiroWallet();
        final coin = wallet.cryptoCurrency;
        final balance = Balance.zeroFor(currency: coin);
        final theme = StackTheme.fromJson(json: lightThemeJsonMap);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              pWallets.overrideWithValue(_Wallets(wallet)),
              pWalletCoin('test').overrideWithValue(coin),
              pWalletName('test').overrideWithValue('Test FIRO wallet'),
              pWalletBalance('test').overrideWithValue(balance),
              pWalletBalanceTertiary('test').overrideWithValue(balance),
              themeProvider.overrideWithValue(StateController(theme)),
              pAmountFormatter(coin).overrideWithValue(
                AmountFormatter(
                  unit: AmountUnit.normal,
                  locale: 'en_US',
                  coin: coin,
                  maxDecimals: 8,
                ),
              ),
            ],
            child: MaterialApp(
              theme: ThemeData(
                extensions: [StackColors.fromStackColorTheme(theme)],
              ),
              home: Scaffold(
                body: SendFromCard(
                  walletId: 'test',
                  amount: Amount(rawValue: BigInt.one, fractionDigits: 8),
                  address: _address,
                  trade: _trade(),
                ),
              ),
            ),
          ),
        );
        final publicButton = find.byKey(
          const Key('walletsSheetItemButtonFiroPublicKey_test'),
        );
        try {
          await tester.tap(find.text('Test FIRO wallet'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          await tester.tap(find.text('Use private balance'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(wallet.privateBuilds, 1);
          expect(find.byType(BuildingTransactionDialog), findsOneWidget);

          await tester.tap(find.text('Cancel'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.byType(BuildingTransactionDialog), findsNothing);
          expect(wallet.privateResult.isCompleted, isFalse);

          await tester.tap(publicButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(wallet.publicResults, hasLength(1));
          expect(find.byType(BuildingTransactionDialog), findsOneWidget);

          wallet.privateResult.complete(TxData());
          await tester.pump(const Duration(seconds: 3));
          expect(find.byType(BuildingTransactionDialog), findsOneWidget);
          // Exercise the actual button callback while the new build is busy.
          tester.widget<MaterialButton>(publicButton).onPressed!();
          await tester.pump();
          expect(wallet.publicResults, hasLength(1));

          await tester.tap(find.text('Cancel'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.byType(BuildingTransactionDialog), findsNothing);
          await tester.tap(publicButton);
          await tester.pump();
          expect(wallet.publicResults, hasLength(2));
          expect(tester.takeException(), isNull);
        } finally {
          if (find.text('Cancel').evaluate().isNotEmpty) {
            await tester.tap(find.text('Cancel'));
            await tester.pump();
          }
          await tester.pumpWidget(const SizedBox.shrink());
          if (!wallet.privateResult.isCompleted) {
            wallet.privateResult.complete(TxData());
          }
          for (final result in wallet.publicResults) {
            result.complete(TxData());
          }
          await tester.pump(const Duration(seconds: 3));
        }
      },
    );
  }
}

const _address = 'aEF6fyd5jjCPcbiEBZJ2g8583caUme8T7Y';

Trade _trade() => Trade(
  uuid: 'test',
  tradeId: 'test',
  rateType: 'floating',
  direction: 'direct',
  timestamp: DateTime(2026),
  updatedAt: DateTime(2026),
  payInCurrency: 'FIRO',
  payInAmount: '0.00000001',
  payInAddress: _address,
  payInNetwork: 'firo',
  payInExtraId: '',
  payInTxid: '',
  payOutCurrency: 'BTC',
  payOutAmount: '0.00000001',
  payOutAddress: '',
  payOutNetwork: 'btc',
  payOutExtraId: '',
  payOutTxid: '',
  refundAddress: '',
  refundExtraId: '',
  status: 'waiting',
  exchangeName: 'ChangeNOW',
);

class _FiroWallet extends FiroWallet {
  _FiroWallet() : super(CryptoCurrencyNetwork.main);

  int privateBuilds = 0;
  final privateResult = Completer<TxData>();
  final publicResults = <Completer<TxData>>[];

  @override
  Future<TxData> prepareSendSpark({
    required TxData txData,
    bool requireChaumV2 = false,
  }) {
    privateBuilds++;
    return privateResult.future;
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) {
    final result = Completer<TxData>();
    publicResults.add(result);
    return result.future;
  }
}

class _Wallets extends Fake implements Wallets {
  _Wallets(this.wallet);

  final FiroWallet wallet;

  @override
  FiroWallet getWallet(String walletId) => wallet;
}
