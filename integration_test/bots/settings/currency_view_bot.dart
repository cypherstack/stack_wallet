import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/settings_view/settings_subviews/currency_view.dart';
import 'package:stackwallet/utilities/cfcolors.dart';

class CurrencyViewBot {
  final WidgetTester tester;

  const CurrencyViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(CurrencyView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byKey(Key("settingsAppBarBackButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCurrency(String code) async {
    await tester.tap(find.text(code));
    await tester.pumpAndSettle();
    final text = find.text(code).evaluate().single.widget as Text;
    expect(text.style!.color, CFColors.spark);
  }
}
