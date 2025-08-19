import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart' deferred as app_localizations_ar;
import 'app_localizations_en.dart' deferred as app_localizations_en;
import 'app_localizations_es.dart' deferred as app_localizations_es;

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('es'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Stack Wallet'**
  String get appTitle;

  /// Bottom navigation tab label for wallets view
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get walletsTab;

  /// Bottom navigation tab label for exchange view
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get exchangeTab;

  /// Bottom navigation tab label for buy view
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buyTab;

  /// Bottom navigation tab label for settings view
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// AppBar title for notifications screen
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// AppBar title for address book screen
  ///
  /// In en, this message translates to:
  /// **'Address Book'**
  String get addressBookTitle;

  /// AppBar title for home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// AppBar title for wallet details screen
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletViewTitle;

  /// AppBar title for send screen
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendTitle;

  /// AppBar title for send from screen
  ///
  /// In en, this message translates to:
  /// **'Send from'**
  String get sendFromTitle;

  /// AppBar title for receive screen
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receiveTitle;

  /// AppBar title for swap screen
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swapTitle;

  /// AppBar title for tokens screen
  ///
  /// In en, this message translates to:
  /// **'Tokens'**
  String get tokensTitle;

  /// Generic save button label used across forms
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// Generic cancel button label used across dialogs
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Continue button text for multi-step processes
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Edit button label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButton;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// Next button for navigation
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// Close button for dialogs and modals
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// OK button for confirmation dialogs
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// Yes button for confirmation dialogs
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesButton;

  /// No button for confirmation dialogs
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noButton;

  /// Copy button for copying text to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyButton;

  /// Send button for transactions
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendButton;

  /// Receive button for receiving transactions
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receiveButton;

  /// Add button for creating new items
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// Label for name input fields
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Label for amount input fields
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// Label for address input fields
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// Label for fee input fields
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get feeLabel;

  /// Label for note input fields
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// Label for password input fields
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Placeholder text for search fields
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// Placeholder text for password fields
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPasswordHint;

  /// Placeholder text for amount fields
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get enterAmountHint;

  /// Hint text for optional fields
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalHint;

  /// Error message for required fields that are empty
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredFieldError;

  /// Error message for invalid email format
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmailError;

  /// Error message for invalid address format
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid address'**
  String get invalidAddressError;

  /// Error message when user has insufficient funds
  ///
  /// In en, this message translates to:
  /// **'Insufficient funds'**
  String get insufficientFundsError;

  /// Error message for network connection failures
  ///
  /// In en, this message translates to:
  /// **'Network connection failed'**
  String get networkError;

  /// Error message for failed transactions
  ///
  /// In en, this message translates to:
  /// **'Transaction failed'**
  String get transactionFailed;

  /// Status message while loading
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingStatus;

  /// Status message while processing
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processingStatus;

  /// Status message while syncing
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncingStatus;

  /// Status message when operation is completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedStatus;

  /// Status message when operation is pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// Status message when transaction is confirmed
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmedStatus;

  /// Label for the wallets section
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get wallets;

  /// Label for the settings section
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for the exchange section
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get exchange;

  /// Label for the buy section
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// Label for the notifications section
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Save changes button text
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// Contract details page title
  ///
  /// In en, this message translates to:
  /// **'Contract details'**
  String get contractDetails;

  /// Label for contract address field
  ///
  /// In en, this message translates to:
  /// **'Contract address'**
  String get contractAddress;

  /// Label for symbol field
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get symbolLabel;

  /// Label for type field
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// Label for decimals field
  ///
  /// In en, this message translates to:
  /// **'Decimals'**
  String get decimalsLabel;

  /// Label for name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Informational text about changing settings later
  ///
  /// In en, this message translates to:
  /// **'You can change it later in Settings'**
  String get youCanChangeItLaterInSettings;

  /// Easy Crypto option label
  ///
  /// In en, this message translates to:
  /// **'Easy Crypto'**
  String get easyCrypto;

  /// Recommended option label
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// Incognito option label
  ///
  /// In en, this message translates to:
  /// **'Incognito'**
  String get incognito;

  /// Privacy conscious option label
  ///
  /// In en, this message translates to:
  /// **'Privacy conscious'**
  String get privacyConscious;

  /// Main tagline shown on welcome/intro screen
  ///
  /// In en, this message translates to:
  /// **'An open-source, multicoin wallet for everyone'**
  String get welcomeTagline;

  /// Button text for starting wallet setup on mobile
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStartedButton;

  /// Button text for creating new wallet on desktop
  ///
  /// In en, this message translates to:
  /// **'Create new {appPrefix}'**
  String createNewWalletButton(String appPrefix);

  /// Button text for restoring from backup on desktop
  ///
  /// In en, this message translates to:
  /// **'Restore from {appPrefix} backup'**
  String restoreFromBackupButton(String appPrefix);

  /// First part of privacy agreement text
  ///
  /// In en, this message translates to:
  /// **'By using {appName}, you agree to the '**
  String privacyAgreementText(String appName);

  /// Link text for terms of service
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfServiceLinkText;

  /// Conjunction between terms and privacy policy links
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get privacyAgreementConjunction;

  /// Link text for privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicyLinkText;

  /// Title text for PIN entry screen
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPinTitle;

  /// Button text for using biometric authentication
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get useBiometricsButton;

  /// Loading message while wallets are being loaded
  ///
  /// In en, this message translates to:
  /// **'Loading wallets...'**
  String get loadingWalletsMessage;

  /// Error message for incorrect PIN entry
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Please try again'**
  String get incorrectPinTryAgainError;

  /// Error message when PIN attempts are throttled
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN entered too many times. Please wait {waitTime}'**
  String incorrectPinThrottleError(String waitTime);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return lookupAppLocalizations(locale);
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

Future<AppLocalizations> lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return app_localizations_ar.loadLibrary().then(
        (dynamic _) => app_localizations_ar.AppLocalizationsAr(),
      );
    case 'en':
      return app_localizations_en.loadLibrary().then(
        (dynamic _) => app_localizations_en.AppLocalizationsEn(),
      );
    case 'es':
      return app_localizations_es.loadLibrary().then(
        (dynamic _) => app_localizations_es.AppLocalizationsEs(),
      );
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
