import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart' as mockito;
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/widgets/wallet_card.dart';

import '../sample_data/theme_json.dart';
import 'wallet_card_test.mocks.dart';

/// quick amount constructor wrapper. Using an int is bad practice but for
/// testing with small amounts this should be fine
Amount _a(int i) => Amount.fromDecimal(
      Decimal.fromInt(i),
      fractionDigits: 8,
    );

@GenerateMocks([
  Wallets,
  BitcoinWallet,
  LocaleService,
  ThemeService,
])
void main() {
  testWidgets('test widget loads correctly', (widgetTester) async {
    final CoinServiceAPI wallet = MockBitcoinWallet();
    final mockThemeService = MockThemeService();

    mockito.when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
          (_) => StackTheme.fromJson(
            json: lightThemeJsonMap,
            applicationThemesDirectoryPath: "test",
          ),
        );
    mockito.when(wallet.walletId).thenAnswer((realInvocation) => "wallet id");
    mockito.when(wallet.coin).thenAnswer((realInvocation) => Coin.bitcoin);
    mockito
        .when(wallet.walletName)
        .thenAnswer((realInvocation) => "wallet name");
    mockito.when(wallet.balance).thenAnswer(
          (_) => Balance(
            total: _a(0),
            spendable: _a(0),
            blockedTotal: _a(0),
            pendingSpendable: _a(0),
          ),
        );

    final wallets = MockWallets();
    final manager = Manager(wallet);

    mockito.when(wallets.getManagerProvider("wallet id")).thenAnswer(
        (realInvocation) => ChangeNotifierProvider((ref) => manager));

    const walletSheetCard = SimpleWalletCard(
      walletId: "wallet id",
    );

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
                  applicationThemesDirectoryPath: "test",
                ),
              ),
            ],
          ),
          home: const Material(
            child: walletSheetCard,
          ),
        ),
      ),
    );

    await widgetTester.pumpAndSettle();

    expect(find.byWidget(walletSheetCard), findsOneWidget);
  });
}
