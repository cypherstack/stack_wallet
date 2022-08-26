import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/onboarding_view/onboarding_view.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_button.dart';

class OnboardingViewBot {
  final WidgetTester tester;

  const OnboardingViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(OnboardingView));
  }

  Future<void> tapCreateNewWallet() async {
    final buttonFinder = find.byType(GradientButton);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapRestoreWallet() async {
    final buttonFinder = find.byType(SimpleButton);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }
}
