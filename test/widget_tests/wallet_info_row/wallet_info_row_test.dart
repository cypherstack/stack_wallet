import 'package:mockito/annotations.dart';
import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/themes/theme_service.dart';

@GenerateMocks([
  Wallets,
  WalletsService,
  ThemeService,
  BitcoinWallet
], customMocks: [
  MockSpec<NodeService>(returnNullOnMissingStub: true),
  MockSpec<CoinServiceAPI>(returnNullOnMissingStub: true),
  // MockSpec<WalletsService>(returnNullOnMissingStub: true),
])
void main() {
  // testWidgets("Test wallet info row displays correctly", (widgetTester) async {
  //   final wallets = MockWallets();
  //   final mockThemeService = MockThemeService();
  //   final CoinServiceAPI wallet = MockBitcoinWallet();
  //   when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
  //     (_) => StackTheme.fromJson(
  //       json: lightThemeJsonMap,
  //     ),
  //   );
  //   when(wallet.coin).thenAnswer((_) => Coin.bitcoin);
  //   when(wallet.walletName).thenAnswer((_) => "some wallet");
  //   when(wallet.walletId).thenAnswer((_) => "some-wallet-id");
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
  //   when(wallets.getManagerProvider("some-wallet-id")).thenAnswer(
  //       (realInvocation) => ChangeNotifierProvider((ref) => manager));
  //
  //   const walletInfoRow = WalletInfoRow(walletId: "some-wallet-id");
  //   await widgetTester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         pWallets.overrideWithValue(wallets),
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
  //         home: const Material(
  //           child: walletInfoRow,
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   await widgetTester.pumpAndSettle();
  //
  //   expect(find.text("some wallet"), findsOneWidget);
  //   expect(find.byType(WalletInfoRowBalance), findsOneWidget);
  // });
}
