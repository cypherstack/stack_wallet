import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_balance.dart';
import 'package:stackwallet/widgets/wallet_info_row/wallet_info_row.dart';

import '../../sample_data/theme_json.dart';
import 'wallet_info_row_test.mocks.dart';

@GenerateMocks([
  Wallets,
  WalletsService,
  ThemeService,
  BitcoinWallet
], customMocks: [
  MockSpec<NodeService>(returnNullOnMissingStub: true),
  MockSpec<Manager>(returnNullOnMissingStub: true),
  MockSpec<CoinServiceAPI>(returnNullOnMissingStub: true),
  // MockSpec<WalletsService>(returnNullOnMissingStub: true),
])
void main() {
  testWidgets("Test wallet info row displays correctly", (widgetTester) async {
    final wallets = MockWallets();
    final mockThemeService = MockThemeService();
    final CoinServiceAPI wallet = MockBitcoinWallet();
    when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
      (_) => StackTheme.fromJson(
        json: lightThemeJsonMap,
      ),
    );
    when(wallet.coin).thenAnswer((_) => Coin.bitcoin);
    when(wallet.walletName).thenAnswer((_) => "some wallet");
    when(wallet.walletId).thenAnswer((_) => "some-wallet-id");
    when(wallet.balance).thenAnswer(
      (_) => Balance(
        total: Amount.zero,
        spendable: Amount.zero,
        blockedTotal: Amount.zero,
        pendingSpendable: Amount.zero,
      ),
    );

    final manager = Manager(wallet);
    when(wallets.getManagerProvider("some-wallet-id")).thenAnswer(
        (realInvocation) => ChangeNotifierProvider((ref) => manager));

    const walletInfoRow = WalletInfoRow(walletId: "some-wallet-id");
    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsChangeNotifierProvider.overrideWithValue(wallets),
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
          home: const Material(
            child: walletInfoRow,
          ),
        ),
      ),
    );

    await widgetTester.pumpAndSettle();

    expect(find.text("some wallet"), findsOneWidget);
    expect(find.byType(WalletInfoRowBalance), findsOneWidget);
  });
}
