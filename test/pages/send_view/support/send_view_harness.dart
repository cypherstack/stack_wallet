import 'dart:async';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/global/price_provider.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/price_service.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/amount/amount_unit.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/providers/eth/current_token_wallet_provider.dart';
import 'package:stackwallet/wallets/isar/providers/eth/token_balance_provider.dart';
import 'package:stackwallet/wallets/isar/providers/solana/current_sol_token_wallet_provider.dart';
import 'package:stackwallet/wallets/isar/providers/solana/sol_token_balance_provider.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/eth_token_wallet.dart';
import 'package:stackwallet/wallets/wallet/impl/sub_wallets/solana_token_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import '../../../sample_data/theme_json.dart';
import '../../../wallets/support/xelis_test_fakes.dart';
import 'fake_wallets.dart';

class HarnessPrefs extends ConfirmationPrefs {
  HarnessPrefs({this.enableCoinControl = false});

  @override
  final bool enableCoinControl;

  @override
  AmountUnit amountUnit(CryptoCurrency coin) => AmountUnit.normal;

  @override
  int maxDecimals(CryptoCurrency coin) => coin.fractionDigits;
}

/// A test tapping a CustomTextButton needs its font loaded before the first
/// paint.
Future<void> loadButtonFont() async {
  final font = FontLoader('Inter_500');
  font.addFont(rootBundle.load('google_fonts/Inter-Medium.ttf'));
  await font.load();
}

/// A faster widget test: semantics are off and animations end on their first
/// frame.
@isTest
void testWithoutAnimation(String description, WidgetTesterCallback callback) =>
    testWidgets(description, (tester) async {
      // Timers keep the fake clock. testWidgets checks the dilation is back to
      // 1 before the test ends.
      timeDilation = 0.001;
      try {
        await callback(tester);
      } finally {
        timeDilation = 1;
      }
    }, semanticsEnabled: false);

Future<void> pumpSendView(
  WidgetTester tester, {
  required Wallet wallet,
  required bool desktop,
  required Widget view,
  List<Override> overrides = const [],
  Balance? balance,
  HarnessPrefs? prefs,
  RouteFactory? onGenerateRoute,
}) async {
  tester.view.physicalSize = desktop
      ? const Size(1600, 1200)
      : const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final previousPlatform = Util.layoutPlatform;
  addTearDown(() => Util.layoutPlatform = previousPlatform);
  Util.layoutPlatform = FakePlatform(
    operatingSystem: desktop ? "linux" : "android",
  );

  final coin = wallet.cryptoCurrency;
  final walletId = wallet.walletId;
  final info = wallet.info;
  (info as TestWalletInfo).balance = balance;
  final harnessPrefs = prefs ?? HarnessPrefs();
  final theme = StackTheme.fromJson(json: lightThemeJsonMap);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pWallets.overrideWithValue(ConfirmationWallets(wallet)),
        pWalletInfo(walletId).overrideWithValue(info),
        pWalletCoin(walletId).overrideWithValue(coin),
        pWalletName(walletId).overrideWithValue(info.name),
        pWalletBalance(walletId)
            .overrideWithProvider(Provider((_) => info.cachedBalance)),
        pWalletBalanceTertiary(walletId)
            .overrideWithValue(info.cachedBalanceTertiary),
        prefsChangeNotifierProvider.overrideWithValue(harnessPrefs),
        priceAnd24hChangeNotifierProvider.overrideWithValue(FakePriceService()),
        themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
        coinIconProvider(coin).overrideWithValue(
          File('test/sample_data/light/assets/dummy.svg').absolute.path,
        ),
        ...overrides,
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: [StackColors.fromStackColorTheme(theme)]),
        onGenerateRoute: onGenerateRoute,
        home: Scaffold(body: view),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

List<Override> ethTokenOverrides(EthTokenWallet tokenWallet) => [
  tokenServiceStateProvider.overrideWithProvider(
    StateProvider<EthTokenWallet?>((ref) => tokenWallet),
  ),
  pTokenBalance.overrideWithProvider(
    (_) => Provider<Balance>(
      (_) =>
          Balance.zeroWith(fractionDigits: tokenWallet.tokenContract.decimals),
    ),
  ),
];

List<Override> solTokenOverrides(SolanaTokenWallet tokenWallet) => [
  solanaTokenServiceStateProvider.overrideWithProvider(
    StateProvider<SolanaTokenWallet?>((ref) => tokenWallet),
  ),
  pSolanaTokenBalance.overrideWithProvider(
    (_) => Provider<Balance>(
      (_) => Balance.zeroWith(fractionDigits: tokenWallet.tokenDecimals),
    ),
  ),
];

class FakePriceService extends ChangeNotifier implements PriceService {
  @override
  ({Decimal value, double change24h})? getPrice(CryptoCurrency coin) => null;

  @override
  ({Decimal value, double change24h})? getTokenPrice(String contractAddress) =>
      null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RecordedRoutes {
  final arguments = <Object?>[];

  Route<dynamic> generate(RouteSettings settings) {
    arguments.add(settings.arguments);
    return MaterialPageRoute<Object?>(
      settings: settings,
      builder: (_) => const _PopAtOnce(),
    );
  }
}

class _PopAtOnce extends StatefulWidget {
  const _PopAtOnce();

  @override
  State<_PopAtOnce> createState() => _PopAtOnceState();
}

class _PopAtOnceState extends State<_PopAtOnce> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Future<List<String?>> logs(Future<void> Function() body) async {
  final messages = <String?>[];
  final debugPrintBefore = debugPrint;
  void restore() => debugPrint = debugPrintBefore;
  // The finally restores it before testWidgets checks it, and the teardown
  // when [body] never finishes.
  addTearDown(restore);
  debugPrint = (message, {wrapWidth}) => messages.add(message);
  try {
    await runZoned(
      body,
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, line) => messages.add(line),
      ),
    );
  } finally {
    restore();
  }
  return messages;
}
