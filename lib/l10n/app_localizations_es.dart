// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Stack Wallet';

  @override
  String get walletsTab => 'Wallets';

  @override
  String get exchangeTab => 'Exchange';

  @override
  String get buyTab => 'Buy';

  @override
  String get settingsTab => 'Settings';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get addressBookTitle => 'Address Book';

  @override
  String get homeTitle => 'Home';

  @override
  String get walletViewTitle => 'Wallet';

  @override
  String get sendTitle => 'Send';

  @override
  String get sendFromTitle => 'Send from';

  @override
  String get receiveTitle => 'Receive';

  @override
  String get swapTitle => 'Swap';

  @override
  String get tokensTitle => 'Tokens';

  @override
  String get saveButton => 'Save';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get continueButton => 'Continuar';

  @override
  String get editButton => 'Edit';

  @override
  String get deleteButton => 'Delete';

  @override
  String get nextButton => 'Next';

  @override
  String get closeButton => 'Close';

  @override
  String get okButton => 'OK';

  @override
  String get yesButton => 'Yes';

  @override
  String get noButton => 'No';

  @override
  String get copyButton => 'Copy';

  @override
  String get sendButton => 'Send';

  @override
  String get receiveButton => 'Receive';

  @override
  String get addButton => 'Add';

  @override
  String get nameLabel => 'Name';

  @override
  String get amountLabel => 'Amount';

  @override
  String get addressLabel => 'Address';

  @override
  String get feeLabel => 'Fee';

  @override
  String get noteLabel => 'Note';

  @override
  String get passwordLabel => 'Password';

  @override
  String get searchHint => 'Search...';

  @override
  String get enterPasswordHint => 'Enter password';

  @override
  String get enterAmountHint => '0.00';

  @override
  String get optionalHint => 'Optional';

  @override
  String get requiredFieldError => 'This field is required';

  @override
  String get invalidEmailError => 'Please enter a valid email address';

  @override
  String get invalidAddressError => 'Please enter a valid address';

  @override
  String get insufficientFundsError => 'Insufficient funds';

  @override
  String get networkError => 'Network connection failed';

  @override
  String get transactionFailed => 'Transaction failed';

  @override
  String get loadingStatus => 'Loading...';

  @override
  String get processingStatus => 'Processing...';

  @override
  String get syncingStatus => 'Syncing...';

  @override
  String get completedStatus => 'Completed';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get confirmedStatus => 'Confirmed';

  @override
  String get wallets => 'Billeteras';

  @override
  String get settings => 'Configuración';

  @override
  String get exchange => 'Intercambio';

  @override
  String get buy => 'Comprar';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get contractDetails => 'Detalles del contrato';

  @override
  String get contractAddress => 'Dirección del contrato';

  @override
  String get symbolLabel => 'Symbol';

  @override
  String get typeLabel => 'Type';

  @override
  String get decimalsLabel => 'Decimals';

  @override
  String get name => 'Nombre';

  @override
  String get youCanChangeItLaterInSettings => 'Puedes cambiarlo más tarde en Configuración';

  @override
  String get easyCrypto => 'Crypto Fácil';

  @override
  String get recommended => 'Recomendado';

  @override
  String get incognito => 'Incógnito';

  @override
  String get privacyConscious => 'Consciente de la privacidad';

  @override
  String get welcomeTagline => 'An open-source, multicoin wallet for everyone';

  @override
  String get getStartedButton => 'Get started';

  @override
  String createNewWalletButton(String appPrefix) {
    return 'Create new $appPrefix';
  }

  @override
  String restoreFromBackupButton(String appPrefix) {
    return 'Restore from $appPrefix backup';
  }

  @override
  String privacyAgreementText(String appName) {
    return 'By using $appName, you agree to the ';
  }

  @override
  String get termsOfServiceLinkText => 'Terms of service';

  @override
  String get privacyAgreementConjunction => ' and ';

  @override
  String get privacyPolicyLinkText => 'Privacy policy';

  @override
  String get enterPinTitle => 'Enter PIN';

  @override
  String get useBiometricsButton => 'Use biometrics';

  @override
  String get loadingWalletsMessage => 'Loading wallets...';

  @override
  String get incorrectPinTryAgainError => 'Incorrect PIN. Please try again';

  @override
  String incorrectPinThrottleError(String waitTime) {
    return 'Incorrect PIN entered too many times. Please wait $waitTime';
  }
}
