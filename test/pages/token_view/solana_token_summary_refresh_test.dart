import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutex/mutex.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/solana/sol_contract.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/token_view/sub_widgets/token_summary_sol.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/wallet_refresh_button.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_wallet_summary.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/price_provider.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/price_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/providers/solana/current_sol_token_wallet_provider.dart';
import 'package:stackwallet/wallets/isar/providers/solana/sol_token_balance_provider.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/solana_token_wallet.dart';

import '../../sample_data/theme_json.dart';
import '../../wallets/support/xelis_test_fakes.dart';

class _UsdcWallet extends Fake implements SolanaTokenWallet {
  @override
  String get walletId => 'sol-wallet';
  @override
  final solContract = SolContract(
    address: 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
    name: 'USD Coin',
    symbol: 'USDC',
    decimals: 6,
  );
  @override
  String get tokenMint => solContract.address;
  @override
  String get tokenSymbol => solContract.symbol;
  @override
  int get tokenDecimals => solContract.decimals;
  @override
  final refreshMutex = Mutex();

  final pending = Completer<void>();
  int refreshes = 0;

  @override
  Future<void> refresh() {
    refreshes++;
    return pending.future;
  }
}

void main() {
  for (final desktop in [false, true]) {
    final layout = desktop ? 'desktop' : 'mobile';
    testWidgets('$layout Solana USDC summary refreshes its token wallet', (
      tester,
    ) async {
      final oldThemeDir = StackFileSystem.themesDir;
      StackFileSystem.themesDir = Directory('test/sample_data').absolute;
      addTearDown(() => StackFileSystem.themesDir = oldThemeDir);
      final coin = Solana(CryptoCurrencyNetwork.main);
      final wallet = _UsdcWallet();
      final theme = StackTheme.fromJson(json: lightThemeJsonMap);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pWalletCoin(wallet.walletId).overrideWithValue(coin),
            pAmountUnit(coin).overrideWithValue(AmountUnit.normal),
            pMaxDecimals(coin).overrideWithValue(coin.fractionDigits),
            priceAnd24hChangeNotifierProvider.overrideWithValue(
              PriceService('USD'),
            ),
            pCurrentSolanaTokenWallet.overrideWithValue(wallet),
            pWalletName(wallet.walletId).overrideWithValue('Solana'),
            pSolanaTokenBalance((
              walletId: wallet.walletId,
              tokenMint: wallet.tokenMint,
            )).overrideWithValue(
              Balance.zeroWith(fractionDigits: wallet.tokenDecimals),
            ),
            prefsChangeNotifierProvider.overrideWithValue(ConfirmationPrefs()),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [StackColors.fromStackColorTheme(theme)],
            ),
            home: Scaffold(
              body: desktop
                  ? DesktopWalletSummary(
                      walletId: wallet.walletId,
                      isToken: true,
                      initialSyncStatus: WalletSyncStatus.synced,
                    )
                  : SolanaTokenSummary(
                      walletId: wallet.walletId,
                      tokenMint: wallet.tokenMint,
                      initialSyncStatus: WalletSyncStatus.synced,
                    ),
            ),
          ),
        ),
      );

      final button = find.byType(WalletRefreshButton);
      await tester.tap(button);
      await tester.tap(button);
      expect(wallet.refreshes, 1);

      wallet.pending.complete();
      await tester.pump();
      await tester.tap(button);
      expect(wallet.refreshes, 2);
    });
  }
}
