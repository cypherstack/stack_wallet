import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/settings_view/settings_subviews/wallet_backup_view.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';

class WalletBackUpViewBot {
  final WidgetTester tester;

  const WalletBackUpViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(WalletBackUpView));
  }

  Future<void> tapBack() async {
    await tester.tap(find.byType(AppBarIconButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapQrCode() async {
    await tester.tap(find.byKey(Key("walletBackupQrCodeButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapQrCodeCancel() async {
    await tester.tap(find.byKey(Key("walletBackupQrCodeCancelButtonKey")));
    await tester.pumpAndSettle();
  }

  Future<void> tapCopy() async {
    await tester.tap(find.byKey(Key("walletBackupCopyButtonKey")));
    await tester.pumpAndSettle();
  }
}
