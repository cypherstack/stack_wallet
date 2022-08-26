import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stackwallet/main.dart' as campfireApp;
import 'package:stackwallet/notifications/modal_popup_dialog.dart';
import 'package:stackwallet/pages/settings_view/settings_subviews/network_settings_subviews/add_custom_node_view.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/widgets/custom_buttons/gradient_button.dart';
import 'package:stackwallet/widgets/custom_buttons/simple_button.dart';
import 'package:stackwallet/widgets/node_card.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'bot_runners/create_wallet_until_pin_confirmation.dart';
import 'bots/addressbook/add_address_book_entry_view_bot.dart';
import 'bots/addressbook/address_book_card_bot.dart';
import 'bots/addressbook/address_book_entry_details_view_bot.dart';
import 'bots/addressbook/address_book_view_bot.dart';
import 'bots/addressbook/edit_address_book_entry_view_bot.dart';
import 'bots/lockscreen_view_bot.dart';
import 'bots/main_view_bot.dart';
import 'bots/onboarding/backup_key_warning_bot.dart';
import 'bots/onboarding/create_pin_view_bot.dart';
import 'bots/onboarding/name_your_wallet_view_bot.dart';
import 'bots/onboarding/onboarding_view_bot.dart';
import 'bots/onboarding/terms_and_conditions_bot.dart';
import 'bots/settings/currency_view_bot.dart';
import 'bots/settings/network_settings/add_custom_node_view_bot.dart';
import 'bots/settings/network_settings/network_settings_view_bot.dart';
import 'bots/settings/network_settings/node_details_view_bot.dart';
import 'bots/settings/settings_view_bot.dart';
import 'bots/settings/wallet_backup_view_bot.dart';
import 'bots/settings/wallet_settings/change_pin_view_bot.dart';
import 'bots/settings/wallet_settings/delete_wallet_warning_view_bot.dart';
import 'bots/settings/wallet_settings/rename_wallet_view_bot.dart';
import 'bots/settings/wallet_settings/wallet_delete_mnemonic_view_bot.dart';
import 'bots/settings/wallet_settings_view_bot.dart';

