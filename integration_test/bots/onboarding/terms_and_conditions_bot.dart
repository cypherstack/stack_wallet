import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/onboarding_view/terms_and_conditions_view.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';

class TermsAndConditionsViewBot {
  final WidgetTester tester;

  const TermsAndConditionsViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(TermsAndConditionsView));
  }

  Future<void> tapIAccept() async {
    final buttonFinder = find.byType(GradientButton);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapBack() async {
    final buttonFinder = find.byType(AppBarIconButton);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> scrollDown() async {
    await tester.fling(
        find.byType(SingleChildScrollView), Offset(0, -1000), 10000);
    await tester.pumpAndSettle();
  }

  Future<void> scrollUp() async {
    await tester.fling(
        find.byType(SingleChildScrollView), Offset(0, 1000), 10000);
    await tester.pumpAndSettle();
  }
}
