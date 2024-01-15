import 'package:mockito/annotations.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/themes/theme_service.dart';

@GenerateMocks([
  Wallets,
  WalletsService,
  ThemeService,
], customMocks: [])
void main() {
  // testWidgets('Test table view row', (widgetTester) async {
  //   widgetTester.binding.window.physicalSizeTestValue = const Size(2500, 1800);
  //
  //   final mockWallet = MockWallets();
  //   final mockThemeService = MockThemeService();
  //   final CoinServiceAPI wallet = MockBitcoinWallet();
  //   when(wallet.coin).thenAnswer((_) => Coin.bitcoin);
  //   when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
  //     (_) => StackTheme.fromJson(
  //       json: lightThemeJsonMap,
  //     ),
  //   );
  //
  //   when(wallet.walletName).thenAnswer((_) => "some wallet");
  //   when(wallet.walletId).thenAnswer((_) => "Wallet id 1");
  //   when(wallet.balance).thenAnswer(
  //     (_) => Balance(
  //       total: Amount.zero,
  //       spendable: Amount.zero,
  //       blockedTotal: Amount.zero,
  //       pendingSpendable: Amount.zero,
  //     ),
  //   );
  //
  //   final wallet = Manager(wallet);
  //
  //   when(mockWallet.getWalletIdsFor(coin: Coin.bitcoin))
  //       .thenAnswer((realInvocation) => ["Wallet id 1", "wallet id 2"]);
  //
  //   when(mockWallet.getManagerProvider("Wallet id 1")).thenAnswer(
  //       (realInvocation) => ChangeNotifierProvider((ref) => manager));
  //
  //   when(mockWallet.getManagerProvider("wallet id 2")).thenAnswer(
  //       (realInvocation) => ChangeNotifierProvider((ref) => manager));
  //
  //   await widgetTester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         pWallets.overrideWithValue(mockWallet),
  //         pThemeService.overrideWithValue(mockThemeService),
  //         coinIconProvider.overrideWithProvider(
  //           (argument) => Provider<String>((_) =>
  //               "${Directory.current.path}/test/sample_data/light/assets/dummy.svg"),
  //         ),
  //       ],
  //       child: MaterialApp(
  //         theme: ThemeData(
  //           extensions: [
  //             StackColors.fromStackColorTheme(
  //               StackTheme.fromJson(
  //                 json: lightThemeJsonMap,
  //               ),
  //             ),
  //           ],
  //         ),
  //         home: Material(
  //           child: TableViewRow(
  //             cells: [
  //               for (int j = 1; j <= 5; j++)
  //                 TableViewCell(flex: 16, child: Text("Some ${j}"))
  //             ],
  //             expandingChild: const CoinWalletsTable(
  //               coin: Coin.bitcoin,
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   await widgetTester.pumpAndSettle();
  //
  //   expect(find.text("Some 1"), findsOneWidget);
  //   expect(find.byType(TableViewRow), findsWidgets);
  //   expect(find.byType(TableViewCell), findsWidgets);
  //   expect(find.byType(CoinWalletsTable), findsWidgets);
  // });
}
