import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart' as mockingjay;
import 'package:stackwallet/models/isar/sw_theme.dart';
import 'package:stackwallet/themes/defaults/dark.dart';
import 'package:stackwallet/utilities/theme/stack_colors.dart';
import 'package:stackwallet/widgets/emoji_select_sheet.dart';

void main() {
  testWidgets("Widget displays correctly", (tester) async {
    const emojiSelectSheet = EmojiSelectSheet();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(
                json: darkJson,
                applicationThemesDirectoryPath: "",
              ),
            ),
          ],
        ),
        home: const Material(
          child: emojiSelectSheet,
        ),
      ),
    );

    expect(find.byWidget(emojiSelectSheet), findsOneWidget);
    expect(find.text("Select emoji"), findsOneWidget);
  });

  testWidgets("Emoji tapped test", (tester) async {
    const emojiSelectSheet = EmojiSelectSheet();

    final navigator = mockingjay.MockNavigator();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              StackColors.fromStackColorTheme(
                StackTheme.fromJson(
                  json: darkJson,
                  applicationThemesDirectoryPath: "",
                ),
              ),
            ],
          ),
          home: mockingjay.MockNavigatorProvider(
            navigator: navigator,
            child: Column(
              children: const [
                Expanded(child: emojiSelectSheet),
              ],
            ),
          ),
        ),
      ),
    );

    final gestureDetector = find.byType(GestureDetector).at(5);
    expect(gestureDetector, findsOneWidget);

    final emoji = Emoji.byChar("😅");

    await tester.tap(gestureDetector);
    await tester.pumpAndSettle();
    mockingjay.verify(() => navigator.pop(emoji)).called(1);
  });
}
