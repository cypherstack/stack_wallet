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
  String get cancel => 'Cancel';

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
}
