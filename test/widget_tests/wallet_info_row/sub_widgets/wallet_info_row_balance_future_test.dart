import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_balance_future.dart';

import 'wallet_info_row_balance_future_test.mocks.dart';

@GenerateMocks([
  Wallets,
  WalletsService,
  BitcoinWallet
], customMocks: [
  MockSpec<NodeService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<CoinServiceAPI>(returnNullOnMissingStub: true),
  // MockSpec<WalletsService>(returnNullOnMissingStub: true),
])
void main() {
  testWidgets("Test wallet info row balance loads correctly",
      (widgetTester) async {
    final wallets = MockWallets();
    final CoinServiceAPI wallet = MockBitcoinWallet();
    when(wallet.coin).thenAnswer((_) => Coin.bitcoin);
    when(wallet.walletName).thenAnswer((_) => "some wallet");
    when(wallet.walletId).thenAnswer((_) => "some-wallet-id");
    when(wallet.balance).thenAnswer(
      (_) => Balance(
        coin: Coin.bitcoin,
        total: 0,
        spendable: 0,
        blockedTotal: 0,
        pendingSpendable: 0,
      ),
    );

    final manager = Manager(wallet);
    when(wallets.getManagerProvider("some-wallet-id")).thenAnswer(
        (realInvocation) => ChangeNotifierProvider((ref) => manager));

    const walletInfoRowBalance =
        WalletInfoRowBalanceFuture(walletId: "some-wallet-id");
    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsChangeNotifierProvider.overrideWithValue(wallets),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                LightColors(),
              ),
            ],
          ),
          home: const Material(
            child: walletInfoRowBalance,
          ),
        ),
      ),
    );
    //
    // expect(find.text("some wallet"), findsOneWidget);

    await widgetTester.pumpAndSettle();

    expect(find.byType(WalletInfoRowBalanceFuture), findsOneWidget);
  });
}
