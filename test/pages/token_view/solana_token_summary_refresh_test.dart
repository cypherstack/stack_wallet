import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutex/mutex.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/ethereum/eth_contract.dart';
import 'package:stackwallet/models/isar/models/solana/sol_contract.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/token_view/sub_widgets/token_summary_sol.dart';
import 'package:stackwallet/pages/wallet_view/sub_widgets/wallet_refresh_button.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/wallet_view/sub_widgets/desktop_wallet_summary.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/price_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/price_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/amount/amount_formatter.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/providers/eth/current_token_wallet_provider.dart';
import 'package:stackwallet/wallets/isar/providers/solana/current_sol_token_wallet_provider.dart';
import 'package:stackwallet/wallets/isar/providers/solana/sol_token_balance_provider.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/eth_token_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/solana_token_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

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

class _RoutingWallet extends Fake implements Wallet {
  _RoutingWallet(this.walletId);

  @override
  final String walletId;
  @override
  final refreshMutex = Mutex();
  int refreshes = 0;

  @override
  Future<void> refresh() async {
    refreshes++;
  }
}

class _RoutingSolWallet extends Fake implements SolanaTokenWallet {
  _RoutingSolWallet({required this.walletId, required String mint})
    : solContract = SolContract(
        address: mint,
        name: 'USD Coin',
        symbol: 'USDC',
        decimals: 6,
      );

  @override
  final String walletId;
  @override
  final SolContract solContract;
  @override
  String get tokenMint => solContract.address;
  @override
  final refreshMutex = Mutex();
  int refreshes = 0;

  @override
  Future<void> refresh() async {
    refreshes++;
  }
}

class _RoutingEthWallet extends Fake implements EthTokenWallet {
  _RoutingEthWallet({required this.walletId, required String address})
    : tokenContract = EthContract(
        address: address,
        name: 'USD Coin',
        symbol: 'USDC',
        decimals: 6,
        type: EthContractType.erc20,
      );

  @override
  final String walletId;
  @override
  final EthContract tokenContract;
  @override
  final refreshMutex = Mutex();
  int refreshes = 0;

  @override
  Future<void> refresh() async {
    refreshes++;
  }
}

class _RoutingWallets extends Fake implements Wallets {
  _RoutingWallets(this.byId);

  final Map<String, Wallet> byId;

  @override
  Wallet getWallet(String walletId) => byId[walletId]!;
}

Future<void> _pumpRefreshButton(
  WidgetTester tester, {
  required String walletId,
  required _RoutingWallet baseWallet,
  String? tokenAddress,
  SolanaTokenWallet? solWallet,
  EthTokenWallet? ethWallet,
}) async {
  final theme = StackTheme.fromJson(json: lightThemeJsonMap);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pWallets.overrideWithValue(
          _RoutingWallets({baseWallet.walletId: baseWallet}),
        ),
        pCurrentSolanaTokenWallet.overrideWithValue(solWallet),
        pCurrentTokenWallet.overrideWithValue(ethWallet),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        home: Scaffold(
          body: WalletRefreshButton(
            walletId: walletId,
            initialSyncStatus: WalletSyncStatus.synced,
            tokenContractAddress: tokenAddress,
          ),
        ),
      ),
    ),
  );
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

  testWidgets('stale Solana wallet ID does not refresh either wallet', (
    tester,
  ) async {
    const mint = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';
    final base = _RoutingWallet('wallet-a');
    final staleToken = _RoutingSolWallet(walletId: 'wallet-b', mint: mint);
    await _pumpRefreshButton(
      tester,
      walletId: base.walletId,
      baseWallet: base,
      tokenAddress: mint,
      solWallet: staleToken,
    );

    await tester.tap(find.byType(WalletRefreshButton));

    expect(base.refreshes, 0);
    expect(staleToken.refreshes, 0);
  });

  testWidgets('base refresh ignores a leftover Solana token wallet', (
    tester,
  ) async {
    final base = _RoutingWallet('wallet-a');
    final token = _RoutingSolWallet(
      walletId: base.walletId,
      mint: 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
    );
    await _pumpRefreshButton(
      tester,
      walletId: base.walletId,
      baseWallet: base,
      solWallet: token,
    );

    await tester.tap(find.byType(WalletRefreshButton));

    expect(base.refreshes, 1);
    expect(token.refreshes, 0);
  });

  testWidgets('mismatched Solana mint does not refresh', (tester) async {
    final base = _RoutingWallet('wallet-a');
    final token = _RoutingSolWallet(
      walletId: base.walletId,
      mint: 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
    );
    await _pumpRefreshButton(
      tester,
      walletId: base.walletId,
      baseWallet: base,
      tokenAddress: 'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB',
      solWallet: token,
    );

    await tester.tap(find.byType(WalletRefreshButton));

    expect(token.refreshes, 0);
    expect(base.refreshes, 0);
  });

  testWidgets('matching Ethereum wallet and contract refreshes', (
    tester,
  ) async {
    const address = '0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48';
    final base = _RoutingWallet('wallet-a');
    final token = _RoutingEthWallet(walletId: base.walletId, address: address);
    await _pumpRefreshButton(
      tester,
      walletId: base.walletId,
      baseWallet: base,
      tokenAddress: address,
      ethWallet: token,
    );

    await tester.tap(find.byType(WalletRefreshButton));

    expect(token.refreshes, 1);
    expect(base.refreshes, 0);
  });

  testWidgets('mismatched Ethereum contract does not refresh', (tester) async {
    final base = _RoutingWallet('wallet-a');
    final token = _RoutingEthWallet(
      walletId: base.walletId,
      address: '0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
    );
    await _pumpRefreshButton(
      tester,
      walletId: base.walletId,
      baseWallet: base,
      tokenAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
      ethWallet: token,
    );

    await tester.tap(find.byType(WalletRefreshButton));

    expect(token.refreshes, 0);
    expect(base.refreshes, 0);
  });

  testWidgets('only the token provider matching both route values refreshes', (
    tester,
  ) async {
    const address = '0xA0b86991c6218b36c1d19d4a2e9eb0ce3606eb48';
    final base = _RoutingWallet('wallet-a');
    final sol = _RoutingSolWallet(
      walletId: 'wallet-b',
      mint: 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
    );
    final eth = _RoutingEthWallet(walletId: base.walletId, address: address);
    await _pumpRefreshButton(
      tester,
      walletId: base.walletId,
      baseWallet: base,
      tokenAddress: address,
      solWallet: sol,
      ethWallet: eth,
    );

    await tester.tap(find.byType(WalletRefreshButton));

    expect(eth.refreshes, 1);
    expect(sol.refreshes, 0);
    expect(base.refreshes, 0);
  });
}
