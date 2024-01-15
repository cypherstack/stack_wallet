import 'package:mockito/annotations.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/services/wallets_service.dart';

@GenerateMocks([
  Wallets,
  WalletsService,
], customMocks: [
  MockSpec<NodeService>(returnNullOnMissingStub: true),
  // MockSpec<WalletsService>(returnNullOnMissingStub: true),
])
void main() {
  // testWidgets("Test wallet info row balance loads correctly",
  //     (widgetTester) async {
  //   final wallets = MockWallets();
  //   final CoinServiceAPI wallet = MockBitcoinWallet();
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
  //   const walletInfoRowBalance =
  //       WalletInfoRowBalance(walletId: "some-wallet-id");
  //   await widgetTester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         pWallets.overrideWithValue(wallets),
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
  //           child: walletInfoRowBalance,
  //         ),
  //       ),
  //     ),
  //   );
  //   //
  //   // expect(find.text("some wallet"), findsOneWidget);
  //
  //   await widgetTester.pumpAndSettle();
  //
  //   expect(find.byType(WalletInfoRowBalance), findsOneWidget);
  // });
}
