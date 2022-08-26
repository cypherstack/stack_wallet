import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/onboarding_view/create_pin_view.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_pin_put/pin_keyboard.dart';

class CreatePinViewBot {
  final WidgetTester tester;

  const CreatePinViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(CreatePinView));
  }

  Future<void> enterPin() async {
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "1"));
    await tester.pumpAndSettle(Duration(milliseconds: 500));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "2"));
    await tester.pumpAndSettle(Duration(milliseconds: 500));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "3"));
    await tester.pumpAndSettle(Duration(milliseconds: 500));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "4"));
    await tester.pumpAndSettle(Duration(seconds: 1));
  }

  Future<void> confirmMatchedPin() async {
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "1"));
    await tester.pumpAndSettle(Duration(milliseconds: 500));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "2"));
    await tester.pumpAndSettle(Duration(milliseconds: 500));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "3"));
    await tester.pumpAndSettle(Duration(milliseconds: 500));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "4"));
    await tester.pump(Duration(seconds: 1));
  }

  Future<void> confirmUnmatchedPin() async {
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "7"));
    await tester.pumpAndSettle(Duration(milliseconds: 500));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "9"));
    await tester.pumpAndSettle(Duration(milliseconds: 500));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "8"));
    await tester.pumpAndSettle(Duration(milliseconds: 500));
    await tester.tap(find.byWidgetPredicate(
        (widget) => widget is NumberKey && widget.number == "5"));
    await tester.pump(Duration(seconds: 1));
  }

  Future<void> tapBack() async {
    final buttonFinder = find.byType(AppBarIconButton);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }
}
