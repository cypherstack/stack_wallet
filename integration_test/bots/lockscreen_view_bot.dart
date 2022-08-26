import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/lockscreen_view.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_pin_put/pin_keyboard.dart';

class LockscreenViewBot {
  final WidgetTester tester;

  const LockscreenViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(LockscreenView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byType(AppBarIconButton));
    await tester.pumpAndSettle();
  }

  Future<void> enterPin(String pin) async {
    for (int i = 0; i < pin.length - 1; i++) {
      await tester.tap(find.byWidgetPredicate(
          (widget) => widget is NumberKey && widget.number == pin[i]));
      await tester.pumpAndSettle(Duration(milliseconds: 500));
    }
    await tester.tap(find.byWidgetPredicate((widget) =>
        widget is NumberKey && widget.number == pin[pin.length - 1]));
    await tester.pumpAndSettle(Duration(seconds: 1));
  }
}
