import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/widgets/custom_loading_overlay.dart';

import '../sample_data/theme_json.dart';
import 'custom_loading_overlay_test.mocks.dart';

@GenerateMocks([
  ThemeService,
])
void main() {
  testWidgets("Test widget displays correct text", (widgetTester) async {
    final eventBus = EventBus();
    final mockThemeService = MockThemeService();
    when(mockThemeService.getTheme(themeId: "light")).thenAnswer(
      (_) => StackTheme.fromJson(
        json: lightThemeJsonMap,
        applicationThemesDirectoryPath: "test",
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
                  applicationThemesDirectoryPath: "test",
                ),
              ),
            ],
          ),
          home: Material(
            child: CustomLoadingOverlay(
                message: "Updating exchange rate", eventBus: eventBus),
          ),
        ),
      ),
    );

    expect(find.text("Updating exchange rate"), findsOneWidget);
  });
}
