import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/widgets/wallet_info_row/sub_widgets/wallet_info_row_balance_future.dart';
import 'package:stackwallet/widgets/wallet_info_row/wallet_info_row.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';

// import '../screen_tests/lockscreen_view_screen_test.mocks.dart';
import 'wallet_info_row_test.mocks.dart';

@GenerateMocks([WalletsService],
    customMocks: [MockSpec<Manager>(returnNullOnMissingStub: true)])
void main() {
  testWidgets("returns wallet info for given wallet id", (widgetTester) async {
    final service = MockWalletsService();
    // final mockManager = MockManager();

    // String? walletId = await service.addNewWallet(
    //     name: "Test", coin: Coin.bitcoin, shouldNotifyListeners: false);
    // final managerProvider = ChangeNotifierProvider<Manager>((ref) => {
    //   return service.get;
    // });

    when(service.addNewWallet(
            name: "Test", coin: Coin.bitcoin, shouldNotifyListeners: false))
        .thenAnswer((_) => Future(() => "some wallet id"));

    // when(service.getWalletId(walletName))
    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsServiceChangeNotifierProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                LightColors(),
              ),
            ],
          ),
          home: const WalletInfoRowBalanceFuture(
            walletId: "some wallet id",
          ),
        ),
      ),
    );
  });
}
