import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:stack_wallet_backup/stack_wallet_backup.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/contact.dart';
import 'package:stackwallet/models/contact_address_entry.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackwallet/models/exchange/response_objects/trade.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/stack_restoring_ui_state.dart';
import 'package:stackwallet/models/trade_wallet_lookup.dart';
import 'package:stackwallet/models/wallet_restore_state.dart';
import 'package:stackwallet/services/address_book_service.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/notes_service.dart';
import 'package:stackwallet/services/trade_notes_service.dart';
import 'package:stackwallet/services/trade_sent_from_stack_service.dart';
import 'package:stackwallet/services/trade_service.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/services/wallets_service.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/backup_frequency_type.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/stack_restoring_status.dart';
import 'package:stackwallet/utilities/enums/sync_type_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/util.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock/wakelock.dart';

class PreRestoreState {
  final Set<String> walletIds;
  final Map<String, dynamic> validJSON;

  PreRestoreState(this.walletIds, this.validJSON);
}

String getErrorMessageFromSWBException(Exception e) {
  String errorMessage = e.toString();
  if (e is BadDataLength) {
    errorMessage = e.errMsg();
  } else if (e is BadProtocolVersion) {
    errorMessage = e.errMsg();
  } else if (e is FailedDecryption) {
    errorMessage = e.errMsg();
  } else if (e is BadChecksum) {
    errorMessage = e.errMsg();
  } else if (e is BadAadLength) {
    errorMessage = e.errMsg();
  }
  return errorMessage;
}

String createAutoBackupFilename(String dirPath, DateTime date) {
  // this filename structure is important. DO NOT CHANGE
  return "$dirPath/stackautobackup_${date.year}_${date.month}_${date.day}_${date.hour}_${date.minute}_${date.second}.swb";
}

abstract class SWB {
  static Completer<void>? _cancelCompleter;

  static Future<void> cancelRestore() async {
    if (!_shouldCancelRestore) {
      _cancelCompleter = null;
      _cancelCompleter = Completer<void>();
      _shouldCancelRestore = true;
      Logging.instance
          .log("SWB cancel restore requested", level: LogLevel.Info);
    } else {
      Logging.instance.log(
          "SWB cancel restore requested while a cancellation request is currently in progress",
          level: LogLevel.Warning);
    }

    // return completer that will complete on SWBRestoreCancelEventType.completed event
    return _cancelCompleter!.future;
  }

  static bool _shouldCancelRestore = false;

  static bool _checkShouldCancel(
    PreRestoreState? revertToState,
    SecureStorageInterface secureStorageInterface,
  ) {
    if (_shouldCancelRestore) {
      if (revertToState != null) {
        _revert(revertToState, secureStorageInterface);
      } else {
        _cancelCompleter!.complete();
        _shouldCancelRestore = false;
      }

      return true;
    } else {
      return false;
    }
  }

