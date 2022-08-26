import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stackwallet/pages/onboarding_view/backup_key_view.dart';
import 'package:stackwallet/utilities/misc_global_constants.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';

class BackupKeyViewBot {
  final WidgetTester tester;

  const BackupKeyViewBot(this.tester);

  Future<void> ensureVisible() async {
    await tester.ensureVisible(find.byType(BackupKeyView));
  }

  Future<void> tapVerify() async {
    final buttonFinder = find.byType(GradientButton);
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapQrCode() async {
    final buttonFinder = find.byKey(Key("backupKeyQrCodeButtonKey"));
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

  Future<void> tapCopy() async {
    final buttonFinder = find.byKey(Key("backupKeyViewCopyButtonKey"));
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

  Future<List<String?>> displayedMnemonic() async {
    List<String?> words = [];
    for (int i = 0; i < CampfireConstants.seedPhraseWordCount; i++) {
      final text = find
          .byKey(Key("mnemonic_word_text_$i"))
          .evaluate()
          .single
          .widget as Text;

      words.add(text.data);
    }
    return words;
  }
}
