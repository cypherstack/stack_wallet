import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/widgets/wallet_navigation_bar/components/wallet_navigation_bar_item.dart';

import '../sample_data/theme_json.dart';

void main() {
  testWidgets('a Slatepack label fits a 57.6 dp navigation item', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final theme = StackTheme.fromJson(json: lightThemeJsonMap);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            extensions: [StackColors.fromStackColorTheme(theme)],
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 57.6,
                height: 61,
                child: WalletNavigationBarItem(
                  data: WalletNavigationBarItemData(
                    icon: const Icon(Icons.description, size: 20),
                    label: 'Slatepack',
                    overrideText: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Slatepack', maxLines: 1, softWrap: false),
                    ),
                    onTap: () {},
                  ),
                  disableDuration: Duration.zero,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Slatepack'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
