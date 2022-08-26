import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/settings_view/settings_subviews/wallet_settings_subviews/wallet_delete_mnemonic_view.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';

class WalletDeleteMnemonicViewBot {
  final WidgetTester tester;

  const WalletDeleteMnemonicViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(WalletDeleteMnemonicView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byKey(Key("settingsAppBarBackButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapQrCode() async {
    await tester.tap(find.byKey(Key("walletDeleteShowQrCodeButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelQrCode() async {
    await tester.tap(find.byKey(Key("deleteWalletQrCodePopupCancelButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCopy() async {
    await tester.tap(find.byKey(Key("walletDeleteCopySeedButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapContinue() async {
    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapConfirmContinue() async {
    await tester.tap(find.byKey(Key("walletDeleteContinueDeleteButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelContinue() async {
    await tester.tap(find.byKey(Key("walletDeleteContinueCancelButtonKey")));
    await tester.pumpAndSettle();
  }
}
