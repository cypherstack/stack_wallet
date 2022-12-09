import 'package:emojis/emoji.dart';
import 'package:epicmobile/utilities/theme/light_colors.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/emoji_select_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart' as mockingjay;

void main() {
  testWidgets("Widget displays correctly", (tester) async {
    const emojiSelectSheet = EmojiSelectSheet();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(LightColors()),
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
              StackColors.fromStackColorTheme(LightColors()),
            ],
          ),
          home: mockingjay.MockNavigatorProvider(
              navigator: navigator, child: emojiSelectSheet),
        ),
      ),
    );

    final gestureDetector = find.byType(GestureDetector).first;
    expect(gestureDetector, findsOneWidget);

    final emoji = Emoji.all()[0];

    await tester.tap(gestureDetector);
    await tester.pumpAndSettle();
    mockingjay.verify(() => navigator.pop(emoji)).called(1);
  });
}
