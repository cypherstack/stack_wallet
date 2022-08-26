import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/onboarding_view/verify_backup_key_view.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';

class VerifyBackupKeyViewBot {
  final WidgetTester tester;

  const VerifyBackupKeyViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(VerifyBackupKeyView));
  }

  Future<void> tapConfirm() async {
    await tester.fling(
        find.byType(SingleChildScrollView), Offset(0, -500), 1000);
    await tester.pumpAndSettle();
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

  Future<void> enterRequestedWord(List<String?> words) async {
    String text = (find
            .byKey(Key("nThWordVerificationString"))
            .evaluate()
            .single
            .widget as Text)
        .data!;

    int? index;

    if (text.length == 33) {
      index = int.parse(text.substring(9, 11));
    } else if (text.length == 32) {
      index = int.parse(text.substring(9, 10));
    }

    if (index == null) {
      throw Exception("Backup key verification text string failed test");
    }

    await tester.enterText(find.byType(TextField), words[index - 1]!);
    await tester.pumpAndSettle();
  }
}
