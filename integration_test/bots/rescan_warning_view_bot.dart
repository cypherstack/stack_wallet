import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/settings_view/settings_subviews/wallet_settings_subviews/rescan_warning_view.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';

class RescanWarningViewBot {
  final WidgetTester tester;

  const RescanWarningViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(RescanWarningView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byKey(Key("settingsAppBarBackButton")));
    await tester.pumpAndSettle();
  }

  Future<void> tapQrCode() async {
    await tester.tap(find.byKey(Key("rescanWarningShowQrCodeButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelQrCode() async {
    await tester
        .tap(find.byKey(Key("rescanWarningQrCodePopupCancelButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCopy() async {
    await tester.tap(find.byKey(Key("rescanWarningCopySeedButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapContinue() async {
    await tester.tap(find.byType(GradientButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapConfirmContinue() async {
    await tester.tap(find.byKey(Key("rescanWarningContinueRescanButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelContinue() async {
    await tester.tap(find.byKey(Key("rescanWarningContinueCancelButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapOkOnRescanFailedDialog() async {
    await tester
        .tap(find.byKey(Key("rescanWarningViewRescanFailedOkButtonKey")));
    await tester.pumpAndSettle();
  }
}
