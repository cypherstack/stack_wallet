import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/onboarding_view/backup_key_warning_view.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';

class BackupKeyWarningViewBot {
  final WidgetTester tester;

  const BackupKeyWarningViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(BackupKeyWarningView));
  }

  Future<void> tapViewBackupKey() async {
    final buttonFinder = find.byType(GradientButton);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapCheckBox() async {
    final buttonFinder = find.byType(Checkbox);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapSkip() async {
    final buttonFinder = find.byType(TextButton);
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
