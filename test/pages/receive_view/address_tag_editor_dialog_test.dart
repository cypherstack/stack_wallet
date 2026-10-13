import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/receive_view/addresses/address_tag_data.dart';
import 'package:stackwallet/pages/receive_view/addresses/address_tag_editor_dialog.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:stackwallet/widgets/desktop/primary_button.dart';

import '../../sample_data/theme_json.dart';

void main() {
  Future<void> openEditor(
    WidgetTester tester, {
    required List<String> tags,
    required Future<void> Function(List<String>) onSave,
    bool desktop = false,
    double textScale = 1,
  }) async {
    Util.screenWidth = desktop ? null : 320;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = desktop
        ? const Size(600, 420)
        : const Size(320, 480);
    addTearDown(() {
      Util.screenWidth = null;
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(
              StackTheme.fromJson(json: lightThemeJsonMap),
            ),
          ],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    AddressTagEditorDialog(tags: tags, onSave: onSave),
              ),
              child: const Text("Open editor"),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("Open editor"));
    await tester.pumpAndSettle();
  }

  testWidgets("normalizes additions and limits pasted input", (tester) async {
    List<String>? saved;
    await openEditor(
      tester,
      tags: ["business"],
      onSave: (tags) async => saved = tags,
    );

    final field = find.byType(TextField);
    await tester.enterText(field, " BUSINESS ");
    await tester.pump();
    expect(
      tester
          .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, "Add"))
          .enabled,
      isFalse,
    );

    await tester.enterText(field, List.filled(64, "x").join());
    await tester.pump();
    expect(
      tester.widget<TextField>(field).controller!.text,
      hasLength(maxAddressTagLength),
    );

    await tester.enterText(field, " New Tag ");
    await tester.tap(find.widgetWithText(PrimaryButton, "Add"));
    await tester.pump();
    expect(find.text("new tag"), findsOneWidget);

    final saveButton = find.widgetWithText(PrimaryButton, "Save");
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(saved, ["business", "new tag"]);
    expect(find.byType(AddressTagEditorDialog), findsNothing);
  });

  testWidgets("refuses input that exceeds the tag length in code units", (
    tester,
  ) async {
    await openEditor(tester, tags: const [], onSave: (_) async {});

    // 20 emoji: 20 characters, so the input formatter admits them, but 40
    // UTF-16 code units, which is what the length cap actually measures.
    final emoji = List.filled(20, "\u{1F600}").join();
    final field = find.byType(TextField);
    await tester.enterText(field, emoji);
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, emoji);

    final add = find.widgetWithText(PrimaryButton, "Add");
    expect(tester.widget<PrimaryButton>(add).enabled, isFalse);
    expect(find.text("Tag is too long"), findsOneWidget);
  });

  testWidgets("refuses input with no visible glyphs", (tester) async {
    List<String>? saved;
    await openEditor(
      tester,
      tags: const [],
      onSave: (tags) async => saved = tags,
    );

    await tester.enterText(find.byType(TextField), "\u200b");
    await tester.pump();
    final add = find.widgetWithText(PrimaryButton, "Add");
    expect(tester.widget<PrimaryButton>(add).enabled, isFalse);

    await tester.tap(add, warnIfMissed: false);
    await tester.pump();
    final save = find.widgetWithText(PrimaryButton, "Save");
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(saved, isEmpty);
  });

  testWidgets("keeps a failed save open and allows retry", (tester) async {
    var attempts = 0;
    await openEditor(
      tester,
      tags: const ["personal"],
      onSave: (_) async {
        attempts++;
        if (attempts == 1) {
          throw StateError("disk full");
        }
      },
    );

    final saveButton = find.widgetWithText(PrimaryButton, "Save");
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key("addressTagSaveError")), findsOneWidget);
    expect(find.byType(AddressTagEditorDialog), findsOneWidget);

    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(AddressTagEditorDialog), findsNothing);
  });

  testWidgets("desktop editor scrolls bounded tags without overflow", (
    tester,
  ) async {
    final tags = List.generate(
      maxAddressTagCount,
      (index) => "tag-$index-${List.filled(40, "x").join()}",
    );
    await openEditor(
      tester,
      tags: tags,
      desktop: true,
      textScale: 2,
      onSave: (_) async {},
    );

    expect(
      find.text("Maximum of $maxAddressTagCount tags reached"),
      findsOneWidget,
    );
    expect(find.byTooltip("Remove ${tags.first} tag"), findsOneWidget);
    expect(
      tester
          .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, "Add"))
          .enabled,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
