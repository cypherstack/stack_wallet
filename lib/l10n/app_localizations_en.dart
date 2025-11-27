// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get ok => 'Ok';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get changePreferences => 'Change preferences';

  @override
  String get syncingPreferences => 'Syncing Preferences';

  @override
  String syncingPreferencesInfo(String appPrefix) {
    return 'Set up your syncing preferences for all wallets in your $appPrefix.';
  }

  @override
  String get syncingTypeCurrentWalletOnly => 'Sync only currently open wallet';

  @override
  String get syncingTypeSelectedWalletsAtStartup =>
      'Sync only selected wallets at startup';

  @override
  String get syncingTypeAllWalletsOnStartup => 'Sync all wallets at startup';

  @override
  String get autoLockSettings => 'Auto lock settings';

  @override
  String get authAutoLockSettings =>
      'Authenticate to change auto lock settings';

  @override
  String biometricUnlockAppTitle(String appPrefix) {
    return 'Unlock $appPrefix';
  }

  @override
  String biometricsUnlockAuthReason(String appName) {
    return 'Unlock your $appName using biometrics';
  }

  @override
  String biometricRestoreSwbTitle(String appPrefix) {
    return 'Restore $appPrefix backup';
  }

  @override
  String biometricsUnlockToRestoreReason(String appName) {
    return 'Authenticate to restore $appName backup';
  }

  @override
  String get security => 'Security';

  @override
  String get changePIN => 'Change PIN';

  @override
  String get authToChangePIN => 'Authenticate to change PIN';

  @override
  String get enableBioAuth => 'Enable biometric authentication';

  @override
  String get randomizePinPad => 'Randomize PIN Pad';

  @override
  String get autoAcceptCorrectPin => 'Auto-accept correct PIN';

  @override
  String get coverInBackground => 'Cover in background';

  @override
  String get disableScreenShots => 'Disable screenshots';

  @override
  String get duressPin => 'Duress PIN';

  @override
  String get biometricsOpensDuress => 'Biometrics opens duress';

  @override
  String get authToCreateDuressPIN => 'Authenticate to create duress PIN';

  @override
  String get createDuressPIN => 'Create duress PIN';

  @override
  String get enableDuressPIN => 'Enable duress PIN';

  @override
  String get disableDuressPIN => 'Disable duress PIN';

  @override
  String get disableDuressPinDeleteWarning =>
      'Your duress pin will be deleted. You will be asked to create a PIN when you enable this again. Are you sure you want to continue?';

  @override
  String get duressPinExplanation =>
      'When unlocking the app with a duress PIN, only wallets marked as visible in duress mode will be loaded and shown. Be aware that providing a duress PIN instead of your real PIN to law enforcement, border agents, or other authorities may be considered deception and could carry legal consequences depending on your jurisdiction. Use with care and according to your threat model.';
}
