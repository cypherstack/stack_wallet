import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/models/isar/stack_theme.dart';
import 'package:stackwallet/pages/send_view/sub_widgets/save_recipient_controls.dart';
import 'package:stackwallet/themes/stack_colors.dart';
import 'package:stackwallet/widgets/custom_buttons/draggable_switch_button.dart';

import '../../sample_data/theme_json.dart';

void main() {
  for (final isDesktop in [false, true]) {
    testWidgets(
      '${isDesktop ? 'desktop' : 'mobile'} contact saving is opt-in',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              extensions: [
                StackColors.fromStackColorTheme(
                  StackTheme.fromJson(json: lightThemeJsonMap),
                ),
              ],
            ),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(240, 600),
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: SizedBox(
                  width: 240,
                  child: _Harness(isDesktop: isDesktop),
                ),
              ),
            ),
          ),
        );

        expect(_isOn(tester), isFalse);
        expect(find.byType(TextField), findsNothing);

        await tester.tap(find.byType(DraggableSwitchButton));
        await tester.pump();

        expect(_isOn(tester), isTrue);
        expect(find.byType(TextField), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

bool _isOn(WidgetTester tester) => tester
    .widget<DraggableSwitchButton>(find.byType(DraggableSwitchButton))
    .isOn;

class _Harness extends StatefulWidget {
  const _Harness({required this.isDesktop});

  final bool isDesktop;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  var enabled = false;

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SaveRecipientControls(
      enabled: enabled,
      isDesktop: widget.isDesktop,
      onChanged: (value) => setState(() => enabled = value),
      controller: controller,
      focusNode: focusNode,
    );
  }
}
