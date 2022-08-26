import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/onboarding_view/name_your_wallet_view.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';

class NameYourWalletViewBot {
  final WidgetTester tester;

  const NameYourWalletViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(NameYourWalletView));
  }

  Future<void> enterWalletName(String name) async {
    final textFieldFinder = find.byType(TextField);
    await tester.ensureVisible(textFieldFinder);
    await tester.enterText(textFieldFinder, name);
    await tester.pumpAndSettle();
  }

  Future<void> tapNext() async {
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
}