const bool TEST_ADDRESS_BOOK = true;
const bool TEST_NETWORK_SETTINGS = true;
const bool TEST_WALLET_BACKUP = true;
const bool TEST_CURRENCY = true;
const bool TEST_WALLET_SETTINGS = true;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // may fail if a network connection fails somewhere
  testWidgets("settings integration test", (tester) async {
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

    // tap settings button
    await mainViewBot.tapSettings();
    await settingsViewBot.ensureVisible();

    if (TEST_ADDRESS_BOOK) {
      // tap address book
      await settingsViewBot.tapAddressBook();
      final addressBookViewBot = AddressBookViewBot(tester);
      await addressBookViewBot.ensureVisible();

      // add entry
      await addressBookViewBot.tapAdd();
      final addAddressBookEntryViewBot = AddAddressBookEntryViewBot(tester);
      await addAddressBookEntryViewBot.ensureVisible();

      // test back and cancel
      await addAddressBookEntryViewBot.tapBack();
      await addressBookViewBot.ensureVisible();
      await addressBookViewBot.tapAdd();
      await addAddressBookEntryViewBot.tapCancel();
      await addressBookViewBot.ensureVisible();

      // now add an entry
      await addressBookViewBot.tapAdd();
      await addAddressBookEntryViewBot.ensureVisible();
      await addAddressBookEntryViewBot
          .enterAddress("aPjLWDTPQsoPHUTxKBNRzoebDALj3eTcfh");
      await addAddressBookEntryViewBot.enterName("john doe");

      // save entry
      await addAddressBookEntryViewBot.tapSave();
      await addressBookViewBot.ensureVisible();
      final addressBookCardBot = AddressBookCardBot(tester);
      await addressBookCardBot.ensureVisible();

      // expand options
      await addressBookCardBot.toggleExpandCard();

      // tap copy
      await addressBookCardBot.tapCopy();
      expect((await Clipboard.getData(Clipboard.kTextPlain))!.text,
          "aPjLWDTPQsoPHUTxKBNRzoebDALj3eTcfh");
      expect(find.text("Address copied to clipboard"), findsOneWidget);
      await tester.pumpAndSettle(Duration(seconds: 2));

      // clear clipboard
      await Clipboard.setData(ClipboardData(text: ""));

      // tap details
      await addressBookCardBot.tapDetails();
      final addressBookEntryDetailsViewBot =
          AddressBookEntryDetailsViewBot(tester);
      await addressBookEntryDetailsViewBot.ensureVisible();

      // tap back then go back to details
      await addressBookEntryDetailsViewBot.tapBack();
      await addressBookCardBot.ensureVisible();
      await addressBookCardBot.tapDetails();
      await addressBookEntryDetailsViewBot.ensureVisible();

      // copy address
      await addressBookEntryDetailsViewBot.tapCopyAddress();
      expect((await Clipboard.getData(Clipboard.kTextPlain))!.text,
          "aPjLWDTPQsoPHUTxKBNRzoebDALj3eTcfh");
      expect(find.text("Address copied to clipboard"), findsOneWidget);
      await tester.pumpAndSettle(Duration(seconds: 2));

      // clear clipboard
      await Clipboard.setData(ClipboardData(text: ""));

      // delete and cancel
      await addressBookEntryDetailsViewBot.tapMore();
      await addressBookEntryDetailsViewBot.tapDelete();
      await addressBookEntryDetailsViewBot.tapCancelDelete();

      // delete and confirm
      await addressBookEntryDetailsViewBot.tapMore();
      await addressBookEntryDetailsViewBot.tapDelete();
      await addressBookEntryDetailsViewBot.tapConfirmDelete();
      await addressBookViewBot.ensureVisible();

      // add and save another entry, then go to details
      await addressBookViewBot.tapAdd();
      await addAddressBookEntryViewBot.ensureVisible();
      await addAddressBookEntryViewBot
          .enterAddress("aPjLWDTPQsoPHUTxKBNRzoebDALj3eTcfh");
      await addAddressBookEntryViewBot.enterName("john doe");
      await addAddressBookEntryViewBot.tapSave();
      await addressBookViewBot.ensureVisible();
      await addressBookCardBot.ensureVisible();
      await addressBookCardBot.toggleExpandCard();
      await addressBookCardBot.tapDetails();
      await addressBookEntryDetailsViewBot.ensureVisible();

      // tap edit
      await addressBookEntryDetailsViewBot.tapEdit();
      final editAddressBookEntryViewBot = EditAddressBookEntryViewBot(tester);
      await editAddressBookEntryViewBot.ensureVisible();

      // tap back
      await editAddressBookEntryViewBot.tapBack();
      await addressBookEntryDetailsViewBot.ensureVisible();
      await addressBookEntryDetailsViewBot.tapEdit();
      await editAddressBookEntryViewBot.ensureVisible();

      // tap cancel
      await editAddressBookEntryViewBot.tapCancel();
      await addressBookEntryDetailsViewBot.ensureVisible();
      await addressBookEntryDetailsViewBot.tapEdit();
      await editAddressBookEntryViewBot.ensureVisible();

      // tap save without editing
      await editAddressBookEntryViewBot.tapSave();
      await addressBookEntryDetailsViewBot.ensureVisible();
      await addressBookEntryDetailsViewBot.tapEdit();
      await editAddressBookEntryViewBot.ensureVisible();

      // tap save with editing
      await editAddressBookEntryViewBot.enterName("jane doe");
      await editAddressBookEntryViewBot
          .enterAddress("aPjLWDTPQsoPHUTxKBNRzoebDALj3eTcfh");

      await editAddressBookEntryViewBot.tapSave();
      await addressBookViewBot.ensureVisible();
      await addressBookCardBot.ensureVisible();

      // expand and tap send
      await addressBookCardBot.toggleExpandCard();
      await addressBookCardBot.tapSend();
      await mainViewBot.ensureVisible();

      // go to details and send
      await mainViewBot.tapSettings();
      await settingsViewBot.tapAddressBook();
      await addressBookCardBot.toggleExpandCard();
      await addressBookCardBot.tapDetails();
      await addressBookEntryDetailsViewBot.tapSend();
      await mainViewBot.ensureVisible();

      // open settings again to continue testing
      await mainViewBot.tapSettings();
      await settingsViewBot.ensureVisible();
    }

    if (TEST_NETWORK_SETTINGS) {
      // network settings
      await settingsViewBot.tapNetwork();
      final networkSettingsViewBot = NetworkSettingsViewBot(tester);
      await networkSettingsViewBot.ensureVisible();

      // test back
      await networkSettingsViewBot.tapBack();
      await settingsViewBot.tapNetwork();
      await networkSettingsViewBot.ensureVisible();
      expect(find.byType(NodeCard), findsOneWidget);

      // test add node back
      await networkSettingsViewBot.tapAdd();
      final addCustomNodeViewBot = AddCustomNodeViewBot(tester);
      await addCustomNodeViewBot.ensureVisible();
      await addCustomNodeViewBot.tapBack();
      await networkSettingsViewBot.tapAdd();
      await addCustomNodeViewBot.ensureVisible();

      // test add node
      await addCustomNodeViewBot.enterNodeName("MyNode");
      await addCustomNodeViewBot.enterNodeAddress("MyNodeAddress");
      await addCustomNodeViewBot.enterNodePort("0");

      // tap test connection
      await addCustomNodeViewBot.tapTestConnection();
      expect(find.text("Connection failed!"), findsOneWidget);
      await tester.pumpAndSettle(Duration(seconds: 2));

      // test save non connecting node
      await addCustomNodeViewBot.tapSave();
      expect(find.byType(CouldNotConnectOnSaveDialog), findsOneWidget);
      await tester
          .tap(find.byKey(Key("couldNotConnectOnSaveConfirmSaveButtonKey")));
      await tester.pumpAndSettle();
      await networkSettingsViewBot.ensureVisible();
      expect(find.byType(NodeCard), findsNWidgets(2));

      // tap default node to get context menu
      expect(find.text("Connect"), findsNothing);
      expect(find.text("Details"), findsNothing);
      expect(find.text("Edit"), findsNothing);
      expect(find.text("Delete"), findsNothing);
      await networkSettingsViewBot.tapNode("Campfire default");
      expect(find.text("Connect"), findsOneWidget);
      expect(find.text("Details"), findsOneWidget);
      expect(find.text("Edit"), findsNothing);
      expect(find.text("Delete"), findsNothing);

      // tap connect
      await tester.tap(find.text("Connect"));
      await tester.pumpAndSettle();

      // tap details
      await networkSettingsViewBot.tapNode("Campfire default");
      await tester.tap(find.text("Details"));
      await tester.pumpAndSettle();
      final nodeDetailsViewBot = NodeDetailsViewBot(tester);
      await nodeDetailsViewBot.ensureVisible();

      // tap test connection
      await nodeDetailsViewBot.tapTestConnection();
      await tester.pumpAndSettle(Duration(seconds: 3));

      // tap back
      await nodeDetailsViewBot.tapBack();
      await networkSettingsViewBot.ensureVisible();

      // tap custom node to get context menu
      expect(find.text("Connect"), findsNothing);
      expect(find.text("Details"), findsNothing);
      expect(find.text("Edit"), findsNothing);
      expect(find.text("Delete"), findsNothing);
      await networkSettingsViewBot.tapNode("MyNode");
      expect(find.text("Connect"), findsOneWidget);
      expect(find.text("Details"), findsOneWidget);
      expect(find.text("Edit"), findsOneWidget);
      expect(find.text("Delete"), findsOneWidget);

      // tap details
      await tester.tap(find.text("Details"));
      await tester.pumpAndSettle();
      await nodeDetailsViewBot.ensureVisible();

      // test back
      await nodeDetailsViewBot.tapBack();
      await networkSettingsViewBot.ensureVisible();
      await networkSettingsViewBot.tapNode("MyNode");
      await tester.tap(find.text("Details"));
      await tester.pumpAndSettle();
      await nodeDetailsViewBot.ensureVisible();

      // tap test connection
      await nodeDetailsViewBot.tapTestConnection();
      expect(find.text("Connection failed!"), findsOneWidget);
      await tester.pumpAndSettle(Duration(seconds: 2));

      // open context and edit
      await nodeDetailsViewBot.tapMoreAndEdit();

      // tap disabled save
      await nodeDetailsViewBot.tapSave();
      await nodeDetailsViewBot.ensureVisible();

      // edit and save node
      await nodeDetailsViewBot.tapUseSSLCheckbox();
      await nodeDetailsViewBot.enterName("MyNode2");
      await nodeDetailsViewBot.tapSave();
      await networkSettingsViewBot.ensureVisible();
      expect(find.text("MyNode2"), findsOneWidget);
      expect(find.text("MyNode"), findsNothing);

      // tap delete node from details view
      await networkSettingsViewBot.tapNode("MyNode2");
      await tester.tap(find.text("Details"));
      await tester.pumpAndSettle();
      await nodeDetailsViewBot.tapMoreAndDelete();

      // cancel delete
      expect(find.byType(ModalPopupDialog), findsOneWidget);
      await nodeDetailsViewBot.tapCancelDelete();
      expect(find.byType(ModalPopupDialog), findsNothing);

      // confirm delete
      await nodeDetailsViewBot.tapMoreAndDelete();
      await nodeDetailsViewBot.tapConfirmDelete();
      await networkSettingsViewBot.ensureVisible();
      // expect only the default node now
      expect(find.byType(NodeCard), findsOneWidget);

      // create new node to test remaining two context options
      // on the main network settings page
      await networkSettingsViewBot.tapAdd();
      await addCustomNodeViewBot.ensureVisible();
      await addCustomNodeViewBot.enterNodeName("MyNode");
      await addCustomNodeViewBot.enterNodeAddress("MyNodeAddress");
      await addCustomNodeViewBot.enterNodePort("0");
      await addCustomNodeViewBot.tapSave();
      await tester
          .tap(find.byKey(Key("couldNotConnectOnSaveConfirmSaveButtonKey")));
      await tester.pumpAndSettle();
      await networkSettingsViewBot.ensureVisible();
      expect(find.byType(NodeCard), findsNWidgets(2));

      // tap edit node from the main network settings page, then save
      await networkSettingsViewBot.tapNode("MyNode");
      await tester.tap(find.text("Edit"));
      await tester.pumpAndSettle();
      await nodeDetailsViewBot.ensureVisible();
      await nodeDetailsViewBot.enterName("MyNode3");
      await nodeDetailsViewBot.enterAddress("somenewaddress");
      await nodeDetailsViewBot.enterPort("00");
      await nodeDetailsViewBot.tapUseSSLCheckbox();
      await tester.tap(find.text("Use SSL"));
      await tester.pumpAndSettle();
      await nodeDetailsViewBot.tapSave();
      await networkSettingsViewBot.ensureVisible();

      // tap edit node from the main network settings page, then back
      await networkSettingsViewBot.tapNode("MyNode3");
      await tester.tap(find.text("Edit"));
      await tester.pumpAndSettle();
      await nodeDetailsViewBot.tapBack();
      await networkSettingsViewBot.ensureVisible();

      // tap delete node from the main network settings page, then cancel
      await networkSettingsViewBot.tapNode("MyNode3");
      await tester.tap(find.text("Delete"));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SimpleButton));
      await tester.pumpAndSettle();
      await networkSettingsViewBot.ensureVisible();
      expect(find.byType(NodeCard), findsNWidgets(2));

      // tap delete node from the main network settings page, then confirm
      await networkSettingsViewBot.tapNode("MyNode3");
      await tester.tap(find.text("Delete"));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(GradientButton));
      await tester.pumpAndSettle();
      await networkSettingsViewBot.ensureVisible();
      expect(find.byType(NodeCard), findsOneWidget);

      // go back to main settings
      await networkSettingsViewBot.tapBack();
      await settingsViewBot.ensureVisible();
    }

    if (TEST_WALLET_BACKUP) {
      await settingsViewBot.tapWalletBackup();
      final lockscreenViewBot = LockscreenViewBot(tester);
      await lockscreenViewBot.ensureVisible();

      // test back
      await lockscreenViewBot.tapBack();
      await settingsViewBot.ensureVisible();
      await settingsViewBot.tapWalletBackup();

      // enter wrong pin
      await lockscreenViewBot.enterPin("2222");
      await tester.pumpAndSettle(Duration(seconds: 2));
      await lockscreenViewBot.ensureVisible();

      // test back again
      await lockscreenViewBot.tapBack();
      await settingsViewBot.ensureVisible();
      await settingsViewBot.tapWalletBackup();

      // enter correct pin
      await lockscreenViewBot.enterPin("1234");
      await tester.pumpAndSettle(Duration(seconds: 2));
      final walletBackUpViewBot = WalletBackUpViewBot(tester);
      await walletBackUpViewBot.ensureVisible();

      // tap copy
      await Clipboard.setData(ClipboardData(text: ""));
      await walletBackUpViewBot.tapCopy();
      final mnemonic =
          (await Clipboard.getData(Clipboard.kTextPlain))!.text!.split(" ");
      expect(mnemonic.length, 24);
      await tester.pumpAndSettle(Duration(seconds: 2));
      await Clipboard.setData(ClipboardData(text: ""));

      // tap qr code then cancel
      await walletBackUpViewBot.tapQrCode();
      final qr = find.byType(PrettyQr).evaluate().first.widget as PrettyQr;
      expect(qr.data, AddressUtils.encodeQRSeedData(mnemonic));
      await walletBackUpViewBot.tapQrCodeCancel();
      expect(find.byType(ModalPopupDialog), findsNothing);

      // tap back to settings
      await walletBackUpViewBot.tapBack();
      await settingsViewBot.ensureVisible();
    }

    if (TEST_CURRENCY) {
      // change to a different currency from default USD
      await settingsViewBot.tapCurrency();
      final currencyViewBot = CurrencyViewBot(tester);
      await currencyViewBot.ensureVisible();
      await currencyViewBot.tapCurrency("CHF");

      // go back to main view to check for "CHF"
      await currencyViewBot.tapBack();
      await settingsViewBot.ensureVisible();
      await settingsViewBot.tapBack();
      await mainViewBot.ensureVisible();
      expect(find.text("CHF"), findsOneWidget);

      // open settings again to continue testing
      await mainViewBot.tapSettings();
      await settingsViewBot.ensureVisible();
    }

    if (TEST_WALLET_SETTINGS) {
      // tap wallet settings
      await settingsViewBot.tapWalletSettings();
      final walletSettingsViewBot = WalletSettingsViewBot(tester);
      await walletSettingsViewBot.ensureVisible();

      // test all change pin back taps
      await walletSettingsViewBot.tapChangePIN();
      final lockScreenViewBot = LockscreenViewBot(tester);
      await lockScreenViewBot.ensureVisible();
      await lockScreenViewBot.tapBack();
      await walletSettingsViewBot.tapChangePIN();
      await lockScreenViewBot.enterPin("1234");
      await tester.pumpAndSettle(Duration(seconds: 2));
      final changePinViewBot = ChangePinViewBot(tester);
      await changePinViewBot.ensureVisible();
      await changePinViewBot.tapBack();
      await walletSettingsViewBot.tapChangePIN();
      await lockScreenViewBot.enterPin("1234");
      await tester.pumpAndSettle(Duration(seconds: 2));
      await changePinViewBot.enterPin();
      await changePinViewBot.tapBack();
      await walletSettingsViewBot.ensureVisible();

      // change pin with a few fails
      await walletSettingsViewBot.tapChangePIN();
      await lockScreenViewBot.enterPin("2222");
      await tester.pumpAndSettle(Duration(seconds: 2));
      await lockScreenViewBot.enterPin("1234");
      await tester.pumpAndSettle(Duration(seconds: 2));
      await changePinViewBot.enterPin();
      await changePinViewBot.confirmUnmatchedPin();
      await changePinViewBot.enterPin();
      await changePinViewBot.confirmUnmatchedPin();
      await changePinViewBot.enterPin();
      await changePinViewBot.confirmMatchedPin();
      await walletSettingsViewBot.ensureVisible();
      await tester.pumpAndSettle(Duration(seconds: 2));

      // change pin with no fails
      await walletSettingsViewBot.tapChangePIN();
      await lockScreenViewBot.enterPin("2222");
      await tester.pumpAndSettle(Duration(seconds: 2));
      await lockScreenViewBot.enterPin("1234");
      await tester.pumpAndSettle(Duration(seconds: 2));
      await changePinViewBot.enterPin();
      await changePinViewBot.confirmMatchedPin();
      await walletSettingsViewBot.ensureVisible();
      await tester.pumpAndSettle(Duration(seconds: 2));

      // biometrics doesn't test well as it prompts for system settings
      // await walletSettingsViewBot.tapToggleBiometrics();
      // await walletSettingsViewBot.tapCancelBiometricsSystemSettingsDialog();

      // rename wallet save
      await walletSettingsViewBot.tapRenameWallet();
      final renameWalletViewBot = RenameWalletViewBot(tester);
      await renameWalletViewBot.tapSave();
      await renameWalletViewBot.enterWalletName("My Firo Wallet2");
      await renameWalletViewBot.tapSave();

      await walletSettingsViewBot.tapRenameWallet();
      expect(find.text("My Firo Wallet2"), findsOneWidget);
      await renameWalletViewBot.enterWalletName("My Firo Wallet");
      await renameWalletViewBot.tapSave();

      // tap back
      await walletSettingsViewBot.tapRenameWallet();
      await renameWalletViewBot.tapBack();
      await walletSettingsViewBot.ensureVisible();

      // tap clear cache and cancel
      await walletSettingsViewBot.tapClearCache();
      await walletSettingsViewBot.tapCancelClearCache();
      await walletSettingsViewBot.ensureVisible();

      // tap clear cache and clear
      await walletSettingsViewBot.tapClearCache();
      await walletSettingsViewBot.tapClearOnClearCache();
      await walletSettingsViewBot.tapOkOnCacheClearedAlert();
      await walletSettingsViewBot.ensureVisible();

      // tap delete wallet and cancel
      await walletSettingsViewBot.tapDeleteWallet();
      await walletSettingsViewBot.tapCancelDeleteConfirmationDialog();

      // tap delete wallet and continue running though
      // and testing back taps throughout
      await walletSettingsViewBot.tapDeleteWallet();
      await walletSettingsViewBot.tapDeleteOnDeleteConfirmationDialog();
      await lockScreenViewBot.ensureVisible();
      await lockScreenViewBot.tapBack();

      await walletSettingsViewBot.tapDeleteWallet();
      await walletSettingsViewBot.tapDeleteOnDeleteConfirmationDialog();
      await lockScreenViewBot.ensureVisible();
      await lockScreenViewBot.enterPin("9999");
      await tester.pumpAndSettle(Duration(seconds: 2));
      await lockScreenViewBot.ensureVisible();
      await lockScreenViewBot.tapBack();

      await walletSettingsViewBot.tapDeleteWallet();
      await walletSettingsViewBot.tapDeleteOnDeleteConfirmationDialog();
      await lockScreenViewBot.ensureVisible();
      await lockScreenViewBot.enterPin("1234");
      await tester.pumpAndSettle(Duration(seconds: 2));
      final deleteWalletWarningViewBot = DeleteWalletWarningViewBot(tester);
      await deleteWalletWarningViewBot.ensureVisible();
      await deleteWalletWarningViewBot.tapBack();
      await walletSettingsViewBot.ensureVisible();

      await walletSettingsViewBot.tapDeleteWallet();
      await walletSettingsViewBot.tapDeleteOnDeleteConfirmationDialog();
      await lockScreenViewBot.ensureVisible();
      await lockScreenViewBot.enterPin("1234");
      await tester.pumpAndSettle(Duration(seconds: 2));
      await deleteWalletWarningViewBot.ensureVisible();
      await deleteWalletWarningViewBot.tapCancelAndGoBack();
      await walletSettingsViewBot.ensureVisible();

      // finally go through and tap view backup key
      await walletSettingsViewBot.tapDeleteWallet();
      await walletSettingsViewBot.tapDeleteOnDeleteConfirmationDialog();
      await lockScreenViewBot.ensureVisible();
      await lockScreenViewBot.enterPin("1234");
      await tester.pumpAndSettle(Duration(seconds: 2));
      await deleteWalletWarningViewBot.ensureVisible();
      await deleteWalletWarningViewBot.tapViewBackupKey();
      final walletDeleteMnemonicViewBot = WalletDeleteMnemonicViewBot(tester);
      await walletDeleteMnemonicViewBot.ensureVisible();

      // test back
      await walletDeleteMnemonicViewBot.tapBack();
      await deleteWalletWarningViewBot.ensureVisible();
      await deleteWalletWarningViewBot.tapViewBackupKey();
      await walletDeleteMnemonicViewBot.ensureVisible();

      // tap qr code
      await walletDeleteMnemonicViewBot.tapQrCode();
      await walletDeleteMnemonicViewBot.tapCancelQrCode();
      await walletDeleteMnemonicViewBot.ensureVisible();

      // tap copy
      await Clipboard.setData(ClipboardData(text: ""));
      await walletDeleteMnemonicViewBot.tapCopy();
      final mnemonic =
          (await Clipboard.getData(Clipboard.kTextPlain))!.text!.split(" ");
      expect(mnemonic.length, 24);
      await tester.pumpAndSettle(Duration(seconds: 2));
      await Clipboard.setData(ClipboardData(text: ""));
      await walletDeleteMnemonicViewBot.ensureVisible();

      // tap continue and cancel
      await walletDeleteMnemonicViewBot.tapContinue();
      await walletDeleteMnemonicViewBot.tapCancelContinue();
      await walletDeleteMnemonicViewBot.ensureVisible();

      // tap continue and finally confirm deletion
      await walletDeleteMnemonicViewBot.tapContinue();
      await walletDeleteMnemonicViewBot.tapConfirmContinue();
      await onboardingViewBot.ensureVisible();
    }
  });
}
