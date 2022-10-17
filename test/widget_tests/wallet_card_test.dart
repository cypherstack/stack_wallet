import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart' as mockito;
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
import 'package:tuple/tuple.dart';

import 'wallet_card_test.mocks.dart';

// class MockNavigatorObserver extends Mock implements NavigatorObserver {}

@GenerateMocks([Wallets, BitcoinWallet, LocaleService])
void main() {
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
    final managerProvider = ChangeNotifierProvider((ref) => manager);

    mockito
        .when(wallets.getManagerProvider("wallet id"))
        .thenAnswer((realInvocation) => managerProvider);
    mockito.when(locale.locale).thenAnswer((_) => "en_US");

    mockito
        .when(wallets.getManagerProvider("wallet id"))
        .thenAnswer((realInvocation) => managerProvider);

    final navigator = mockingjay.MockNavigator();
    mockingjay
        .when(() => navigator.pushNamed("/wallet",
            arguments: Tuple2("wallet id", managerProvider)))
        .thenAnswer((_) async => {});

    // mockingjay
    //     .when(() => navigator.push(mockingjay.any(
    //         that: mockingjay.isRoute(
    //             whereName: equals("/wallets"),
    //             whereArguments: equals(Tuple2(
    //                 "wallet id", wallets.getManagerProvider("wallet id")))))))
    //     .thenAnswer((_) async => {});
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
              )),
        ),
      ),
    );
    //
    expect(find.byType(MaterialButton), findsOneWidget);
    await widgetTester.tap(find.byType(MaterialButton));
    // });
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
}
