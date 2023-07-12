import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages_desktop_specific/my_stack_view/coin_wallets_table.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/widgets/table_view/table_view_cell.dart';
import 'package:stackwallet/widgets/table_view/table_view_row.dart';

import '../../sample_data/theme_json.dart';
import 'table_view_row_test.mocks.dart';

@GenerateMocks([
  Wallets,
  WalletsService,
  ThemeService,
  BitcoinWallet
], customMocks: [
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<CoinServiceAPI>(returnNullOnMissingStub: true)
])
void main() {
  testWidgets('Test table view row', (widgetTester) async {
    widgetTester.binding.window.physicalSizeTestValue = const Size(2500, 1800);

    final mockWallet = MockWallets();
    final mockThemeService = MockThemeService();
    final CoinServiceAPI wallet = MockBitcoinWallet();
    when(wallet.coin).thenAnswer((_) => Coin.bitcoin);
    when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
      (_) => StackTheme.fromJson(
        json: lightThemeJsonMap,
      ),
    );

    when(wallet.walletName).thenAnswer((_) => "some wallet");
    when(wallet.walletId).thenAnswer((_) => "Wallet id 1");
    when(wallet.balance).thenAnswer(
      (_) => Balance(
        total: Amount.zero,
        spendable: Amount.zero,
        blockedTotal: Amount.zero,
        pendingSpendable: Amount.zero,
      ),
    );

    final manager = Manager(wallet);

    when(mockWallet.getWalletIdsFor(coin: Coin.bitcoin))
        .thenAnswer((realInvocation) => ["Wallet id 1", "wallet id 2"]);

    when(mockWallet.getManagerProvider("Wallet id 1")).thenAnswer(
        (realInvocation) => ChangeNotifierProvider((ref) => manager));

    when(mockWallet.getManagerProvider("wallet id 2")).thenAnswer(
        (realInvocation) => ChangeNotifierProvider((ref) => manager));

    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsChangeNotifierProvider.overrideWithValue(mockWallet),
          pThemeService.overrideWithValue(mockThemeService),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(
                  json: lightThemeJsonMap,
                ),
              ),
            ],
          ),
          home: Material(
            child: TableViewRow(
              cells: [
                for (int j = 1; j <= 5; j++)
                  TableViewCell(flex: 16, child: Text("Some ${j}"))
              ],
              expandingChild: const CoinWalletsTable(
                coin: Coin.bitcoin,
              ),
            ),
          ),
        ),
      ),
    );

    await widgetTester.pumpAndSettle();

    expect(find.text("Some 1"), findsOneWidget);
    expect(find.byType(TableViewRow), findsWidgets);
    expect(find.byType(TableViewCell), findsWidgets);
    expect(find.byType(CoinWalletsTable), findsWidgets);
  });
}
