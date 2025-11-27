import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
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
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @changePreferences.
  ///
  /// In en, this message translates to:
  /// **'Change preferences'**
  String get changePreferences;

  /// No description provided for @syncingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Syncing Preferences'**
  String get syncingPreferences;

  /// Syncing preferences info string
  ///
  /// In en, this message translates to:
  /// **'Set up your syncing preferences for all wallets in your {appPrefix}.'**
  String syncingPreferencesInfo(String appPrefix);

  /// No description provided for @syncingTypeCurrentWalletOnly.
  ///
  /// In en, this message translates to:
  /// **'Sync only currently open wallet'**
  String get syncingTypeCurrentWalletOnly;

  /// No description provided for @syncingTypeSelectedWalletsAtStartup.
  ///
  /// In en, this message translates to:
  /// **'Sync only selected wallets at startup'**
  String get syncingTypeSelectedWalletsAtStartup;

  /// No description provided for @syncingTypeAllWalletsOnStartup.
  ///
  /// In en, this message translates to:
  /// **'Sync all wallets at startup'**
  String get syncingTypeAllWalletsOnStartup;

  /// No description provided for @autoLockSettings.
  ///
  /// In en, this message translates to:
  /// **'Auto lock settings'**
  String get autoLockSettings;

  /// No description provided for @authAutoLockSettings.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to change auto lock settings'**
  String get authAutoLockSettings;

  /// Biometrics unlock auth title
  ///
  /// In en, this message translates to:
  /// **'Unlock {appPrefix}'**
  String biometricUnlockAppTitle(String appPrefix);

  /// Biometrics unlock app auth reason message
  ///
  /// In en, this message translates to:
  /// **'Unlock your {appName} using biometrics'**
  String biometricsUnlockAuthReason(String appName);

  /// Biometrics restore auth title
  ///
  /// In en, this message translates to:
  /// **'Restore {appPrefix} backup'**
  String biometricRestoreSwbTitle(String appPrefix);

  /// Biometrics unlock app to restore reason message
  ///
  /// In en, this message translates to:
  /// **'Authenticate to restore {appName} backup'**
  String biometricsUnlockToRestoreReason(String appName);

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changePIN.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePIN;

  /// No description provided for @authToChangePIN.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to change PIN'**
  String get authToChangePIN;

  /// No description provided for @enableBioAuth.
  ///
  /// In en, this message translates to:
  /// **'Enable biometric authentication'**
  String get enableBioAuth;

  /// No description provided for @randomizePinPad.
  ///
  /// In en, this message translates to:
  /// **'Randomize PIN Pad'**
  String get randomizePinPad;

  /// No description provided for @autoAcceptCorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Auto-accept correct PIN'**
  String get autoAcceptCorrectPin;

  /// No description provided for @coverInBackground.
  ///
  /// In en, this message translates to:
  /// **'Cover in background'**
  String get coverInBackground;

  /// No description provided for @disableScreenShots.
  ///
  /// In en, this message translates to:
  /// **'Disable screenshots'**
  String get disableScreenShots;

  /// No description provided for @duressPin.
  ///
  /// In en, this message translates to:
  /// **'Duress PIN'**
  String get duressPin;

  /// No description provided for @biometricsOpensDuress.
  ///
  /// In en, this message translates to:
  /// **'Biometrics opens duress'**
  String get biometricsOpensDuress;

  /// No description provided for @authToCreateDuressPIN.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to create duress PIN'**
  String get authToCreateDuressPIN;

  /// No description provided for @createDuressPIN.
  ///
  /// In en, this message translates to:
  /// **'Create duress PIN'**
  String get createDuressPIN;

  /// No description provided for @enableDuressPIN.
  ///
  /// In en, this message translates to:
  /// **'Enable duress PIN'**
  String get enableDuressPIN;

  /// No description provided for @disableDuressPIN.
  ///
  /// In en, this message translates to:
  /// **'Disable duress PIN'**
  String get disableDuressPIN;

  /// No description provided for @disableDuressPinDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Your duress pin will be deleted. You will be asked to create a PIN when you enable this again. Are you sure you want to continue?'**
  String get disableDuressPinDeleteWarning;

  /// No description provided for @duressPinExplanation.
  ///
  /// In en, this message translates to:
  /// **'When unlocking the app with a duress PIN, only wallets marked as visible in duress mode will be loaded and shown. Be aware that providing a duress PIN instead of your real PIN to law enforcement, border agents, or other authorities may be considered deception and could carry legal consequences depending on your jurisdiction. Use with care and according to your threat model.'**
  String get duressPinExplanation;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
