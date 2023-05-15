import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/theme_service.dart';
import 'package:stackwallet/widgets/custom_buttons/favorite_toggle.dart';

import '../../sample_data/theme_json.dart';
import 'favorite_toggle_test.mocks.dart';

@GenerateMocks([
  ThemeService,
])
void main() {
  testWidgets("Test widget build", (widgetTester) async {
    final key = UniqueKey();
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
          home: FavoriteToggle(
            onChanged: null,
            key: key,
          ),
        ),
      ),
    );

    expect(find.byType(FavoriteToggle), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
