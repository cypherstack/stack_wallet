import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/settings_view/settings_subviews/wallet_settings_subviews/rename_wallet_view.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';

class RenameWalletViewBot {
  final WidgetTester tester;

  const RenameWalletViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(RenameWalletView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byKey(Key("settingsAppBarBackButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapSave() async {
    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();
  }

  Future<void> enterWalletName(String name) async {
    await tester.enterText(find.byType(TextField), name);
    await tester.pump();
  }
}
