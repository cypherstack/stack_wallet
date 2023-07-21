import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/widgets/desktop/desktop_scaffold.dart';

import '../../sample_data/theme_json.dart';
import 'desktop_scaffold_test.mocks.dart';

@GenerateMocks([
  ThemeService,
])
void main() {
  testWidgets("test DesktopScaffold", (widgetTester) async {
    final key = UniqueKey();
    final mockThemeService = MockThemeService();
    when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
      (_) => StackTheme.fromJson(
        json: lightThemeJsonMap,
      ),
    );
    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          pThemeService.overrideWithValue(mockThemeService),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(
                  json: lightThemeJsonMap,
                ),
              ),
            ],
          ),
          home: Material(
            child: DesktopScaffold(
              key: key,
              body: const SizedBox(),
            ),
          ),
        ),
      ),
    );
  });

  testWidgets("Test MasterScaffold for non desktop", (widgetTester) async {
    final key = UniqueKey();
    final mockThemeService = MockThemeService();
    when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
      (_) => StackTheme.fromJson(
        json: lightThemeJsonMap,
      ),
    );

    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          pThemeService.overrideWithValue(mockThemeService),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(
                  json: lightThemeJsonMap,
                ),
              ),
            ],
          ),
          home: Material(
            child: MasterScaffold(
              key: key,
              body: const SizedBox(),
              appBar: AppBar(),
              isDesktop: false,
            ),
          ),
        ),
      ),
    );
  });

  testWidgets("Test MasterScaffold for desktop", (widgetTester) async {
    final key = UniqueKey();
    final mockThemeService = MockThemeService();

    when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
      (_) => StackTheme.fromJson(
        json: lightThemeJsonMap,
      ),
    );

    await widgetTester.pumpWidget(
      ProviderScope(
        overrides: [
          pThemeService.overrideWithValue(mockThemeService),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(
                  json: lightThemeJsonMap,
                ),
              ),
            ],
          ),
          home: Material(
            child: MasterScaffold(
              key: key,
              body: const SizedBox(),
              appBar: AppBar(),
              isDesktop: true,
            ),
          ),
        ),
      ),
    );
  });
}
