import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/onboarding_view/restore_wallet_form_view.dart';

class RestoreWalletFormViewBot {
  final WidgetTester tester;

  const RestoreWalletFormViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(RestoreWalletFormView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byKey(Key("onboardingAppBarBackButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapScanQrCode() async {
    await tester.tap(find.byKey(Key("restoreWalletViewScanQRButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelScanQrCode() async {
    await tester.tap(find.text("CANCEL"));
    await tester.pumpAndSettle();
  }

  Future<void> tapPaste() async {
    await tester.tap(find.byKey(Key("restoreWalletViewPasteButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapRestore(bool settle) async {
    await tester.tap(find.byKey(Key("restoreMnemonicViewRestoreButtonKey")));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(Duration(seconds: 1));
    }
  }

  Future<void> tapCancelRestore() async {
    await tester
        .tap(find.byKey(Key("restoreWalletWaitingDialogCancelButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> enterWord(String word, int position) async {
    await tester.enterText(
        find.byKey(Key("restoreMnemonicFormField_$position")), word);
  }

  Future<void> scrollDown() async {
    await tester.fling(
        find.byType(SingleChildScrollView), Offset(0, -500), 10000);
    await tester.pumpAndSettle();
  }
}
