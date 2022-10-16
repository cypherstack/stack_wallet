import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart' as mockito;
import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/bitcoin/bitcoin_wallet.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/theme/light_colors.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/wallet_card.dart';

import 'wallet_card_test.mocks.dart';

// class MockNavigatorObserver extends Mock implements NavigatorObserver {}

@GenerateMocks([Wallets, BitcoinWallet, LocaleService])
void main() {
  group('Navigation tests', () {
    late mockingjay.MockNavigator navigator;

    setUp(() {
      navigator = mockingjay.MockNavigator();
      // mockingjay
      //     .when(navigator.push(mockingjay.any()))
      //     .thenAnswer((invocation) async {});
    });

    Future<void> _builAddressSheetCard(
        WidgetTester widgetTester, bool popPrevious) async {
      // final CoinServiceAPI wallet = MockBitcoinWallet();
      // when(wallet.walletId).thenAnswer((realInvocation) => "wallet id");
      // when(wallet.coin).thenAnswer((realInvocation) => Coin.bitcoin);
      // when(wallet.walletName).thenAnswer((realInvocation) => "wallet name");
      //
      // final wallets = MockWallets();
      // final manager = Manager(wallet);
      //
      // when(wallets.getManagerProvider("wallet id")).thenAnswer(
      //     (realInvocation) => ChangeNotifierProvider((ref) => manager));
      //
      // await widgetTester.pumpWidget(
      //   ProviderScope(
      //     overrides: [
      //       walletsChangeNotifierProvider.overrideWithValue(wallets),
      //     ],
      //     child: MaterialApp(
      //       theme: ThemeData(
      //         extensions: [
      //           StackColors.fromStackColorTheme(LightColors()),
      //         ],
      //       ),
      //       home: Material(
      //         child: WalletSheetCard(
      //           walletId: "wallet id",
      //           popPrevious: popPrevious,
      //         ),
      //       ),
      //       navigatorObservers: [mockObserver],
      //     ),
      //   ),
      // );
    }

    testWidgets("When pop popOver redirect", (widgetTester) async {
      final CoinServiceAPI wallet = MockBitcoinWallet();
      mockito.when(wallet.walletId).thenAnswer((realInvocation) => "wallet id");
      mockito.when(wallet.coin).thenAnswer((realInvocation) => Coin.bitcoin);
      mockito
          .when(wallet.walletName)
          .thenAnswer((realInvocation) => "wallet name");

      final wallets = MockWallets();
      final locale = MockLocaleService();
      final manager = Manager(wallet);

      mockito.when(wallets.getManagerProvider("wallet id")).thenAnswer(
          (realInvocation) => ChangeNotifierProvider((ref) => manager));
      mockito.when(locale.locale).thenAnswer((_) => "en_US");

      final navigator = mockingjay.MockNavigator();
      mockingjay
          .when(() => navigator.pushNamed("/wallets", arguments: []))
          .thenAnswer((_) async => {});
      // mockingjay.when(() => navigator.pop()).thenAnswer((invocation) {});

      await widgetTester.pumpWidget(
        ProviderScope(
          overrides: [
            walletsChangeNotifierProvider.overrideWithValue(wallets),
            localeServiceChangeNotifierProvider.overrideWithValue(locale),
          ],
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                StackColors.fromStackColorTheme(LightColors()),
              ],
            ),
            home: mockingjay.MockNavigatorProvider(
                navigator: navigator,
                child: const WalletSheetCard(
                  walletId: "wallet id",
                  popPrevious: true,
                )),
          ),
        ),
      );

      // await widgetTester.pumpAndSettle();
      // final navigator = mockingjay.MockNavigator();
      // // mockingjay.when(() => navi)
      // await _builAddressSheetCard(widgetTester, false);
      //
      // // final Route pushedRoute = verify(mocki)
      // expect(find.byType(MaterialButton), findsOneWidget);
      // mockingjay.verify(() => navigator.pushNamed("wallets")).called(1);
      await widgetTester.tap(find.byType(MaterialButton));
      // mockingjay
      //     .verifyNever(
      //       () => navigator.push<void>(
      //         mockingjay.any(
      //           that: mockingjay.isRoute<void>(
      //             whereName: equals("/wallet"),
      //           ),
      //         ),
      //       ),
      //     )
      //     .called(0);

      // verify(mockObserver.didPop(mockingjay.any(), mockingjay.any()));
    });
  });

  testWidgets('test widget loads correctly', (widgetTester) async {
    final CoinServiceAPI wallet = MockBitcoinWallet();
    mockito.when(wallet.walletId).thenAnswer((realInvocation) => "wallet id");
    mockito.when(wallet.coin).thenAnswer((realInvocation) => Coin.bitcoin);
    mockito
        .when(wallet.walletName)
        .thenAnswer((realInvocation) => "wallet name");

    final wallets = MockWallets();
    final manager = Manager(wallet);

    mockito.when(wallets.getManagerProvider("wallet id")).thenAnswer(
        (realInvocation) => ChangeNotifierProvider((ref) => manager));

    const walletSheetCard = WalletSheetCard(
      walletId: "wallet id",
    );

    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          walletsChangeNotifierProvider.overrideWithValue(wallets),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(LightColors()),
            ],
          ),
          home: const Material(
            child: walletSheetCard,
          ),
        ),
      ),
    );
    expect(find.byWidget(walletSheetCard), findsOneWidget);
  });

  // testWidgets("test pop previous is false does nothing", (widgetTester) async {
  //   final CoinServiceAPI wallet = MockBitcoinWallet();
  //   when(wallet.walletId).thenAnswer((realInvocation) => "wallet id");
  //   when(wallet.coin).thenAnswer((realInvocation) => Coin.bitcoin);
  //   when(wallet.walletName).thenAnswer((realInvocation) => "wallet name");
  //
  //   final wallets = MockWallets();
  //   final manager = Manager(wallet);
  //
  //   when(wallets.getManagerProvider("wallet id")).thenAnswer(
  //       (realInvocation) => ChangeNotifierProvider((ref) => manager));
  //
  //   const walletSheetCard = WalletSheetCard(
  //     walletId: "wallet id",
  //     popPrevious: false,
  //   );
  //
  //   // late NavigatorObserver mockObserver;
  //   //
  //   // setUp(() {
  //   //   mockObserver = MockNavigatorObserver();
  //   // });
  //
  //   await widgetTester.pumpWidget(
  //     ProviderScope(
  //       overrides: [
  //         walletsChangeNotifierProvider.overrideWithValue(wallets),
  //       ],
  //       child: MaterialApp(
  //         theme: ThemeData(
  //           extensions: [
  //             StackColors.fromStackColorTheme(LightColors()),
  //           ],
  //         ),
  //         home: const Material(
  //           child: walletSheetCard,
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   await widgetTester.tap(find.byType(MaterialButton));
  // });
}
