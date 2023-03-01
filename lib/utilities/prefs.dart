import 'package:flutter/cupertino.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/backup_frequency_type.dart';
import 'package:stackwallet/utilities/enums/languages_enum.dart';
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:uuid/uuid.dart';

class Prefs extends ChangeNotifier {
  Prefs._();
  static final Prefs _instance = Prefs._();
  static Prefs get instance => _instance;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (!_initialized) {
      _currency = await _getPreferredCurrency();
      // _exchangeRateType = await _getExchangeRateType();
      _useBiometrics = await _getUseBiometrics();
      _hasPin = await _getHasPin();
      _language = await _getPreferredLanguage();
      _showFavoriteWallets = await _getShowFavoriteWallets();
      _wifiOnly = await _getUseWifiOnly();
      _syncType = await _getSyncType();
      _walletIdsSyncOnStartup = await _getWalletIdsSyncOnStartup();
      _currentNotificationId = await _getCurrentNotificationIndex();
      _lastUnlocked = await _getLastUnlocked();
      _lastUnlockedTimeout = await _getLastUnlockedTimeout();
      _showTestNetCoins = await _getShowTestNetCoins();
      _isAutoBackupEnabled = await _getIsAutoBackupEnabled();
      _autoBackupLocation = await _getAutoBackupLocation();
      _backupFrequencyType = await _getBackupFrequencyType();
      _lastAutoBackup = await _getLastAutoBackup();
      _hideBlockExplorerWarning = await _getHideBlockExplorerWarning();
      _gotoWalletOnStartup = await _getGotoWalletOnStartup();
      _startupWalletId = await _getStartupWalletId();
      _externalCalls = await _getHasExternalCalls();
      _familiarity = await _getHasFamiliarity();
      _userId = await _getUserId();
      _signupEpoch = await _getSignupEpoch();

      _initialized = true;
    }
  }

  // last timestamp user unlocked wallet

  int _lastUnlockedTimeout = 60;

  int get lastUnlockedTimeout => _lastUnlockedTimeout;

  set lastUnlockedTimeout(int lastUnlockedTimeout) {
    if (_lastUnlockedTimeout != lastUnlockedTimeout) {
      DB.instance.put<dynamic>(
          boxName: DB.boxNamePrefs,
          key: "lastUnlockedTimeout",
          value: lastUnlockedTimeout);
      _lastUnlockedTimeout = lastUnlockedTimeout;
      notifyListeners();
    }
  }

  Future<int> _getLastUnlockedTimeout() async {
    return (DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs, key: "lastUnlockedTimeout")) as int? ??
        60;
  }

  // last timestamp user unlocked wallet

  int _lastUnlocked = 0;

  int get lastUnlocked => _lastUnlocked;

  set lastUnlocked(int lastUnlocked) {
    if (_lastUnlocked != lastUnlocked) {
      DB.instance.put<dynamic>(
          boxName: DB.boxNamePrefs, key: "lastUnlocked", value: lastUnlocked);
      _lastUnlocked = lastUnlocked;
      notifyListeners();
    }
  }

  Future<int> _getLastUnlocked() async {
    return await DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs, key: "lastUnlocked") as int? ??
        0;
  }

  // notification index

  late int _currentNotificationId;

  int get currentNotificationId => _currentNotificationId;

  Future<void> incrementCurrentNotificationIndex() async {
    if (_currentNotificationId <= Constants.notificationsMax) {
      _currentNotificationId++;
    } else {
      _currentNotificationId = 0;
    }
    await DB.instance.put<dynamic>(
        boxName: DB.boxNamePrefs,
        key: "currentNotificationId",
        value: _currentNotificationId);
    notifyListeners();
  }

  Future<int> _getCurrentNotificationIndex() async {
    return await DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs, key: "currentNotificationId") as int? ??
        0;
  }

  // list of wallet ids to auto sync when auto sync only selected wallets is chosen

  List<String> _walletIdsSyncOnStartup = [];

  List<String> get walletIdsSyncOnStartup => _walletIdsSyncOnStartup;

  set walletIdsSyncOnStartup(List<String> walletIdsSyncOnStartup) {
    if (_walletIdsSyncOnStartup != walletIdsSyncOnStartup) {
      DB.instance.put<dynamic>(
          boxName: DB.boxNamePrefs,
          key: "walletIdsSyncOnStartup",
          value: walletIdsSyncOnStartup);
      _walletIdsSyncOnStartup = walletIdsSyncOnStartup;
      notifyListeners();
    }
  }

  Future<List<String>> _getWalletIdsSyncOnStartup() async {
    final list = await DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs, key: "walletIdsSyncOnStartup") as List? ??
        [];
    return List<String>.from(list);
  }

  // sync type

  SyncingType _syncType = SyncingType.allWalletsOnStartup;

  SyncingType get syncType => _syncType;

  set syncType(SyncingType syncType) {
    if (_syncType != syncType) {
      DB.instance.put<dynamic>(
          boxName: DB.boxNamePrefs,
          key: "syncTypeIndex",
          value: syncType.index);
      _syncType = syncType;
      notifyListeners();
    }
  }

  Future<SyncingType> _getSyncType() async {
    final int index = await DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs, key: "syncTypeIndex") as int? ??
        SyncingType.allWalletsOnStartup.index;
    return SyncingType.values[index];
  }

  // wifi only

  bool _wifiOnly = false;

  bool get wifiOnly => _wifiOnly;

  set wifiOnly(bool wifiOnly) {
    if (_wifiOnly != wifiOnly) {
      DB.instance.put<dynamic>(
          boxName: DB.boxNamePrefs, key: "wifiOnly", value: wifiOnly);
      _wifiOnly = wifiOnly;
      notifyListeners();
    }
  }

  Future<bool> _getUseWifiOnly() async {
    return await DB.instance
            .get<dynamic>(boxName: DB.boxNamePrefs, key: "wifiOnly") as bool? ??
        false;
  }

  // show favorites

  bool _showFavoriteWallets = true;

  bool get showFavoriteWallets => _showFavoriteWallets;

  set showFavoriteWallets(bool showFavoriteWallets) {
    if (_showFavoriteWallets != showFavoriteWallets) {
      DB.instance.put<dynamic>(
          boxName: DB.boxNamePrefs,
          key: "showFavoriteWallets",
          value: showFavoriteWallets);
      _showFavoriteWallets = showFavoriteWallets;
      notifyListeners();
    }
  }

  Future<bool> _getShowFavoriteWallets() async {
    return await DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs, key: "showFavoriteWallets") as bool? ??
        true;
  }

  // language

  String _language = Language.englishUS.description;

  String get language => _language;

  set language(String newLanguage) {
    if (_language != newLanguage) {
      DB.instance.put<dynamic>(
          boxName: DB.boxNamePrefs, key: "language", value: newLanguage);
      _language = newLanguage;
      notifyListeners();
    }
  }

  Future<String> _getPreferredLanguage() async {
    return await DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs, key: "language") as String? ??
        Language.englishUS.description;
  }

  // base currency

  String _currency = "USD";

  String get currency => _currency;

  set currency(String newCurrency) {
    if (currency != newCurrency) {
      DB.instance.put<dynamic>(
          boxName: DB.boxNamePrefs, key: "currency", value: newCurrency);
      _currency = newCurrency;
      notifyListeners();
    }
  }

  Future<String> _getPreferredCurrency() async {
    return await DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs, key: "currency") as String? ??
        "USD";
  }

  // exchange rate type

  // ExchangeRateType _exchangeRateType = ExchangeRateType.estimated;
  //
  // ExchangeRateType get exchangeRateType => _exchangeRateType;
  //
  // set exchangeRateType(ExchangeRateType exchangeRateType) {
  //   if (_exchangeRateType != exchangeRateType) {
  //     switch (exchangeRateType) {
  //       case ExchangeRateType.estimated:
  //         DB.instance.put<dynamic>(
  //             boxName: DB.boxNamePrefs,
  //             key: "exchangeRateType",
  //             value: "estimated");
  //         break;
  //       case ExchangeRateType.fixed:
  //         DB.instance.put<dynamic>(
  //             boxName: DB.boxNamePrefs,
  //             key: "exchangeRateType",
  //             value: "fixed");
  //         break;
  //     }
  //     _exchangeRateType = exchangeRateType;
  //     notifyListeners();
  //   }
  // }
  //
  // Future<ExchangeRateType> _getExchangeRateType() async {
  //   String? rate = await DB.instance.get<dynamic>(
  //       boxName: DB.boxNamePrefs, key: "exchangeRateType") as String?;
  //   rate ??= "estimated";
  //   switch (rate) {
  //     case "estimated":
  //       return ExchangeRateType.estimated;
  //     case "fixed":
  //       return ExchangeRateType.fixed;
  //     default:
  //       throw Exception("Invalid exchange rate type found in prefs!");
  //   }
  // }

  // use biometrics

  bool _useBiometrics = false;

  bool get useBiometrics => _useBiometrics;

  set useBiometrics(bool useBiometrics) {
    if (_useBiometrics != useBiometrics) {
      DB.instance.put<dynamic>(
          boxName: DB.boxNamePrefs, key: "useBiometrics", value: useBiometrics);
      _useBiometrics = useBiometrics;
      notifyListeners();
    }
  }

  Future<bool> _getUseBiometrics() async {
    return await DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs, key: "useBiometrics") as bool? ??
        false;
  }

  // has set up pin

  bool _hasPin = false;

  bool get hasPin => _hasPin;

  set hasPin(bool hasPin) {
    if (_hasPin != hasPin) {
      DB.instance
          .put<dynamic>(boxName: DB.boxNamePrefs, key: "hasPin", value: hasPin);
      _hasPin = hasPin;
      notifyListeners();
    }
  }

  Future<bool> _getHasPin() async {
    return await DB.instance
            .get<dynamic>(boxName: DB.boxNamePrefs, key: "hasPin") as bool? ??
        false;
  }

  // familiarity

  int _familiarity = 0;

  int get familiarity => _familiarity;

  set familiarity(int familiarity) {
    if (_familiarity != familiarity) {
      DB.instance.put<dynamic>(
          boxName: DB.boxNamePrefs, key: "familiarity", value: familiarity);
      _familiarity = familiarity;
      notifyListeners();
    }
  }

  Future<int> _getHasFamiliarity() async {
    return await DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs, key: "familiarity") as int? ??
        0;
  }

  // show testnet coins

  bool _showTestNetCoins = false;

  bool get showTestNetCoins => _showTestNetCoins;

  set showTestNetCoins(bool showTestNetCoins) {
    if (_showTestNetCoins != showTestNetCoins) {
      DB.instance.put<dynamic>(
          boxName: DB.boxNamePrefs,
          key: "showTestNetCoins",
          value: showTestNetCoins);
      _showTestNetCoins = showTestNetCoins;
      notifyListeners();
    }
  }

  Future<bool> _getShowTestNetCoins() async {
    return await DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs, key: "showTestNetCoins") as bool? ??
        false;
  }

  // auto backup

  bool _isAutoBackupEnabled = false;

  bool get isAutoBackupEnabled => _isAutoBackupEnabled;

  set isAutoBackupEnabled(bool isAutoBackupEnabled) {
    if (_isAutoBackupEnabled != isAutoBackupEnabled) {
      DB.instance
          .put<dynamic>(
              boxName: DB.boxNamePrefs,
              key: "isAutoBackupEnabled",
              value: isAutoBackupEnabled)
          .then((_) {
        _isAutoBackupEnabled = isAutoBackupEnabled;
        notifyListeners();
      });
    }
  }

  Future<bool> _getIsAutoBackupEnabled() async {
    return await DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs, key: "isAutoBackupEnabled") as bool? ??
        false;
  }

  // auto backup file location uri

  String? _autoBackupLocation;

  String? get autoBackupLocation => _autoBackupLocation;

  set autoBackupLocation(String? autoBackupLocation) {
    if (this.autoBackupLocation != autoBackupLocation) {
      DB.instance.put<dynamic>(
          boxName: DB.boxNamePrefs,
          key: "autoBackupLocation",
          value: autoBackupLocation);
      _autoBackupLocation = autoBackupLocation;
      notifyListeners();
    }
  }

  Future<String?> _getAutoBackupLocation() async {
    return await DB.instance.get<dynamic>(
        boxName: DB.boxNamePrefs, key: "autoBackupLocation") as String?;
  }

  // auto backup frequency type

  BackupFrequencyType _backupFrequencyType =
      BackupFrequencyType.everyTenMinutes;

  BackupFrequencyType get backupFrequencyType => _backupFrequencyType;

  set backupFrequencyType(BackupFrequencyType backupFrequencyType) {
    if (_backupFrequencyType != backupFrequencyType) {
      switch (backupFrequencyType) {
        case BackupFrequencyType.everyTenMinutes:
          DB.instance.put<dynamic>(
              boxName: DB.boxNamePrefs,
              key: "backupFrequencyType",
              value: "10Min");
          break;
        case BackupFrequencyType.everyAppStart:
          DB.instance.put<dynamic>(
              boxName: DB.boxNamePrefs,
              key: "backupFrequencyType",
              value: "onStart");
          break;
        case BackupFrequencyType.afterClosingAWallet:
          DB.instance.put<dynamic>(
              boxName: DB.boxNamePrefs,
              key: "backupFrequencyType",
              value: "onWalletClose");
          break;
      }
      _backupFrequencyType = backupFrequencyType;
      notifyListeners();
    }
  }

  Future<BackupFrequencyType> _getBackupFrequencyType() async {
    String? rate = await DB.instance.get<dynamic>(
        boxName: DB.boxNamePrefs, key: "backupFrequencyType") as String?;
    rate ??= "10Min";
    switch (rate) {
      case "10Min":
        return BackupFrequencyType.everyTenMinutes;
      case "onStart":
        return BackupFrequencyType.everyAppStart;
      case "onWalletClose":
        return BackupFrequencyType.afterClosingAWallet;
      default:
        throw Exception("Invalid Backup Frequency type found in prefs!");
    }
  }

  // auto backup last time stamp

  DateTime? _lastAutoBackup;

  DateTime? get lastAutoBackup => _lastAutoBackup;

  set lastAutoBackup(DateTime? lastAutoBackup) {
    if (this.lastAutoBackup != lastAutoBackup) {
      DB.instance.put<dynamic>(
          boxName: DB.boxNamePrefs,
          key: "lastAutoBackup",
          value: lastAutoBackup);
      _lastAutoBackup = lastAutoBackup;
      notifyListeners();
    }
  }

  Future<DateTime?> _getLastAutoBackup() async {
    return await DB.instance.get<dynamic>(
        boxName: DB.boxNamePrefs, key: "autoBackupFileUri") as DateTime?;
  }

  // auto backup

  bool _hideBlockExplorerWarning = false;

  bool get hideBlockExplorerWarning => _hideBlockExplorerWarning;

  set hideBlockExplorerWarning(bool hideBlockExplorerWarning) {
    if (_hideBlockExplorerWarning != hideBlockExplorerWarning) {
      DB.instance
          .put<dynamic>(
              boxName: DB.boxNamePrefs,
              key: "hideBlockExplorerWarning",
              value: hideBlockExplorerWarning)
          .then((_) {
        _hideBlockExplorerWarning = hideBlockExplorerWarning;
        notifyListeners();
      });
    }
  }

  Future<bool> _getHideBlockExplorerWarning() async {
    return await DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs,
            key: "hideBlockExplorerWarning") as bool? ??
        false;
  }

  // auto backup

  bool _gotoWalletOnStartup = false;

  bool get gotoWalletOnStartup => _gotoWalletOnStartup;

  set gotoWalletOnStartup(bool gotoWalletOnStartup) {
    if (_gotoWalletOnStartup != gotoWalletOnStartup) {
      DB.instance
          .put<dynamic>(
              boxName: DB.boxNamePrefs,
              key: "gotoWalletOnStartup",
              value: gotoWalletOnStartup)
          .then((_) {
        _gotoWalletOnStartup = gotoWalletOnStartup;
        notifyListeners();
      });
    }
  }

  Future<bool> _getGotoWalletOnStartup() async {
    return await DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs, key: "gotoWalletOnStartup") as bool? ??
        false;
  }

  // startup wallet id

  String? _startupWalletId;

  String? get startupWalletId => _startupWalletId;

  set startupWalletId(String? startupWalletId) {
    if (this.startupWalletId != startupWalletId) {
      DB.instance.put<dynamic>(
          boxName: DB.boxNamePrefs,
          key: "startupWalletId",
          value: startupWalletId);
      _startupWalletId = startupWalletId;
      notifyListeners();
    }
  }

  Future<String?> _getStartupWalletId() async {
    return await DB.instance.get<dynamic>(
        boxName: DB.boxNamePrefs, key: "startupWalletId") as String?;
  }

  // incognito mode off by default
  // allow external network calls such as exchange data and price info
  bool _externalCalls = true;

  bool get externalCalls => _externalCalls;

  set externalCalls(bool externalCalls) {
    if (_externalCalls != externalCalls) {
      DB.instance
          .put<dynamic>(
              boxName: DB.boxNamePrefs,
              key: "externalCalls",
              value: externalCalls)
          .then((_) {
        _externalCalls = externalCalls;
        notifyListeners();
      });
    }
  }

  Future<bool> _getHasExternalCalls() async {
    return await DB.instance.get<dynamic>(
            boxName: DB.boxNamePrefs, key: "externalCalls") as bool? ??
        true;
  }

  Future<bool> isExternalCallsSet() async {
    if (await DB.instance
            .get<dynamic>(boxName: DB.boxNamePrefs, key: "externalCalls") ==
        null) {
      return false;
    }
    return true;
  }

  String? _userId;
  String? get userID => _userId;

  Future<String?> _getUserId() async {
    String? userID = await DB.instance
        .get<dynamic>(boxName: DB.boxNamePrefs, key: "userID") as String?;
    if (userID == null) {
      userID = const Uuid().v4();
      await saveUserID(userID);
    }
    return userID;
  }

  Future<void> saveUserID(String userId) async {
    _userId = userId;
    await DB.instance
        .put<dynamic>(boxName: DB.boxNamePrefs, key: "userID", value: _userId);
    // notifyListeners();
  }

  int? _signupEpoch;
  int? get signupEpoch => _signupEpoch;

  Future<int?> _getSignupEpoch() async {
    int? signupEpoch = await DB.instance
        .get<dynamic>(boxName: DB.boxNamePrefs, key: "signupEpoch") as int?;
    if (signupEpoch == null) {
      signupEpoch = DateTime.now().millisecondsSinceEpoch ~/
          Duration.millisecondsPerSecond;
      await saveSignupEpoch(signupEpoch);
    }
    return signupEpoch;
  }

  Future<void> saveSignupEpoch(int signupEpoch) async {
    _signupEpoch = signupEpoch;
    await DB.instance.put<dynamic>(
        boxName: DB.boxNamePrefs, key: "signupEpoch", value: _signupEpoch);
    // notifyListeners();
  }
}
