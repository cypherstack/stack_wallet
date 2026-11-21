import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/app_config.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/advanced_views/manage_explorer_view.dart';
import 'package:stackwallet/pages_desktop_specific/settings/settings_menu/advanced_settings/desktop_manage_block_explorers_dialog.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/themes/coin_icon_provider.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_providers.dart';
import 'package:stackwallet/utilities/block_explorers.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/widgets/choose_coin_view.dart';

import '../../sample_data/theme_json.dart';

class _TestPrefs extends ChangeNotifier implements Prefs {
  @override
  bool get showTestNetCoins => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final epic = Epiccash(CryptoCurrencyNetwork.main);
  final mwc = Mimblewimblecoin(CryptoCurrencyNetwork.main);
  final bitcoin = Bitcoin(CryptoCurrencyNetwork.main);

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousThemesDir = StackFileSystem.themesDir;
    addTearDown(() => StackFileSystem.themesDir = previousThemesDir);
    StackFileSystem.themesDir = Directory('test/sample_data').absolute;
    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    final icon = File('test/sample_data/light/assets/dummy.svg').absolute.path;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsChangeNotifierProvider.overrideWithValue(_TestPrefs()),
          themeProvider.overrideWithProvider(StateProvider((ref) => theme)),
          coinIconProvider.overrideWithProvider((_) => Provider((_) => icon)),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: home,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  test('Epic Cash and MWC have no default block explorer', () {
    expect(hasDefaultBlockExplorer(epic), isFalse);
    expect(hasDefaultBlockExplorer(mwc), isFalse);
    expect(hasDefaultBlockExplorer(bitcoin), isTrue);
  });

  test('the app offers Epic Cash, MWC and Bitcoin', () {
    expect(AppConfig.coins, containsAll([epic, mwc, bitcoin]));
  });

  testWidgets('the mobile explorer list leaves out coins without an explorer', (
    tester,
  ) async {
    await pump(
      tester,
      const ChooseCoinView(
        title: 'Manage block explorers',
        coinAdditional: 'block explorer',
        nextRouteName: ManageExplorerView.routeName,
      ),
    );

    expect(find.text('${bitcoin.prettyName} block explorer'), findsOneWidget);
    expect(find.text('${epic.prettyName} block explorer'), findsNothing);
    expect(find.text('${mwc.prettyName} block explorer'), findsNothing);
  });

  testWidgets(
    'the desktop explorer list leaves out coins without an explorer',
    (tester) async {
      await pump(
        tester,
        const Scaffold(body: DesktopManageBlockExplorersDialog()),
      );

      expect(find.text('${bitcoin.prettyName} block explorer'), findsOneWidget);
      expect(find.text('${epic.prettyName} block explorer'), findsNothing);
      expect(find.text('${mwc.prettyName} block explorer'), findsNothing);
    },
  );
}
