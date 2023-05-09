import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/sw_theme.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/themes/defaults/dark.dart';
import 'package:stackwallet/widgets/custom_pin_put/custom_pin_put.dart';
import 'package:stackwallet/widgets/custom_pin_put/pin_keyboard.dart';

void main() {
  group("CustomPinPut tests, non-random PIN", () {
    testWidgets("CustomPinPut with 4 fields builds correctly, non-random PIN",
        (tester) async {
      const pinPut = CustomPinPut(
        fieldsCount: 4,
        isRandom: false,
      );

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
            child: pinPut,
          ),
        ),
      );

      // expects 5 here. Four + the actual text field text
      expect(find.text(""), findsNWidgets(5));
      expect(find.byType(PinKeyboard), findsOneWidget);
      expect(find.byType(BackspaceKey), findsOneWidget);
      expect(find.byType(NumberKey), findsNWidgets(10));
    });

    testWidgets("CustomPinPut entering a pin successfully, non-random PIN",
        (tester) async {
      bool submittedPinMatches = false;
      final pinPut = CustomPinPut(
        fieldsCount: 4,
        onSubmit: (pin) {
          submittedPinMatches = pin == "1234";
          print("pin entered: $pin");
        },
        useNativeKeyboard: false,
        isRandom: false,
      );

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
          home: Material(
            child: pinPut,
          ),
        ),
      );

      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "1"));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "2"));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "6"));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackspaceKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "3"));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "4"));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SubmitKey));
      await tester.pumpAndSettle();

      expect(submittedPinMatches, true);
    });

    testWidgets("CustomPinPut pin enter fade animation, non-random PIN",
        (tester) async {
      final controller = TextEditingController();
      final pinPut = CustomPinPut(
        fieldsCount: 4,
        pinAnimationType: PinAnimationType.fade,
        controller: controller,
        isRandom: false,
      );

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
          home: Material(
            child: pinPut,
          ),
        ),
      );

      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "1"));
      await tester.pumpAndSettle();
      expect(controller.text, "1");

      await tester.tap(find.byType(BackspaceKey));
      await tester.pumpAndSettle();
      expect(controller.text, "");
    });

    testWidgets("CustomPinPut pin enter scale animation, non-random PIN",
        (tester) async {
      final controller = TextEditingController();
      final pinPut = CustomPinPut(
        fieldsCount: 4,
        pinAnimationType: PinAnimationType.scale,
        controller: controller,
        isRandom: false,
      );

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
          home: Material(
            child: pinPut,
          ),
        ),
      );

      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "1"));
      await tester.pumpAndSettle();
      expect(controller.text, "1");

      await tester.tap(find.byType(BackspaceKey));
      await tester.pumpAndSettle();
      expect(controller.text, "");
    });

    testWidgets("CustomPinPut pin enter rotate animation, non-random PIN",
        (tester) async {
      final controller = TextEditingController();
      final pinPut = CustomPinPut(
        fieldsCount: 4,
        pinAnimationType: PinAnimationType.rotation,
        controller: controller,
        isRandom: false,
      );

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
          home: Material(
            child: pinPut,
          ),
        ),
      );

      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "1"));
      await tester.pumpAndSettle();
      expect(controller.text, "1");

      await tester.tap(find.byType(BackspaceKey));
      await tester.pumpAndSettle();
      expect(controller.text, "");
    });
  });

  testWidgets("PinKeyboard builds correctly, non-random PIN", (tester) async {
    final keyboard = PinKeyboard(
      onNumberKeyPressed: (_) {},
      onBackPressed: () {},
      onSubmitPressed: () {},
      isRandom: false,
    );

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
        home: Material(
          child: keyboard,
        ),
      ),
    );

    expect(find.byType(BackspaceKey), findsOneWidget);
    expect(find.byType(SubmitKey), findsOneWidget);
    expect(find.byType(NumberKey), findsNWidgets(10));
    expect(find.text("0"), findsOneWidget);
    expect(find.text("1"), findsOneWidget);
    expect(find.text("2"), findsOneWidget);
    expect(find.text("3"), findsOneWidget);
    expect(find.text("4"), findsOneWidget);
    expect(find.text("5"), findsOneWidget);
    expect(find.text("6"), findsOneWidget);
    expect(find.text("7"), findsOneWidget);
    expect(find.text("8"), findsOneWidget);
    expect(find.text("9"), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(2));
  });

  group("CustomPinPut tests, with random PIN", () {
    testWidgets("CustomPinPut with 4 fields builds correctly, with random PIN",
        (tester) async {
      const pinPut = CustomPinPut(
        fieldsCount: 4,
        isRandom: true,
      );

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
            child: pinPut,
          ),
        ),
      );

      // expects 5 here. Four + the actual text field text
      expect(find.text(""), findsNWidgets(5));
      expect(find.byType(PinKeyboard), findsOneWidget);
      expect(find.byType(BackspaceKey), findsOneWidget);
      expect(find.byType(NumberKey), findsNWidgets(10));
    });

    testWidgets("CustomPinPut entering a pin successfully, with random PIN",
        (tester) async {
      bool submittedPinMatches = false;
      final pinPut = CustomPinPut(
        fieldsCount: 4,
        onSubmit: (pin) {
          submittedPinMatches = pin == "1234";
          print("pin entered: $pin");
        },
        useNativeKeyboard: false,
        isRandom: true,
      );

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
          home: Material(
            child: pinPut,
          ),
        ),
      );

      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "1"));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "2"));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "6"));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackspaceKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "3"));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "4"));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SubmitKey));
      await tester.pumpAndSettle();

      expect(submittedPinMatches, true);
    });

    testWidgets("CustomPinPut pin enter fade animation, with random PIN",
        (tester) async {
      final controller = TextEditingController();
      final pinPut = CustomPinPut(
        fieldsCount: 4,
        pinAnimationType: PinAnimationType.fade,
        controller: controller,
        isRandom: true,
      );

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
          home: Material(
            child: pinPut,
          ),
        ),
      );

      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "1"));
      await tester.pumpAndSettle();
      expect(controller.text, "1");

      await tester.tap(find.byType(BackspaceKey));
      await tester.pumpAndSettle();
      expect(controller.text, "");
    });

    testWidgets("CustomPinPut pin enter scale animation, with random PIN",
        (tester) async {
      final controller = TextEditingController();
      final pinPut = CustomPinPut(
        fieldsCount: 4,
        pinAnimationType: PinAnimationType.scale,
        controller: controller,
        isRandom: true,
      );

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
          home: Material(
            child: pinPut,
          ),
        ),
      );

      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "1"));
      await tester.pumpAndSettle();
      expect(controller.text, "1");

      await tester.tap(find.byType(BackspaceKey));
      await tester.pumpAndSettle();
      expect(controller.text, "");
    });

    testWidgets("CustomPinPut pin enter rotate animation, with random PIN",
        (tester) async {
      final controller = TextEditingController();
      final pinPut = CustomPinPut(
        fieldsCount: 4,
        pinAnimationType: PinAnimationType.rotation,
        controller: controller,
        isRandom: true,
      );

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
          home: Material(
            child: pinPut,
          ),
        ),
      );

      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == "1"));
      await tester.pumpAndSettle();
      expect(controller.text, "1");

      await tester.tap(find.byType(BackspaceKey));
      await tester.pumpAndSettle();
      expect(controller.text, "");
    });
  });

  testWidgets("PinKeyboard builds correctly, with random PIN", (tester) async {
    final keyboard = PinKeyboard(
      onNumberKeyPressed: (_) {},
      onBackPressed: () {},
      onSubmitPressed: () {},
      isRandom: true,
    );

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
        home: Material(
          child: keyboard,
        ),
      ),
    );

    expect(find.byType(BackspaceKey), findsOneWidget);
    expect(find.byType(SubmitKey), findsOneWidget);
    expect(find.byType(NumberKey), findsNWidgets(10));
    expect(find.text("0"), findsOneWidget);
    expect(find.text("1"), findsOneWidget);
    expect(find.text("2"), findsOneWidget);
    expect(find.text("3"), findsOneWidget);
    expect(find.text("4"), findsOneWidget);
    expect(find.text("5"), findsOneWidget);
    expect(find.text("6"), findsOneWidget);
    expect(find.text("7"), findsOneWidget);
    expect(find.text("8"), findsOneWidget);
    expect(find.text("9"), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(2));
  });
}
