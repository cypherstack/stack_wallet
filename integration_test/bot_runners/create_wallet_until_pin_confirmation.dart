import '../bots/onboarding/create_pin_view_bot.dart';
import '../bots/onboarding/name_your_wallet_view_bot.dart';
import '../bots/onboarding/terms_and_conditions_bot.dart';

Future<void> createWalletUntilPinConfirmation(
  TermsAndConditionsViewBot termsAndConditionsViewBot,
  NameYourWalletViewBot nameYourWalletViewBot,
  CreatePinViewBot createPinViewBot,
) async {
  await termsAndConditionsViewBot.ensureVisible();

  // test scrolling of terms & conditions
  await termsAndConditionsViewBot.scrollDown();
  await termsAndConditionsViewBot.scrollUp();

  // accept terms & conditions
  await termsAndConditionsViewBot.tapIAccept();

  await nameYourWalletViewBot.ensureVisible();
  // test tap back
  await nameYourWalletViewBot.tapBack();
  await termsAndConditionsViewBot.ensureVisible();
  // accept terms & conditions again
  await termsAndConditionsViewBot.tapIAccept();
  await nameYourWalletViewBot.ensureVisible();

  // enter a wallet name
  await nameYourWalletViewBot.enterWalletName("My Firo Wallet");

  // tap next
  await nameYourWalletViewBot.tapNext();

  await createPinViewBot.ensureVisible();
  // tap back
  await createPinViewBot.tapBack();
  await nameYourWalletViewBot.ensureVisible();

  // tap next
  await nameYourWalletViewBot.tapNext();
  await createPinViewBot.ensureVisible();

  // enter a pin
  await createPinViewBot.enterPin();
  // confirm pin
  await createPinViewBot.confirmMatchedPin();
}
