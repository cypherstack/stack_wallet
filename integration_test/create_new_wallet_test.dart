import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stackwallet/main.dart' as campfireApp;
import 'package:stackwallet/pages/main_view.dart';

import 'bot_runners/create_wallet_until_pin_confirmation.dart';
import 'bots/onboarding/backup_key_view_bot.dart';
import 'bots/onboarding/backup_key_warning_bot.dart';
import 'bots/onboarding/create_pin_view_bot.dart';
import 'bots/onboarding/name_your_wallet_view_bot.dart';
import 'bots/onboarding/onboarding_view_bot.dart';
import 'bots/onboarding/terms_and_conditions_bot.dart';
import 'bots/onboarding/verify_backup_key_view_bot.dart';

void main() {
  group("Campfire app test", () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    testWidgets("new wallet creation", (tester) async {
      campfireApp.main();
      await tester.pumpAndSettle(Duration(seconds: 10));

      final onboardingViewBot = OnboardingViewBot(tester);
      final termsAndConditionsViewBot = TermsAndConditionsViewBot(tester);
      final nameYourWalletViewBot = NameYourWalletViewBot(tester);
      final createPinViewBot = CreatePinViewBot(tester);
      final backupKeyWarningViewBot = BackupKeyWarningViewBot(tester);
      final backupKeyViewBot = BackupKeyViewBot(tester);
      final verifyBackUpViewBot = VerifyBackupKeyViewBot(tester);

      // tap create new wallet button
      await onboardingViewBot.ensureVisible();
      await onboardingViewBot.tapCreateNewWallet();

      await termsAndConditionsViewBot.ensureVisible();
      // test tap back
      await termsAndConditionsViewBot.tapBack();
      await onboardingViewBot.ensureVisible();
      // tap new again
      await onboardingViewBot.tapCreateNewWallet();

      await createWalletUntilPinConfirmation(
        termsAndConditionsViewBot,
        nameYourWalletViewBot,
        createPinViewBot,
      );

      // wait for wallet generation
      await tester.pumpAndSettle(Duration(seconds: 60));

      await backupKeyWarningViewBot.ensureVisible();

      // tap back
      await backupKeyWarningViewBot.tapBack();
      await onboardingViewBot.ensureVisible();

      // tap create new wallet button
      await onboardingViewBot.ensureVisible();
      await onboardingViewBot.tapCreateNewWallet();

      await termsAndConditionsViewBot.ensureVisible();
      // test tap back
      await termsAndConditionsViewBot.tapBack();
      await onboardingViewBot.ensureVisible();
      // tap new again
      await onboardingViewBot.tapCreateNewWallet();

      // run through to backup key warning again
      await createWalletUntilPinConfirmation(
        termsAndConditionsViewBot,
        nameYourWalletViewBot,
        createPinViewBot,
      );

      // wait for wallet generation
      await tester.pumpAndSettle(Duration(seconds: 60));

      await backupKeyWarningViewBot.ensureVisible();

      // enable checkbox
      await backupKeyWarningViewBot.tapCheckBox();
      await backupKeyWarningViewBot.tapViewBackupKey();

      // expect to see mnemonic displayed
      await backupKeyViewBot.ensureVisible();

      // tap back
      await backupKeyViewBot.tapBack();
      await backupKeyWarningViewBot.ensureVisible();

      // advance again
      await backupKeyWarningViewBot.tapViewBackupKey();
      // expect to see mnemonic displayed again
      await backupKeyViewBot.ensureVisible();

      // tap qr code
      await backupKeyViewBot.tapQrCode();
      // tap cancel to pop qr code view
      await tester.tap(find.byKey(Key("backUpKeyViewQrCodeCancelButtonKey")));
      await tester.pumpAndSettle();

      // tap copy
      await backupKeyViewBot.tapCopy();

      // fetch words to verify on next page
      final words = await backupKeyViewBot.displayedMnemonic();

      // tap verify to go to next screen
      await backupKeyViewBot.tapVerify();
      // expect next screen
      await verifyBackUpViewBot.ensureVisible();

      // ensure overlay from previous copy function has gone away
      await tester.pumpAndSettle(Duration(seconds: 2));

      // tap back
      await verifyBackUpViewBot.tapBack();
      await backupKeyViewBot.ensureVisible();

      // continue forward again
      await backupKeyViewBot.tapVerify();
      // expect next screen again
      await verifyBackUpViewBot.ensureVisible();

      // enter requested word
      await verifyBackUpViewBot.enterRequestedWord(words);
      // tap confirm to check validity
      await verifyBackUpViewBot.tapConfirm();

      // expect main wallet view
      expect(find.byType(MainView), findsOneWidget);
    });
  });
}
