import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epicmobile/utilities/theme/light_colors.dart';
import 'package:epicmobile/utilities/theme/stack_colors.dart';
import 'package:epicmobile/widgets/custom_buttons/draggable_switch_button.dart';

void main() {
  testWidgets("DraggableSwitchButton tapped", (tester) async {
    bool? isButtonOn = false;
    final button = DraggableSwitchButton(
      onItem: const Text("yes"),
      offItem: const Text("no"),
      onValueChanged: (newValue) => isButtonOn = newValue,
      enabled: false,
      isOn: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(LightColors()),
          ],
        ),
        home: button,
      ),
    );

    await tester.tap(find.byType(DraggableSwitchButton));
    await tester.pumpAndSettle();

    expect(isButtonOn, true);
  });

  testWidgets("DraggableSwitchButton dragged off", (tester) async {
    bool? isButtonOn = true;
    final button = DraggableSwitchButton(
      onItem: const Text("yes"),
      offItem: const Text("no"),
      onValueChanged: (newValue) => isButtonOn = newValue,
      enabled: true,
      isOn: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(LightColors()),
          ],
        ),
        home: SizedBox(
          width: 200,
          height: 60,
          child: button,
        ),
      ),
    );

    await tester.drag(find.byKey(const Key("draggableSwitchButtonSwitch")),
        const Offset(-800, 0));
    await tester.pumpAndSettle();

    expect(isButtonOn, false);
  });

  testWidgets("DraggableSwitchButton dragged on", (tester) async {
    bool? isButtonOn = false;
    final button = DraggableSwitchButton(
      onItem: const Text("yes"),
      offItem: const Text("no"),
      onValueChanged: (newValue) => isButtonOn = newValue,
      enabled: true,
      isOn: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            StackColors.fromStackColorTheme(LightColors()),
          ],
        ),
        home: SizedBox(
          width: 200,
          height: 60,
          child: button,
        ),
      ),
    );

    await tester.drag(find.byKey(const Key("draggableSwitchButtonSwitch")),
        const Offset(800, 0));
    await tester.pumpAndSettle();

    expect(isButtonOn, true);
  });
}
