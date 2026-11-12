import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart' as platform;
import 'package:stackwallet/models/add_wallet_list_entity/sub_classes/eth_token_entity.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/add_wallet_views/select_wallet_for_token_view.dart';
import 'package:stackwallet/providers/global/wallets_provider.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/utilities/default_eth_tokens.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/isar/models/wallet_info.dart';
import 'package:stackwallet/wallets/isar/providers/all_wallets_info_provider.dart';
import 'package:stackwallet/wallets/isar/providers/wallet_info_provider.dart';
import 'package:stackwallet/wallets/wallet/wallet.dart';

import '../../sample_data/theme_json.dart';

void main() {
  late platform.Platform originalPlatform;

  setUp(() => originalPlatform = Util.layoutPlatform);
  tearDown(() => Util.layoutPlatform = originalPlatform);

  final token = DefaultTokens.usdc;

  // Wallet.create saves the info to the db before the verify step adds the
  // wallet to pWallets, so the picker can see a wallet it can't look up yet.
  Future<WalletInfo> pumpWithUnregisteredWallet(
    WidgetTester tester,
    _FakeWallets wallets, {
    List<String> walletTokens = const [],
  }) async {
    final info = WalletInfo.createNew(
      coin: Ethereum(CryptoCurrencyNetwork.main),
      name: "new eth wallet",
    );
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pThemeService.overrideWithValue(_TestThemeService(theme)),
          pAllWalletsInfo.overrideWithValue([info]),
          pWallets.overrideWithValue(wallets),
          pWalletTokenAddresses.overrideWithProvider(
            (walletId) => Provider((_) => walletTokens),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: SelectWalletForTokenView(entity: EthTokenEntity(token)),
        ),
      ),
    );
    await tester.pump();
    return info;
  }

  for (final os in ["android", "linux"]) {
    testWidgets("$os picker skips a wallet that isn't registered yet", (
      tester,
    ) async {
      Util.layoutPlatform = platform.FakePlatform(operatingSystem: os);
      await pumpWithUnregisteredWallet(tester, _FakeWallets());

      expect(tester.takeException(), isNull);
      expect(find.text("You do not have any Ethereum wallets"), findsOneWidget);
      expect(find.text("Add new Ethereum wallet"), findsOneWidget);
    });
  }

  testWidgets("picker rebuilds when the new wallet is registered", (
    tester,
  ) async {
    Util.layoutPlatform = platform.FakePlatform(operatingSystem: "android");
    final wallets = _FakeWallets();
    // The wallet already holds the token, so once it is registered the
    // picker shows the "already have" message instead of building a row.
    final info = await pumpWithUnregisteredWallet(
      tester,
      wallets,
      walletTokens: [token.address],
    );
    expect(find.text("You do not have any Ethereum wallets"), findsOneWidget);

    wallets.registered.add(_FakeWallet(info.walletId));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SelectWalletForTokenView)),
    );
    final trigger = container.read(
      newEthWalletTriggerTempUntilHiveCompletelyDeleted.notifier,
    );
    trigger.state = !trigger.state;
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.text("All current Ethereum wallets already have ${token.name}"),
      findsOneWidget,
    );
  });
}

class _TestThemeService extends Fake implements ThemeService {
  _TestThemeService(this.theme);

  final StackTheme theme;

  @override
  StackTheme? getTheme({required String themeId}) => theme;
}

class _FakeWallets extends Fake implements Wallets {
  final List<Wallet> registered = [];

  @override
  List<Wallet> get wallets => registered;
}

class _FakeWallet extends Fake implements Wallet {
  _FakeWallet(this.walletId);

  @override
  final String walletId;
}
