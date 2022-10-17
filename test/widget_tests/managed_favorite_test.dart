import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/widgets/managed_favorite.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

import 'managed_favorite_test.mocks.dart';

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
  testWidgets("Test wallet info row displays correctly", (widgetTester) async {
    final wallets = MockWallets();
    final CoinServiceAPI wallet = MockBitcoinWallet();
    when(wallet.coin).thenAnswer((_) => Coin.bitcoin);
    when(wallet.walletName).thenAnswer((_) => "some wallet");
    when(wallet.walletId).thenAnswer((_) => "some wallet id");

    final manager = Manager(wallet);
    when(wallets.getManager("some wallet id"))
        .thenAnswer((realInvocation) => manager);

    when(manager.isFavorite).thenAnswer((realInvocation) => false);
    const managedFavorite = ManagedFavorite(walletId: "some wallet id");
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
            child: managedFavorite,
          ),
        ),
      ),
    );

    expect(find.byType(ManagedFavorite), findsOneWidget);
  });
}
