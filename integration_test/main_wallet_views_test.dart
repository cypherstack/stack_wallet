import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stackwallet/main.dart' as campfireApp;

import 'bot_runners/create_wallet_until_pin_confirmation.dart';
import 'bots/main_view_bot.dart';
import 'bots/onboarding/backup_key_warning_bot.dart';
import 'bots/onboarding/create_pin_view_bot.dart';
import 'bots/onboarding/name_your_wallet_view_bot.dart';
import 'bots/onboarding/onboarding_view_bot.dart';
import 'bots/onboarding/terms_and_conditions_bot.dart';
import 'bots/receive_view_bot.dart';
import 'bots/send_view_bot.dart';
import 'bots/settings/settings_view_bot.dart';
import 'bots/transaction/transaction_search_view_bot.dart';
import 'bots/wallet_view_bot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets("wallet, send, and receive view test", (tester) async {
    campfireApp.main();
    await tester.pumpAndSettle(Duration(seconds: 10));

    // robots
    final onboardingViewBot = OnboardingViewBot(tester);
    final termsAndConditionsViewBot = TermsAndConditionsViewBot(tester);
    final nameYourWalletViewBot = NameYourWalletViewBot(tester);
    final createPinViewBot = CreatePinViewBot(tester);
    final backupKeyWarningViewBot = BackupKeyWarningViewBot(tester);
    final mainViewBot = MainViewBot(tester);
    final settingsViewBot = SettingsViewBot(tester);
    final walletViewBot = WalletViewBot(tester);
    final transactionSearchViewBot = TransactionSearchViewBot(tester);
    final sendViewBot = SendViewBot(tester);
    final receiveViewBot = ReceiveViewBot(tester);

    // tap create new wallet button
    await onboardingViewBot.ensureVisible();
    await onboardingViewBot.tapCreateNewWallet();
    await termsAndConditionsViewBot.ensureVisible();

    await createWalletUntilPinConfirmation(
      termsAndConditionsViewBot,
      nameYourWalletViewBot,
      createPinViewBot,
    );

    // wait for wallet generation
    await tester.pumpAndSettle(Duration(seconds: 60));

    await backupKeyWarningViewBot.ensureVisible();

    // tap skip to load into main wallet view
    await backupKeyWarningViewBot.tapSkip();

    await mainViewBot.ensureVisible();

    // tap refresh
    await mainViewBot.tapRefresh();

    // tap settings button
    await mainViewBot.tapSettings();
    await settingsViewBot.ensureVisible();

    // tap back to main wallet view
    await settingsViewBot.tapBack();
    await mainViewBot.ensureVisible();

    await walletViewBot.ensureVisible();

    // wait for refresh notification that covers switch to disappear
    await tester.pumpAndSettle(Duration(seconds: 3));

    // tap switch
    await walletViewBot.tapAvailableFullSwitch();
    await walletViewBot.checkAvailableFullSwitchIsDisabled();

    // drag switch
    await walletViewBot.dragAvailableFullSwitchRight();
    await walletViewBot.checkAvailableFullSwitchIsDisabled();

    // drag switch
    await walletViewBot.dragAvailableFullSwitchLeft();
    await walletViewBot.checkAvailableFullSwitchIsEnabled();

    // tap switch again
    await walletViewBot.tapAvailableFullSwitch();
    await walletViewBot.checkAvailableFullSwitchIsDisabled();

    // tap tx search
    await walletViewBot.tapTransactionSearch();
    await transactionSearchViewBot.ensureVisible();

    // go back
    await transactionSearchViewBot.tapX();
    await walletViewBot.ensureVisible();

    // go to send tab
    await mainViewBot.tapSend();
    await sendViewBot.ensureVisible();

    // go to receive tab
    await mainViewBot.tapReceive();
    await receiveViewBot.ensureVisible();
  });
}
