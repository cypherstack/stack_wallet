import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stackwallet/main.dart' as campfireApp;
import 'package:stackwallet/notifications/campfire_alert.dart';
import 'package:stackwallet/pages/main_view.dart';

import 'bot_runners/create_wallet_until_pin_confirmation.dart';
import 'bots/onboarding/create_pin_view_bot.dart';
import 'bots/onboarding/name_your_wallet_view_bot.dart';
import 'bots/onboarding/onboarding_view_bot.dart';
import 'bots/onboarding/restore_wallet_form_view_bot.dart';
import 'bots/onboarding/terms_and_conditions_bot.dart';
import 'private.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets("restore from seed test", (tester) async {
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

    // test back
    await restoreWalletFormViewBot.tapBack();
    await onboardingViewBot.ensureVisible();
    await onboardingViewBot.tapRestoreWallet();
    await termsAndConditionsViewBot.ensureVisible();
    await createWalletUntilPinConfirmation(
      termsAndConditionsViewBot,
      nameYourWalletViewBot,
      createPinViewBot,
    );
    await tester.pumpAndSettle();
    await restoreWalletFormViewBot.ensureVisible();

    // open qr scanner and cancel
    // this test fails due to system popup?
    // await restoreWalletFormViewBot.tapScanQrCode();
    // await tester.tap(find.text("ONLY THIS TIME"));
    // await tester.pumpAndSettle();
    // await restoreWalletFormViewBot.tapCancelScanQrCode();
    // await restoreWalletFormViewBot.ensureVisible();

    // paste invalid mnemonic test
    await Clipboard.setData(ClipboardData(
        text:
            "some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words some mnemonic words"));
    await restoreWalletFormViewBot.tapPaste();
    await restoreWalletFormViewBot.scrollDown();
    expect(find.text("Please check spelling", skipOffstage: false),
        findsNWidgets(24));
    expect(find.text("some", skipOffstage: false), findsNWidgets(8));
    expect(find.text("mnemonic", skipOffstage: false), findsNWidgets(8));
    expect(find.text("words", skipOffstage: false), findsNWidgets(8));

    // tap restore on invalid mnemonic words
    await restoreWalletFormViewBot.tapRestore(true);
    await restoreWalletFormViewBot.ensureVisible();

    // paste valid mnemonic
    await Clipboard.setData(ClipboardData(text: TEST_MNEMONIC));
    await restoreWalletFormViewBot.tapPaste();
    await restoreWalletFormViewBot.scrollDown();

    // enter a valid word which gives us an invalid mnemonic
    await restoreWalletFormViewBot.enterWord("old", 24);
    await restoreWalletFormViewBot.tapRestore(true);
    expect(find.byType(CampfireAlert), findsOneWidget);
    await tester.tap(find.byKey(Key("campfireAlertOKButtonKey")));
    await tester.pumpAndSettle();
    expect(find.byType(CampfireAlert), findsNothing);

    // re paste valid mnemonic, restore, and cancel
    await Clipboard.setData(ClipboardData(text: TEST_MNEMONIC));
    await restoreWalletFormViewBot.tapPaste();
    await restoreWalletFormViewBot.scrollDown();
    await restoreWalletFormViewBot.tapRestore(false);
    await restoreWalletFormViewBot.tapCancelRestore();
    await onboardingViewBot.ensureVisible();

    // full restore
    await onboardingViewBot.tapRestoreWallet();
    await termsAndConditionsViewBot.ensureVisible();
    await createWalletUntilPinConfirmation(
      termsAndConditionsViewBot,
      nameYourWalletViewBot,
      createPinViewBot,
    );
    await tester.pumpAndSettle();
    await restoreWalletFormViewBot.ensureVisible();
    await Clipboard.setData(ClipboardData(text: TEST_MNEMONIC));
    await restoreWalletFormViewBot.tapPaste();
    await restoreWalletFormViewBot.scrollDown();
    await restoreWalletFormViewBot.tapRestore(true);

    expect(find.byType(MainView), findsOneWidget);

    await Future.delayed(Duration(seconds: 10));

    expect(find.byType(ListView, skipOffstage: false), findsNWidgets(1));
    expect(find.text("0.00041252 FIRO"), findsOneWidget);
  });
}
