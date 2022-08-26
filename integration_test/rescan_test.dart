import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stackwallet/main.dart' as campfireApp;

import 'bot_runners/create_wallet_until_pin_confirmation.dart';
import 'bots/lockscreen_view_bot.dart';
import 'bots/main_view_bot.dart';
import 'bots/onboarding/create_pin_view_bot.dart';
import 'bots/onboarding/name_your_wallet_view_bot.dart';
import 'bots/onboarding/onboarding_view_bot.dart';
import 'bots/onboarding/restore_wallet_form_view_bot.dart';
import 'bots/onboarding/terms_and_conditions_bot.dart';
import 'bots/rescan_warning_view_bot.dart';
import 'bots/settings/settings_view_bot.dart';
import 'bots/settings/wallet_settings_view_bot.dart';
import 'private.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets("rescan test", (tester) async {
    campfireApp.main();
    await tester.pumpAndSettle(Duration(seconds: 10));

    // robots
    final onboardingViewBot = OnboardingViewBot(tester);
    final termsAndConditionsViewBot = TermsAndConditionsViewBot(tester);
    final nameYourWalletViewBot = NameYourWalletViewBot(tester);
    final createPinViewBot = CreatePinViewBot(tester);

    // tap restore wallet button
    await onboardingViewBot.ensureVisible();
    await onboardingViewBot.tapRestoreWallet();
    await termsAndConditionsViewBot.ensureVisible();

    await createWalletUntilPinConfirmation(
      termsAndConditionsViewBot,
      nameYourWalletViewBot,
      createPinViewBot,
    );

    await tester.pumpAndSettle(Duration(seconds: 2));
    final restoreWalletFormViewBot = RestoreWalletFormViewBot(tester);
    await restoreWalletFormViewBot.ensureVisible();

    // paste valid mnemonic
    await Clipboard.setData(ClipboardData(text: TEST_MNEMONIC));
    await restoreWalletFormViewBot.tapPaste();
    await restoreWalletFormViewBot.scrollDown();
    await restoreWalletFormViewBot.tapRestore(true);

    final mainViewBot = MainViewBot(tester);
    await mainViewBot.ensureVisible();

    await Future.delayed(Duration(seconds: 10));

    expect(find.byType(ListView, skipOffstage: false), findsNWidgets(1));
    expect(find.text("0.00041252 FIRO"), findsOneWidget);

    // restore should have succeeded by now
    // now we test full rescan
    await mainViewBot.tapSettings();
    final settingsViewBot = SettingsViewBot(tester);
    await settingsViewBot.ensureVisible();
    await settingsViewBot.tapWalletSettings();
    final walletSettingsViewBot = WalletSettingsViewBot(tester);
    await walletSettingsViewBot.ensureVisible();

    // tap rescan wallet and then cancel
    await walletSettingsViewBot.tapFullRescan();
    await walletSettingsViewBot.tapCancelRescanConfirmationDialog();

    // tap rescan and continue running though
    // and testing back taps throughout
    await walletSettingsViewBot.tapFullRescan();
    await walletSettingsViewBot.tapRescanOnRescanConfirmationDialog();
    final lockScreenViewBot = LockscreenViewBot(tester);
    await lockScreenViewBot.ensureVisible();
    await lockScreenViewBot.tapBack();

    await walletSettingsViewBot.tapFullRescan();
    await walletSettingsViewBot.tapRescanOnRescanConfirmationDialog();
    await lockScreenViewBot.ensureVisible();
    await lockScreenViewBot.enterPin("9999");
    await tester.pumpAndSettle(Duration(seconds: 2));
    await lockScreenViewBot.ensureVisible();
    await lockScreenViewBot.tapBack();

    await walletSettingsViewBot.tapFullRescan();
    await walletSettingsViewBot.tapRescanOnRescanConfirmationDialog();
    await lockScreenViewBot.ensureVisible();
    await lockScreenViewBot.enterPin("1234");
    await tester.pumpAndSettle(Duration(seconds: 2));
    final rescanWarningViewBot = RescanWarningViewBot(tester);
    await rescanWarningViewBot.ensureVisible();
    await rescanWarningViewBot.tapBack();
    await walletSettingsViewBot.ensureVisible();

    // tap qr code
    await walletSettingsViewBot.tapFullRescan();
    await walletSettingsViewBot.tapRescanOnRescanConfirmationDialog();
    await lockScreenViewBot.ensureVisible();
    await lockScreenViewBot.enterPin("1234");
    await tester.pumpAndSettle(Duration(seconds: 2));
    await rescanWarningViewBot.ensureVisible();
    await rescanWarningViewBot.tapQrCode();
    await rescanWarningViewBot.tapCancelQrCode();
    await rescanWarningViewBot.ensureVisible();

    // tap copy
    await Clipboard.setData(ClipboardData(text: ""));
    await rescanWarningViewBot.tapCopy();
    final mnemonic = (await Clipboard.getData(Clipboard.kTextPlain))!.text;
    expect(mnemonic, TEST_MNEMONIC);
    await tester.pumpAndSettle(Duration(seconds: 2));
    await Clipboard.setData(ClipboardData(text: ""));
    await rescanWarningViewBot.ensureVisible();

    // tap continue and cancel
    await rescanWarningViewBot.tapContinue();
    await rescanWarningViewBot.tapCancelContinue();
    await rescanWarningViewBot.ensureVisible();

    // tap continue and finally confirm rescan
    await rescanWarningViewBot.tapContinue();
    await rescanWarningViewBot.tapConfirmContinue();

    await mainViewBot.ensureVisible();
    await tester.pumpAndSettle();
    await Future.delayed(Duration(seconds: 10));
    await tester.pumpAndSettle();

    expect(find.text("0.00041252 FIRO"), findsOneWidget);
  });
}