  static Future<bool> encryptStackWalletWithPassphrase(
    String fileToSave,
    String passphrase,
    String plaintext,
  ) async {
    try {
      File backupFile = File(fileToSave);
      if (!backupFile.existsSync()) {
        String jsonBackup = plaintext;
        Uint8List content = Uint8List.fromList(utf8.encode(jsonBackup));
        Uint8List encryptedContent =
            await encryptWithPassphrase(passphrase, content);
        backupFile
            .writeAsStringSync(Format.uint8listToString(encryptedContent));
      }
      Logging.instance.log(backupFile.absolute, level: LogLevel.Info);
      return true;
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Error);
      return false;
    }
  }

  static Future<bool> encryptStackWalletWithADK(
    String fileToSave,
    String adk,
    String plaintext,
    int adkVersion,
  ) async {
    try {
      File backupFile = File(fileToSave);
      if (!backupFile.existsSync()) {
        String jsonBackup = plaintext;
        Uint8List content = Uint8List.fromList(utf8.encode(jsonBackup));
        Uint8List encryptedContent = await encryptWithAdk(
            Format.stringToUint8List(adk), content,
            version: adkVersion);
        backupFile
            .writeAsStringSync(Format.uint8listToString(encryptedContent));
      }
      Logging.instance.log(backupFile.absolute, level: LogLevel.Info);
      return true;
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Error);
      return false;
    }
  }

  static Future<String?> decryptStackWalletWithPassphrase(
    Tuple2<String, String> data,
  ) async {
    try {
      String fileToRestore = data.item1;
      String passphrase = data.item2;
      File backupFile = File(fileToRestore);
      String encryptedText = await backupFile.readAsString();
      return await decryptStackWalletStringWithPassphrase(
        Tuple2(encryptedText, passphrase),
      );
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Error);
      return null;
    }
  }

  static Future<String?> decryptStackWalletStringWithPassphrase(
    Tuple2<String, String> data,
  ) async {
    try {
      String encryptedText = data.item1;
      String passphrase = data.item2;

      final Uint8List encryptedBytes = Format.stringToUint8List(encryptedText);

      Uint8List decryptedContent =
          await decryptWithPassphrase(passphrase, encryptedBytes);

      final String jsonBackup = utf8.decode(decryptedContent);
      return jsonBackup;
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Error);
      return null;
    }
  }

  /// [secureStorage] parameter exposed for testing purposes
  static Future<Map<String, dynamic>> createStackWalletJSON({
    required SecureStorageInterface secureStorage,
  }) async {
    Logging.instance
        .log("Starting createStackWalletJSON...", level: LogLevel.Info);
    final _wallets = Wallets.sharedInstance;
    Map<String, dynamic> backupJson = {};
    NodeService nodeService =
        NodeService(secureStorageInterface: secureStorage);
    final _secureStore = secureStorage;

    Logging.instance.log("createStackWalletJSON awaiting DB.instance.mutex...",
        level: LogLevel.Info);
    // prevent modification of data
    await DB.instance.mutex.protect(() async {
      Logging.instance.log(
          "...createStackWalletJSON DB.instance.mutex acquired",
          level: LogLevel.Info);
      Logging.instance.log(
        "SWB backing up nodes",
        level: LogLevel.Warning,
      );
      try {
        var primaryNodes = nodeService.primaryNodes.map((e) async {
          final map = e.toMap();
          map["password"] = await e.getPassword(_secureStore);
          return map;
        }).toList();
        backupJson['primaryNodes'] = await Future.wait(primaryNodes);
      } catch (e, s) {
        Logging.instance.log("$e $s", level: LogLevel.Warning);
      }
      try {
        final nodesFuture = nodeService.nodes.map((e) async {
          final map = e.toMap();
          map["password"] = await e.getPassword(_secureStore);
          return map;
        }).toList();
        final nodes = await Future.wait(nodesFuture);
        backupJson['nodes'] = nodes;
      } catch (e, s) {
        Logging.instance.log("$e $s", level: LogLevel.Error);
      }

      Logging.instance.log(
        "SWB backing up prefs",
        level: LogLevel.Warning,
      );

      Map<String, dynamic> prefs = {};
      final _prefs = Prefs.instance;
      await _prefs.init();
      prefs['currency'] = _prefs.currency;
      prefs['useBiometrics'] = _prefs.useBiometrics;
      prefs['hasPin'] = _prefs.hasPin;
      prefs['language'] = _prefs.language;
      prefs['showFavoriteWallets'] = _prefs.showFavoriteWallets;
      prefs['wifiOnly'] = _prefs.wifiOnly;
      prefs['syncType'] = _prefs.syncType.name;
      prefs['walletIdsSyncOnStartup'] = _prefs.walletIdsSyncOnStartup;
      prefs['showTestNetCoins'] = _prefs.showTestNetCoins;
      prefs['isAutoBackupEnabled'] = _prefs.isAutoBackupEnabled;
      prefs['autoBackupLocation'] = _prefs.autoBackupLocation;
      prefs['backupFrequencyType'] = _prefs.backupFrequencyType.toString();
      prefs['lastAutoBackup'] = _prefs.lastAutoBackup.toString();

      backupJson['prefs'] = prefs;

      Logging.instance.log(
        "SWB backing up addressbook",
        level: LogLevel.Warning,
      );

      AddressBookService addressBookService = AddressBookService();
      var addresses = await addressBookService.addressBookEntries;
      backupJson['addressBookEntries'] =
          addresses.map((e) => e.toMap()).toList();

      Logging.instance.log(
        "SWB backing up wallets",
        level: LogLevel.Warning,
      );

      List<dynamic> backupWallets = [];
      for (var manager in _wallets.managers) {
        Map<String, dynamic> backupWallet = {};
        backupWallet['name'] = manager.walletName;
        backupWallet['id'] = manager.walletId;
        backupWallet['isFavorite'] = manager.isFavorite;
        backupWallet['mnemonic'] = await manager.mnemonic;
        backupWallet['mnemonicPassphrase'] = await manager.mnemonicPassphrase;
        backupWallet['coinName'] = manager.coin.name;
        backupWallet['storedChainHeight'] = DB.instance
            .get<dynamic>(boxName: manager.walletId, key: 'storedChainHeight');

        backupWallet['txidList'] = DB.instance.get<dynamic>(
            boxName: manager.walletId, key: "cachedTxids") as List?;
        // the following can cause a deadlock
        // (await manager.transactionData).getAllTransactions().keys.toList();

        backupWallet['restoreHeight'] = DB.instance
            .get<dynamic>(boxName: manager.walletId, key: 'restoreHeight');

        NotesService notesService = NotesService(walletId: manager.walletId);
        var notes = await notesService.notes;
        backupWallet['notes'] = notes;

        backupWallets.add(backupWallet);
      }
      backupJson['wallets'] = backupWallets;

      Logging.instance.log(
        "SWB backing up trades",
        level: LogLevel.Warning,
      );

      // back up trade history
      final tradesService = TradesService();
      final trades =
          tradesService.trades.map((e) => e.toMap()).toList(growable: false);
      backupJson["tradeHistory"] = trades;

      // back up trade history lookup data for trades send from stack wallet
      final tradeTxidLookupDataService = TradeSentFromStackService();
      final lookupData =
          tradeTxidLookupDataService.all.map((e) => e.toMap()).toList();
      backupJson["tradeTxidLookupData"] = lookupData;

      Logging.instance.log(
        "SWB backing up trade notes",
        level: LogLevel.Warning,
      );

      // back up trade notes
      final tradeNotesService = TradeNotesService();
      final tradeNotes = tradeNotesService.all;
      backupJson["tradeNotes"] = tradeNotes;
    });
    Logging.instance.log("createStackWalletJSON DB.instance.mutex released",
        level: LogLevel.Info);

    // // back up notifications data
    // final notificationsService = NotificationsService();
    // await notificationsService.init(nodeService, tradesService);
    // backupJson["allNotifications"] = notificationsService.notifications
    //     .map((e) => e.toMap())
    //     .toList(growable: false);

    Logging.instance
        .log("...createStackWalletJSON complete", level: LogLevel.Info);
    return backupJson;
  }

  static Future<bool> asyncRestore(
    Tuple2<dynamic, Manager> tuple,
    StackRestoringUIState? uiState,
    WalletsService walletsService,
  ) async {
    final manager = tuple.item2;
    final walletbackup = tuple.item1;

    List<String> mnemonicList = (walletbackup['mnemonic'] as List<dynamic>)
        .map<String>((e) => e as String)
        .toList();
    final String mnemonic = mnemonicList.join(" ").trim();
    final String mnemonicPassphrase =
        walletbackup['mnemonicPassphrase'] as String? ?? "";

    uiState?.update(
      walletId: manager.walletId,
      restoringStatus: StackRestoringStatus.restoring,
      mnemonic: mnemonic,
      mnemonicPassphrase: mnemonicPassphrase,
    );

    if (_shouldCancelRestore) {
      return false;
    }

    try {
      int restoreHeight = 0;

      restoreHeight = walletbackup['restoreHeight'] as int? ?? 0;
      if (restoreHeight <= 0) {
        restoreHeight = walletbackup['storedChainHeight'] as int? ?? 0;
      }

      manager.isFavorite = walletbackup['isFavorite'] == "false" ? false : true;

      if (_shouldCancelRestore) {
        return false;
      }

      // restore notes
      NotesService notesService = NotesService(walletId: manager.walletId);
      final notes = walletbackup["notes"] as Map?;
      if (notes != null) {
        for (final note in notes.entries) {
          await notesService.editOrAddNote(
              txid: note.key as String, note: note.value as String);
        }
      }

      if (_shouldCancelRestore) {
        return false;
      }

      // TODO GUI option to set maxUnusedAddressGap?
      // default is 20 but it may miss some transactions if
      // the previous wallet software generated many addresses
      // without using them
      await manager.recoverFromMnemonic(
        mnemonic: mnemonic,
        mnemonicPassphrase: mnemonicPassphrase,
        maxUnusedAddressGap: manager.coin == Coin.firo ? 50 : 20,
        maxNumberOfIndexesToCheck: 1000,
        height: restoreHeight,
      );

      if (_shouldCancelRestore) {
        return false;
      }

      // if mnemonic verified does not get set the wallet will be deleted on app restart
      await walletsService.setMnemonicVerified(walletId: manager.walletId);

      if (_shouldCancelRestore) {
        return false;
      }

      Logging.instance.log(
          "SWB restored: ${manager.walletId} ${manager.walletName} ${manager.coin.prettyName}",
          level: LogLevel.Info);

      final currentAddress = await manager.currentReceivingAddress;
      uiState?.update(
        walletId: manager.walletId,
        restoringStatus: StackRestoringStatus.success,
        manager: manager,
        address: currentAddress,
        height: restoreHeight,
        mnemonic: mnemonic,
        mnemonicPassphrase: mnemonicPassphrase,
      );
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Warning);
      uiState?.update(
        walletId: manager.walletId,
        restoringStatus: StackRestoringStatus.failed,
        manager: manager,
        mnemonic: mnemonic,
        mnemonicPassphrase: mnemonicPassphrase,
      );
      return false;
    }
    return true;
  }

  static Future<void> _restoreEverythingButWallets(
    Map<String, dynamic> validJSON,
    StackRestoringUIState? uiState,
    Map<String, String> oldToNewWalletIdMap,
    SecureStorageInterface secureStorageInterface,
  ) async {
    Map<String, dynamic> prefs = validJSON["prefs"] as Map<String, dynamic>;
    List<dynamic>? addressBookEntries =
        validJSON["addressBookEntries"] as List?;
    List<dynamic>? primaryNodes = validJSON["primaryNodes"] as List?;
    List<dynamic>? nodes = validJSON["nodes"] as List?;
    List<dynamic>? trades = validJSON["tradeHistory"] as List?;
    List<dynamic>? tradeTxidLookupData =
        validJSON["tradeTxidLookupData"] as List?;
    Map<String, dynamic>? tradeNotes =
        validJSON["tradeNotes"] as Map<String, dynamic>?;

    uiState?.preferences = StackRestoringStatus.restoring;

    Logging.instance.log(
      "SWB restoring prefs",
      level: LogLevel.Warning,
    );
    await _restorePrefs(prefs);

    uiState?.preferences = StackRestoringStatus.success;
    uiState?.addressBook = StackRestoringStatus.restoring;

    Logging.instance.log(
      "SWB restoring addressbook",
      level: LogLevel.Warning,
    );
    if (addressBookEntries != null) {
      await _restoreAddressBook(addressBookEntries);
    }

    uiState?.addressBook = StackRestoringStatus.success;
    uiState?.nodes = StackRestoringStatus.restoring;

    Logging.instance.log(
      "SWB restoring nodes",
      level: LogLevel.Warning,
    );
    await _restoreNodes(
      nodes,
      primaryNodes,
      secureStorageInterface,
    );

    uiState?.nodes = StackRestoringStatus.success;
    uiState?.trades = StackRestoringStatus.restoring;

    // restore trade history
    if (trades != null) {
      Logging.instance.log(
        "SWB restoring trades",
        level: LogLevel.Warning,
      );
      await _restoreTrades(trades);
    }

    // restore trade history lookup data for trades send from stack wallet
    if (tradeTxidLookupData != null) {
      Logging.instance.log(
        "SWB restoring trade look up data",
        level: LogLevel.Warning,
      );
      await _restoreTradesLookUpData(tradeTxidLookupData, oldToNewWalletIdMap);
    }

    // restore trade notes

    if (tradeNotes != null) {
      Logging.instance.log(
        "SWB restoring trade notes",
        level: LogLevel.Warning,
      );
      await _restoreTradesNotes(tradeNotes);
    }

    uiState?.trades = StackRestoringStatus.success;
    // uiState?.notifications = RestoringState.restoring;

    // // restore notifications data
    // final notificationsService = NotificationsService();
    // await notificationsService.init(nodeService, tradesService);
    // if (allNotifications != null) {
    //   for (int i = 0; i < allNotifications.length - 1; i++) {
    //     notificationsService.add(
    //         NotificationModel.fromJson(allNotifications[i]), false);
    //   }
    //   // only call notifyListeners on last one added
    //   if (allNotifications.length > 0) {
    //     notificationsService.add(
    //         NotificationModel.fromJson(allNotifications.last), true);
    //   }
    // }

    // uiState?.notifications = RestoringState.done;
  }

  static Future<bool?> restoreStackWalletJSON(
    String jsonBackup,
    StackRestoringUIState? uiState,
    SecureStorageInterface secureStorageInterface,
  ) async {
    if (!Platform.isLinux) await Wakelock.enable();

    Logging.instance.log(
      "SWB creating temp backup",
      level: LogLevel.Warning,
    );
    final preRestoreJSON =
        await createStackWalletJSON(secureStorage: secureStorageInterface);
    Logging.instance.log(
      "SWB temp backup created",
      level: LogLevel.Warning,
    );

    List<String> _currentWalletIds = Map<String, dynamic>.from(DB.instance
                .get<dynamic>(
                    boxName: DB.boxNameAllWalletsData, key: "names") as Map? ??
            {})
        .values
        .map((e) => e["id"] as String)
        .toList();

    final preRestoreState =
        PreRestoreState(_currentWalletIds.toSet(), preRestoreJSON);

    Map<String, String> oldToNewWalletIdMap = {};

    Map<String, dynamic> validJSON =
        json.decode(jsonBackup) as Map<String, dynamic>;

    List<dynamic> wallets = validJSON["wallets"] as List;

    // check for duplicate walletIds and assign new ones if required
    for (final wallet in wallets) {
      if (_currentWalletIds.contains(wallet["id"] as String)) {
        oldToNewWalletIdMap[wallet["id"] as String] = const Uuid().v1();
      } else {
        oldToNewWalletIdMap[wallet["id"] as String] = wallet["id"] as String;
      }
    }

    uiState?.decryption = StackRestoringStatus.success;

    // basic cancel check here
    // no reverting required yet as nothing has been written to store
    if (_checkShouldCancel(
      null,
      secureStorageInterface,
    )) {
      return false;
    }

    await _restoreEverythingButWallets(
      validJSON,
      uiState,
      oldToNewWalletIdMap,
      secureStorageInterface,
    );

    // check if cancel was requested and restore previous state
    if (_checkShouldCancel(
      preRestoreState,
      secureStorageInterface,
    )) {
      return false;
    }

    final nodeService = NodeService(
      secureStorageInterface: secureStorageInterface,
    );
    final walletsService = WalletsService(
      secureStorageInterface: secureStorageInterface,
    );
    final _prefs = Prefs.instance;
    await _prefs.init();

    final List<Tuple2<dynamic, Manager>> managers = [];

    Map<String, WalletRestoreState> walletStates = {};

    for (var walletbackup in wallets) {
      // check if cancel was requested and restore previous state
      if (_checkShouldCancel(
        preRestoreState,
        secureStorageInterface,
      )) {
        return false;
      }

      Coin coin = Coin.values
          .firstWhere((element) => element.name == walletbackup['coinName']);
      String walletName = walletbackup['name'] as String;
      final walletId = oldToNewWalletIdMap[walletbackup["id"] as String]!;

      // TODO: use these for monero and possibly other coins later on?
      // final List<String> txidList = List<String>.from(walletbackup['txidList'] as List? ?? []);

      const int sanityCheckMax = 100;
      int count = 0;
      while (await walletsService.checkForDuplicate(walletName) &&
          count < sanityCheckMax) {
        walletName += " (restored)";
      }

      await walletsService.addExistingStackWallet(
        name: walletName,
        walletId: walletId,
        coin: coin,
        shouldNotifyListeners: false,
      );

      var node = nodeService.getPrimaryNodeFor(coin: coin);

      if (node == null) {
        node = DefaultNodes.getNodeFor(coin);
        await nodeService.setPrimaryNodeFor(coin: coin, node: node);
      }

      final txTracker = TransactionNotificationTracker(walletId: walletId);

      final failovers = nodeService.failoverNodesFor(coin: coin);

      // check if cancel was requested and restore previous state
      if (_checkShouldCancel(
        preRestoreState,
        secureStorageInterface,
      )) {
        return false;
      }

      final wallet = CoinServiceAPI.from(
        coin,
        walletId,
        walletName,
        secureStorageInterface,
        node,
        txTracker,
        _prefs,
        failovers,
      );

      final manager = Manager(wallet);

      managers.add(Tuple2(walletbackup, manager));
      // check if cancel was requested and restore previous state
      if (_checkShouldCancel(
        preRestoreState,
        secureStorageInterface,
      )) {
        return false;
      }

      walletStates[walletId] = WalletRestoreState(
        coin: coin,
        restoringStatus: StackRestoringStatus.waiting,
        walletId: walletId,
        walletName: walletName,
        manager: manager,
      );
    }

    // check if cancel was requested and restore previous state
    if (_checkShouldCancel(
      preRestoreState,
      secureStorageInterface,
    )) {
      return false;
    }

    // set the states so the ui can display each status as they update during restores
    uiState?.walletStates = walletStates;

    List<Future<bool>> restoreStatuses = [];
    // start restoring wallets
    for (final tuple in managers) {
      // check if cancel was requested and restore previous state
      if (_checkShouldCancel(
        preRestoreState,
        secureStorageInterface,
      )) {
        return false;
      }
      final bools = await asyncRestore(tuple, uiState, walletsService);
      restoreStatuses.add(Future(() => bools));
    }

    // check if cancel was requested and restore previous state
    if (_checkShouldCancel(
      preRestoreState,
      secureStorageInterface,
    )) {
      return false;
    }

    for (Future<bool> status in restoreStatuses) {
      // check if cancel was requested and restore previous state
      if (_checkShouldCancel(
        preRestoreState,
        secureStorageInterface,
      )) {
        return false;
      }
      await status;
    }

    if (!Platform.isLinux) await Wakelock.disable();
    // check if cancel was requested and restore previous state
    if (_checkShouldCancel(
      preRestoreState,
      secureStorageInterface,
    )) {
      return false;
    }

    Logging.instance.log("done with SWB restore", level: LogLevel.Warning);
    if (Util.isDesktop) {
      await Wallets.sharedInstance
          .loadAfterStackRestore(_prefs, managers.map((e) => e.item2).toList());
    }
    return true;
  }

  static Future<void> _revert(
    PreRestoreState revertToState,
    SecureStorageInterface secureStorageInterface,
  ) async {
    Map<String, dynamic> prefs =
        revertToState.validJSON["prefs"] as Map<String, dynamic>;
    List<dynamic>? addressBookEntries =
        revertToState.validJSON["addressBookEntries"] as List?;
    List<dynamic>? primaryNodes =
        revertToState.validJSON["primaryNodes"] as List?;
    List<dynamic>? nodes = revertToState.validJSON["nodes"] as List?;
    List<dynamic>? trades = revertToState.validJSON["tradeHistory"] as List?;
    List<dynamic>? tradeTxidLookupData =
        revertToState.validJSON["tradeTxidLookupData"] as List?;
    Map<String, dynamic>? tradeNotes =
        revertToState.validJSON["tradeNotes"] as Map<String, dynamic>?;

    // prefs
    await _restorePrefs(prefs);

    // contacts
    final addressBookService = AddressBookService();
    final allContactIds = addressBookService.contacts.map((e) => e.id);

    if (addressBookEntries == null) {
      // if no contacts were present before attempted restore then delete any that
      // could have been added before the restore was cancelled
      for (final String idToDelete in allContactIds) {
        await addressBookService.removeContact(idToDelete);
      }
    } else {
      final Map<String, dynamic> preContactMap = {};
      for (final contact in addressBookEntries) {
        preContactMap[contact['id'] as String] =
            contact as Map<String, dynamic>;
      }
      // otherwise we go through and delete any newly added contacts while
      // reverting previous contact data on contacts that may have been modified
      for (final String id in allContactIds) {
        final contact = preContactMap[id];
        // pre restore state has contact
        if (contact != null) {
          // ensure this contact's data matches the pre restore state
          List<ContactAddressEntry> addresses = [];
          for (var address in (contact['addresses'] as List<dynamic>)) {
            addresses.add(
              ContactAddressEntry(
                coin: Coin.values
                    .firstWhere((element) => element.name == address['coin']),
                address: address['address'] as String,
                label: address['label'] as String,
              ),
            );
          }
          await addressBookService.editContact(
            Contact(
              emojiChar: contact['emoji'] as String?,
              name: contact['name'] as String,
              addresses: addresses,
              isFavorite: contact['isFavorite'] as bool,
              id: contact['id'] as String,
            ),
          );
        } else {
          // otherwise remove it as it was not there before attempting SWB restore
          await addressBookService.removeContact(id);
        }
      }
    }

    // nodes
    NodeService nodeService = NodeService(
      secureStorageInterface: secureStorageInterface,
    );
    final currentNodes = nodeService.nodes;
    if (nodes == null) {
      // no pre nodes found so we delete all but defaults
      for (final node in currentNodes) {
        if (!node.isDefault) {
          await nodeService.delete(node.id, true);
        }
      }
    } else {
      final Map<String, dynamic> preNodeMap = {};
      for (final nodeData in nodes) {
        preNodeMap[nodeData['id'] as String] = nodeData as Map<String, dynamic>;
      }
      // delete only newly added during attempted restore
      for (final node in currentNodes) {
        final nodeData = preNodeMap[node.id];
        if (nodeData != null) {
          // node existed before restore attempt
          // revert to pre restore node
          await nodeService.edit(
              node.copyWith(
                host: nodeData['host'] as String,
                port: nodeData['port'] as int,
                name: nodeData['name'] as String,
                useSSL: nodeData['useSSL'] == "false" ? false : true,
                enabled: nodeData['enabled'] == "false" ? false : true,
                coinName: nodeData['coinName'] as String,
                loginName: nodeData['loginName'] as String?,
                isFailover: nodeData['isFailover'] as bool,
                isDown: nodeData['isDown'] as bool,
              ),
              nodeData['password'] as String?,
              true);
        } else {
          await nodeService.delete(node.id, true);
        }
      }
    }

    // primary nodes
    if (primaryNodes != null) {
      for (var node in primaryNodes) {
        try {
          await nodeService.setPrimaryNodeFor(
            coin: coinFromPrettyName(node['coinName'] as String),
            node: nodeService.getNodeById(id: node['id'] as String)!,
          );
        } catch (e, s) {
          Logging.instance.log("$e $s", level: LogLevel.Error);
        }
      }
    }
    await nodeService.updateDefaults();

    // trades
    final tradesService = TradesService();
    final currentTrades = tradesService.trades;

    if (trades == null) {
      // no trade history found pre restore attempt so we delete anything that
      // was added during the restore attempt
      for (final tradeTx in currentTrades) {
        await tradesService.delete(trade: tradeTx, shouldNotifyListeners: true);
      }
    } else {
      final Map<String, dynamic> preTradeMap = {};
      for (final trade in trades) {
        preTradeMap[trade['uuid'] as String] = trade as Map<String, dynamic>;
      }
      // delete only newly added during attempted restore
      for (final tradeTx in currentTrades) {
        final tradeData = preTradeMap[tradeTx.uuid];
        if (tradeData != null) {
          // trade existed before attempted restore so we don't delete it, only
          // revert data to pre restore state
          await tradesService.edit(
              trade: Trade.fromMap(tradeData as Map<String, dynamic>),
              shouldNotifyListeners: true);
        } else {
          // trade did not exist before so we delete it
          await tradesService.delete(
              trade: tradeTx, shouldNotifyListeners: true);
        }
      }
    }

    // trade notes

    final tradeNotesService = TradeNotesService();
    final currentNotes = tradeNotesService.all;

    if (tradeNotes == null) {
      for (final noteEntry in currentNotes.entries) {
        await tradeNotesService.delete(tradeId: noteEntry.key);
      }
    } else {
      // grab all trade IDs of (reverted to pre state) trades
      final idsToKeep = tradesService.trades.map((e) => e.tradeId);

      // delete all notes that don't correspond to an id that we have
      for (final noteEntry in currentNotes.entries) {
        if (!idsToKeep.contains(noteEntry.key)) {
          await tradeNotesService.delete(tradeId: noteEntry.key);
        }
      }
    }

    // trade lookup data
    // to avoid risking completely messing up here we'll accept a bit of risk
    // and completely delete everything before restoring pre state. This data
    // "Table" will be removed as it won't be needed if/when we migrate to Isar
    final tradeTxidLookupDataService = TradeSentFromStackService();
    final allItems = tradeTxidLookupDataService.all;
    for (final item in allItems) {
      await tradeTxidLookupDataService.delete(tradeWalletLookup: item);
    }
    if (tradeTxidLookupData != null) {
      for (int i = 0; i < tradeTxidLookupData.length; i++) {
        final json = Map<String, dynamic>.from(tradeTxidLookupData[i] as Map);
        TradeWalletLookup lookup = TradeWalletLookup.fromJson(json);
        await tradeTxidLookupDataService.save(tradeWalletLookup: lookup);
      }
    }

    // finally remove any added wallets
    final walletsService =
        WalletsService(secureStorageInterface: secureStorageInterface);
    final namesData = await walletsService.walletNames;
    for (final entry in namesData.entries) {
      if (!revertToState.walletIds.contains(entry.value.walletId)) {
        await walletsService.deleteWallet(entry.key, true);
      }
    }

    _cancelCompleter!.complete();
    _shouldCancelRestore = false;
    Logging.instance.log("Revert SWB complete", level: LogLevel.Info);
  }

  static Future<void> _restorePrefs(Map<String, dynamic> prefs) async {
    final _prefs = Prefs.instance;
    await _prefs.init();
    _prefs.currency = prefs['currency'] as String;
    // _prefs.useBiometrics = prefs['useBiometrics'] as bool;
    // _prefs.hasPin = prefs['hasPin'] as bool;
    _prefs.language = prefs['language'] as String;
    _prefs.showFavoriteWallets = prefs['showFavoriteWallets'] as bool;
    _prefs.wifiOnly = prefs['wifiOnly'] as bool;
    _prefs.syncType = prefs['syncType'] == "currentWalletOnly"
        ? SyncingType.currentWalletOnly
        : prefs['syncType'] == "selectedWalletsAtStartup"
            ? SyncingType.currentWalletOnly
            : SyncingType.allWalletsOnStartup; //
    _prefs.walletIdsSyncOnStartup =
        (prefs['walletIdsSyncOnStartup'] as List<dynamic>)
            .map<String>((e) => e as String)
            .toList();
    _prefs.showTestNetCoins = prefs['showTestNetCoins'] as bool;
    _prefs.isAutoBackupEnabled = prefs['isAutoBackupEnabled'] as bool;
    _prefs.autoBackupLocation = prefs['autoBackupLocation'] as String?;
    _prefs.backupFrequencyType = BackupFrequencyType.values.firstWhere(
        (e) => e.name == (prefs['backupFrequencyType'] as String?),
        orElse: () => BackupFrequencyType.everyAppStart);
    _prefs.lastAutoBackup =
        DateTime.tryParse(prefs['lastAutoBackup'] as String? ?? "");
  }

  static Future<void> _restoreAddressBook(
    List<dynamic> addressBookEntries,
  ) async {
    AddressBookService addressBookService = AddressBookService();
    for (var contact in addressBookEntries) {
      List<ContactAddressEntry> addresses = [];
      for (var address in (contact['addresses'] as List<dynamic>)) {
        addresses.add(
          ContactAddressEntry(
            coin: Coin.values
                .firstWhere((element) => element.name == address['coin']),
            address: address['address'] as String,
            label: address['label'] as String,
          ),
        );
      }
      await addressBookService.addContact(
        Contact(
          emojiChar: contact['emoji'] as String?,
          name: contact['name'] as String,
          addresses: addresses,
          isFavorite: contact['isFavorite'] as bool,
          id: contact['id'] as String,
        ),
      );
    }
  }

  static Future<void> _restoreNodes(
    List<dynamic>? nodes,
    List<dynamic>? primaryNodes,
    SecureStorageInterface secureStorageInterface,
  ) async {
    NodeService nodeService = NodeService(
      secureStorageInterface: secureStorageInterface,
    );
    if (nodes != null) {
      for (var node in nodes) {
        await nodeService.add(
          NodeModel(
            host: node['host'] as String,
            port: node['port'] as int,
            name: node['name'] as String,
            id: node['id'] as String,
            useSSL: node['useSSL'] == "false" ? false : true,
            enabled: node['enabled'] == "false" ? false : true,
            coinName: node['coinName'] as String,
            loginName: node['loginName'] as String?,
            isFailover: node['isFailover'] as bool,
            isDown: node['isDown'] as bool,
          ),
          node["password"] as String?,
          true,
        );
      }
    }
    if (primaryNodes != null) {
      for (var node in primaryNodes) {
        try {
          await nodeService.setPrimaryNodeFor(
            coin: coinFromPrettyName(node['coinName'] as String),
            node: nodeService.getNodeById(id: node['id'] as String)!,
          );
        } catch (e, s) {
          Logging.instance.log("$e $s", level: LogLevel.Error);
        }
      }
    }
    await nodeService.updateDefaults();
  }

  static Future<void> _restoreTrades(
    List<dynamic> trades,
  ) async {
    final tradesService = TradesService();
    for (int i = 0; i < trades.length - 1; i++) {
      ExchangeTransaction? exTx;
      try {
        exTx = ExchangeTransaction.fromJson(trades[i] as Map<String, dynamic>);
      } catch (e) {
        // unneeded log
        // Logging.instance.log("$e\n$s", level: LogLevel.Warning);
      }

      Trade trade;
      if (exTx != null) {
        trade = Trade.fromExchangeTransaction(exTx, false);
      } else {
        trade = Trade.fromMap(trades[i] as Map<String, dynamic>);
      }

      await tradesService.add(
        trade: trade,
        shouldNotifyListeners: false,
      );
    }
    // only call notifyListeners on last one added
    if (trades.isNotEmpty) {
      ExchangeTransaction? exTx;
      try {
        exTx =
            ExchangeTransaction.fromJson(trades.last as Map<String, dynamic>);
      } catch (e) {
        // unneeded log
        // Logging.instance.log("$e\n$s", level: LogLevel.Warning);
      }

      Trade trade;
      if (exTx != null) {
        trade = Trade.fromExchangeTransaction(exTx, false);
      } else {
        trade = Trade.fromMap(trades.last as Map<String, dynamic>);
      }

      await tradesService.add(
        trade: trade,
        shouldNotifyListeners: true,
      );
    }
  }

  static Future<void> _restoreTradesLookUpData(
    List<dynamic> tradeTxidLookupData,
    Map<String, String> oldToNewWalletIdMap,
  ) async {
    final tradeTxidLookupDataService = TradeSentFromStackService();
    for (int i = 0; i < tradeTxidLookupData.length; i++) {
      final json = Map<String, dynamic>.from(tradeTxidLookupData[i] as Map);
      TradeWalletLookup lookup = TradeWalletLookup.fromJson(json);
      // update walletIds
      List<String> walletIds =
          lookup.walletIds.map((e) => oldToNewWalletIdMap[e]!).toList();
      lookup = lookup.copyWith(walletIds: walletIds);

      final oldLookup = DB.instance.get<TradeWalletLookup>(
          boxName: DB.boxNameTradeLookup, key: lookup.uuid);
      if (oldLookup != null) {
        if (oldLookup.txid == lookup.txid &&
            oldLookup.tradeId == lookup.tradeId) {
          List<String> mergedList = oldLookup.walletIds;
          for (final id in lookup.walletIds) {
            if (!mergedList.contains(id)) {
              mergedList.add(id);
            }
          }
          lookup = lookup.copyWith(walletIds: walletIds);
        } else {
          lookup = TradeWalletLookup(
            uuid: const Uuid().v1(),
            txid: lookup.txid,
            tradeId: lookup.tradeId,
            walletIds: lookup.walletIds,
          );
        }
      }

      await tradeTxidLookupDataService.save(tradeWalletLookup: lookup);
    }
  }

  static Future<void> _restoreTradesNotes(
    Map<String, dynamic> tradeNotes,
  ) async {
    final tradeNotesService = TradeNotesService();
    for (final note in tradeNotes.entries) {
      await tradeNotesService.set(
          tradeId: note.key, note: note.value as String);
    }
  }
}
