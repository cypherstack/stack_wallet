import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/coin_wallets_table.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/table_view/table_view_cell.dart';
import 'package:stackwallet/widgets/table_view/table_view_row.dart';

import 'table_view_row_test.mocks.dart';

@GenerateMocks([
  Wallets,
  WalletsService,
  BitcoinWallet
], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<CoinServiceAPI>(returnNullOnMissingStub: true)
])
void main() {
  testWidgets('Test table view row', (widgetTester) async {
    final mockWallet = MockWallets();
    final CoinServiceAPI wallet = MockBitcoinWallet();
    when(wallet.coin).thenAnswer((_) => Coin.bitcoin);

    when(wallet.walletName).thenAnswer((_) => "some wallet");
    when(wallet.walletId).thenAnswer((_) => "Wallet id 1");

    final manager = Manager(wallet);

    when(mockWallet.getWalletIdsFor(coin: Coin.bitcoin))
        .thenAnswer((realInvocation) => ["Wallet id 1", "wallet id 2"]);

    when(mockWallet.getManagerProvider("Wallet id 1")).thenAnswer(
        (realInvocation) => ChangeNotifierProvider((ref) => manager));

    when(mockWallet.getManagerProvider("wallet id 2")).thenAnswer(
        (realInvocation) => ChangeNotifierProvider((ref) => manager));

    final walletIds = mockWallet.getWalletIdsFor(coin: Coin.bitcoin);

    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsChangeNotifierProvider.overrideWithValue(mockWallet),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                LightColors(),
              ),
            ],
          ),
          home: Material(
            child: TableViewRow(
                cells: [
                  for (int j = 1; j <= 5; j++)
                    TableViewCell(flex: 16, child: Text("Some Text ${j}"))
                ],
                expandingChild: const CoinWalletsTable(
                  coin: Coin.bitcoin,
                )),
          ),
        ),
      ),
    );

    expect(find.text("Some Text 1"), findsOneWidget);
    expect(find.byType(TableViewRow), findsWidgets);
    expect(find.byType(TableViewCell), findsWidgets);
    expect(find.byType(CoinWalletsTable), findsWidgets);
  });
}
