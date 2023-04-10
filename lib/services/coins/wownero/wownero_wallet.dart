import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_wownero/api/exceptions/creation_transaction_exception.dart';
import 'package:cw_wownero/api/wallet.dart';
import 'package:cw_wownero/pending_wownero_transaction.dart';
import 'package:cw_wownero/wownero_wallet.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_libmonero/core/key_service.dart';
import 'package:flutter_libmonero/core/wallet_creation_service.dart';
import 'package:flutter_libmonero/view_model/send/output.dart'
    as wownero_output;
import 'package:flutter_libmonero/wownero/wownero.dart';
import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/db/isar/main_db.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/isar_models.dart' as isar_models;
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/event_bus/events/global/blocks_remaining_event.dart';
import 'package:stackwallet/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/mixins/wallet_cache.dart';
import 'package:stackwallet/services/mixins/wallet_db.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:tuple/tuple.dart';

const int MINIMUM_CONFIRMATIONS = 10;

class WowneroWallet extends CoinServiceAPI with WalletCache, WalletDB {
  WowneroWallet({
    required String walletId,
    required String walletName,
    required Coin coin,
    required SecureStorageInterface secureStorage,
    Prefs? prefs,
    MainDB? mockableOverride,
  }) {
    _walletId = walletId;
    _walletName = walletName;
    _coin = coin;
    _secureStorage = secureStorage;
    _prefs = prefs ?? Prefs.instance;
    initCache(walletId, coin);
    initWalletDB(mockableOverride: mockableOverride);
  }

  late final String _walletId;
  late final Coin _coin;
  late final SecureStorageInterface _secureStorage;
  late final Prefs _prefs;

  late String _walletName;

  bool _shouldAutoSync = false;
  bool _isConnected = false;
  bool _hasCalledExit = false;
  bool refreshMutex = false;
  bool longMutex = false;

  WalletService? walletService;
  KeyService? keysStorage;
  WowneroWalletBase? walletBase;
  WalletCreationService? _walletCreationService;
  Timer? _autoSaveTimer;

  Future<isar_models.Address?> get _currentReceivingAddress =>
      db.getAddresses(walletId).sortByDerivationIndexDesc().findFirst();
  Future<FeeObject>? _feeObject;

  Mutex prepareSendMutex = Mutex();
  Mutex estimateFeeMutex = Mutex();

  @override
  set isFavorite(bool markFavorite) {
    _isFavorite = markFavorite;
    updateCachedIsFavorite(markFavorite);
  }

  @override
  bool get isFavorite => _isFavorite ??= getCachedIsFavorite();

  bool? _isFavorite;

  @override
  bool get shouldAutoSync => _shouldAutoSync;

  @override
  set shouldAutoSync(bool shouldAutoSync) {
    if (_shouldAutoSync != shouldAutoSync) {
      _shouldAutoSync = shouldAutoSync;
      // wow wallets cannot be open at the same time
      // leave following commented out for now

      // if (!shouldAutoSync) {
      //   timer?.cancel();
      //   moneroAutosaveTimer?.cancel();
      //   timer = null;
      //   moneroAutosaveTimer = null;
      //   stopNetworkAlivePinging();
      // } else {
      //   startNetworkAlivePinging();
      //   // Walletbase needs to be open for this to work
      //   refresh();
      // }
    }
  }

  @override
  String get walletName => _walletName;

  // setter for updating on rename
  @override
  set walletName(String newName) => _walletName = newName;

  @override
  Coin get coin => _coin;

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    try {
      Logging.instance.log("confirmSend txData: $txData", level: LogLevel.Info);
      final pendingWowneroTransaction =
          txData['pendingWowneroTransaction'] as PendingWowneroTransaction;
      try {
        await pendingWowneroTransaction.commit();
        Logging.instance.log(
            "transaction ${pendingWowneroTransaction.id} has been sent",
            level: LogLevel.Info);
        return pendingWowneroTransaction.id;
      } catch (e, s) {
        Logging.instance.log("$walletName wownero confirmSend: $e\n$s",
            level: LogLevel.Error);
        rethrow;
      }
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from confirmSend(): $e\n$s",
          level: LogLevel.Info);
      rethrow;
    }
  }

  @override
  Future<String> get currentReceivingAddress async =>
      (await _currentReceivingAddress)?.value ??
      (await _generateAddressForChain(0, 0)).value;

  @override
  Future<Amount> estimateFeeFor(Amount amount, int feeRate) async {
    MoneroTransactionPriority priority;
    FeeRateType feeRateType = FeeRateType.slow;
    switch (feeRate) {
      case 1:
        priority = MoneroTransactionPriority.regular;
        feeRateType = FeeRateType.average;
        break;
      case 2:
        priority = MoneroTransactionPriority.medium;
        feeRateType = FeeRateType.average;
        break;
      case 3:
        priority = MoneroTransactionPriority.fast;
        feeRateType = FeeRateType.fast;
        break;
      case 4:
        priority = MoneroTransactionPriority.fastest;
        feeRateType = FeeRateType.fast;
        break;
      case 0:
      default:
        priority = MoneroTransactionPriority.slow;
        feeRateType = FeeRateType.slow;
        break;
    }
    var aprox;
    await estimateFeeMutex.protect(() async {
      {
        try {
          aprox = (await prepareSend(
              // This address is only used for getting an approximate fee, never for sending
              address: "WW3iVcnoAY6K9zNdU4qmdvZELefx6xZz4PMpTwUifRkvMQckyadhSPYMVPJhBdYE8P9c27fg9RPmVaWNFx1cDaj61HnetqBiy",
              amount: amount,
              args: {"feeRate": feeRateType}))['fee'];
          await Future<void>.delayed(const Duration(milliseconds: 500));
        } catch (e, s) {
          aprox = walletBase!.calculateEstimatedFee(
            priority,
            amount.raw.toInt(),
          );
        }
      }
    });

    print("this is the aprox fee $aprox for $amount");

    if (aprox is Amount) {
      return aprox as Amount;
    } else {
      return Amount(
        rawValue: BigInt.from(aprox as int),
        fractionDigits: coin.decimals,
      );
    }
  }

  @override
  Future<void> exit() async {
    if (!_hasCalledExit) {
      walletBase?.onNewBlock = null;
      walletBase?.onNewTransaction = null;
      walletBase?.syncStatusChanged = null;
      _hasCalledExit = true;
      _autoSaveTimer?.cancel();
      await walletBase?.save(prioritySave: true);
      walletBase?.close();
    }
  }

  @override
  Future<FeeObject> get fees => _feeObject ??= _getFees();

  @override
  Future<void> fullRescan(
    int maxUnusedAddressGap,
    int maxNumberOfIndexesToCheck,
  ) async {
    // clear blockchain info
    await db.deleteWalletBlockchainData(walletId);

    var restoreHeight = walletBase?.walletInfo.restoreHeight;
    highestPercentCached = 0;
    await walletBase?.rescan(height: restoreHeight);
    await refresh();
  }

  @override
  Future<bool> generateNewAddress() async {
    try {
      final currentReceiving = await _currentReceivingAddress;

      final newReceivingIndex = currentReceiving!.derivationIndex + 1;

      // Use new index to derive a new receiving address
      final newReceivingAddress = await _generateAddressForChain(
        0,
        newReceivingIndex,
      );

      // Add that new receiving address
      await db.putAddress(newReceivingAddress);

      return true;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from generateNewAddress(): $e\n$s",
          level: LogLevel.Error);
      return false;
    }
  }

  @override
  bool get hasCalledExit => _hasCalledExit;

  @override
  Future<void> initializeExisting() async {
    Logging.instance.log(
        "initializeExisting() ${coin.prettyName} wallet $walletName...",
        level: LogLevel.Info);

    if (getCachedId() == null) {
      //todo: check if print needed
      // debugPrint("Exception was thrown");
      throw Exception(
          "Attempted to initialize an existing wallet using an unknown wallet ID!");
    }

    walletService =
        wownero.createWowneroWalletService(DB.instance.moneroWalletInfoBox);
    keysStorage = KeyService(_secureStorage);

    await _prefs.init();

    String? password;
    try {
      password = await keysStorage?.getWalletPassword(walletName: _walletId);
    } catch (e, s) {
      throw Exception("Password not found $e, $s");
    }
    walletBase = (await walletService?.openWallet(_walletId, password!))
        as WowneroWalletBase;

    // await _checkCurrentReceivingAddressesForTransactions();

    Logging.instance.log(
      "Opened existing ${coin.prettyName} wallet $walletName",
      level: LogLevel.Info,
    );
  }

  @override
  Future<void> initializeNew({int seedWordsLength = 14}) async {
    await _prefs.init();

    // this should never fail
    if ((await mnemonicString) != null || (await mnemonicPassphrase) != null) {
      throw Exception(
          "Attempted to overwrite mnemonic on generate new wallet!");
    }

    // TODO: Wallet Service may need to be switched to Wownero
    walletService =
        wownero.createWowneroWalletService(DB.instance.moneroWalletInfoBox);
    keysStorage = KeyService(_secureStorage);
    WalletInfo walletInfo;
    WalletCredentials credentials;
    try {
      String name = _walletId;
      final dirPath =
          await _pathForWalletDir(name: name, type: WalletType.wownero);
      final path = await _pathForWallet(name: name, type: WalletType.wownero);
      credentials = wownero.createWowneroNewWalletCredentials(
        name: name,
        language: "English",
        seedWordsLength: seedWordsLength,
      );

      walletInfo = WalletInfo.external(
        id: WalletBase.idFor(name, WalletType.wownero),
        name: name,
        type: WalletType.wownero,
        isRecovery: false,
        restoreHeight: credentials.height ?? 0,
        date: DateTime.now(),
        path: path,
        dirPath: dirPath,
        // TODO: find out what to put for address
        address: '',
      );
      credentials.walletInfo = walletInfo;

      _walletCreationService = WalletCreationService(
        secureStorage: _secureStorage,
        walletService: walletService,
        keyService: keysStorage,
      );
      _walletCreationService?.changeWalletType();
      // To restore from a seed
      final wallet = await _walletCreationService?.create(credentials);

      final bufferedCreateHeight = (seedWordsLength == 14)
          ? getSeedHeightSync(wallet?.seed.trim() as String)
          : wownero.getHeightByDate(
              date: DateTime.now().subtract(const Duration(
                  days:
                      2))); // subtract a couple days to ensure we have a buffer for SWB

      await DB.instance.put<dynamic>(
          boxName: walletId, key: "restoreHeight", value: bufferedCreateHeight);
      walletInfo.restoreHeight = bufferedCreateHeight;

      await _secureStorage.write(
          key: '${_walletId}_mnemonic', value: wallet?.seed.trim());
      await _secureStorage.write(
        key: '${_walletId}_mnemonicPassphrase',
        value: "",
      );

      walletInfo.address = wallet?.walletAddresses.address;
      await DB.instance
          .add<WalletInfo>(boxName: WalletInfo.boxName, value: walletInfo);
      walletBase?.close();
      walletBase = wallet as WowneroWalletBase;
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
      walletBase?.close();
    }
    final node = await _getCurrentNode();
    final host = Uri.parse(node.host).host;
    await walletBase?.connectToNode(
      node: Node(
        uri: "$host:${node.port}",
        type: WalletType.wownero,
        trusted: node.trusted ?? false,
      ),
    );
    await walletBase?.startSync();
    await Future.wait([
      updateCachedId(walletId),
      updateCachedIsFavorite(false),
    ]);

    // Generate and add addresses to relevant arrays
    final initialReceivingAddress = await _generateAddressForChain(0, 0);
    // final initialChangeAddress = await _generateAddressForChain(1, 0);

    await db.putAddress(initialReceivingAddress);

    walletBase?.close();

    Logging.instance
        .log("initializeNew for $walletName $walletId", level: LogLevel.Info);
  }

  @override
  bool get isConnected => _isConnected;

  @override
  bool get isRefreshing => refreshMutex;

  @override
  // not used in wow
  Future<int> get maxFee => throw UnimplementedError();

  @override
  Future<List<String>> get mnemonic async {
    final _mnemonicString = await mnemonicString;
    if (_mnemonicString == null) {
      return [];
    }
    final List<String> data = _mnemonicString.split(' ');
    return data;
  }

  @override
  Future<String?> get mnemonicString =>
      _secureStorage.read(key: '${_walletId}_mnemonic');

  @override
  Future<String?> get mnemonicPassphrase => _secureStorage.read(
        key: '${_walletId}_mnemonicPassphrase',
      );

  @override
  Future<Map<String, dynamic>> prepareSend({
    required String address,
    required Amount amount,
    Map<String, dynamic>? args,
  }) async {
    try {
      final feeRate = args?["feeRate"];
      if (feeRate is FeeRateType) {
        MoneroTransactionPriority feePriority;
        switch (feeRate) {
          case FeeRateType.fast:
            feePriority = MoneroTransactionPriority.fast;
            break;
          case FeeRateType.average:
            feePriority = MoneroTransactionPriority.regular;
            break;
          case FeeRateType.slow:
            feePriority = MoneroTransactionPriority.slow;
            break;
        }

        Future<PendingTransaction>? awaitPendingTransaction;
        try {
          // check for send all
          bool isSendAll = false;
          final balance = await _availableBalance;
          if (amount == balance) {
            isSendAll = true;
          }
          Logging.instance.log("$address $amount $args", level: LogLevel.Info);
          String amountToSend = amount.decimal.toString();
          Logging.instance.log("$amount $amountToSend", level: LogLevel.Info);

          wownero_output.Output output = wownero_output.Output(walletBase!);
          output.address = address;
          output.sendAll = isSendAll;
          output.setCryptoAmount(amountToSend);

          List<wownero_output.Output> outputs = [output];
          Object tmp = wownero.createWowneroTransactionCreationCredentials(
            outputs: outputs,
            priority: feePriority,
          );

          await prepareSendMutex.protect(() async {
            awaitPendingTransaction = walletBase!.createTransaction(tmp);
          });
        } catch (e, s) {
          Logging.instance.log("Exception rethrown from prepareSend(): $e\n$s",
              level: LogLevel.Warning);
        }

        PendingWowneroTransaction pendingWowneroTransaction =
            await (awaitPendingTransaction!) as PendingWowneroTransaction;
        final int realFee = Amount.fromDecimal(
          Decimal.parse(pendingWowneroTransaction.feeFormatted),
          fractionDigits: coin.decimals,
        ).raw.toInt();

        Map<String, dynamic> txData = {
          "pendingWowneroTransaction": pendingWowneroTransaction,
          "fee": realFee,
          "addresss": address,
          "recipientAmt": amount,
        };

        Logging.instance.log("prepare send: $txData", level: LogLevel.Info);
        return txData;
      } else {
        throw ArgumentError("Invalid fee rate argument provided!");
      }
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from prepare send(): $e\n$s",
          level: LogLevel.Info);

      if (e.toString().contains("Incorrect unlocked balance")) {
        throw Exception("Insufficient balance!");
      } else if (e is CreationTransactionException) {
        throw Exception("Insufficient funds to pay for transaction fee!");
      } else {
        throw Exception("Transaction failed with error code $e");
      }
    }
  }

  @override
  Future<void> recoverFromMnemonic({
    required String mnemonic,
    String? mnemonicPassphrase, // not used at the moment
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
    required int height,
  }) async {
    final int seedLength = mnemonic.trim().split(" ").length;
    if (!(seedLength == 14 || seedLength == 25)) {
      throw Exception("Invalid wownero mnemonic length found: $seedLength");
    }

    await _prefs.init();
    longMutex = true;
    final start = DateTime.now();
    try {
      // check to make sure we aren't overwriting a mnemonic
      // this should never fail
      if ((await mnemonicString) != null ||
          (await this.mnemonicPassphrase) != null) {
        longMutex = false;
        throw Exception("Attempted to overwrite mnemonic on restore!");
      }
      await _secureStorage.write(
          key: '${_walletId}_mnemonic', value: mnemonic.trim());
      await _secureStorage.write(
        key: '${_walletId}_mnemonicPassphrase',
        value: mnemonicPassphrase ?? "",
      );

      // extract seed height from 14 word seed
      if (seedLength == 14) {
        height = getSeedHeightSync(mnemonic.trim());
      } else {
        // 25 word seed. TODO validate
        if (height == 0) {
          height = wownero.getHeightByDate(
              date: DateTime.now().subtract(const Duration(
                  days:
                      2))); // subtract a couple days to ensure we have a buffer for SWB\
        }
      }

      await DB.instance
          .put<dynamic>(boxName: walletId, key: "restoreHeight", value: height);

      walletService =
          wownero.createWowneroWalletService(DB.instance.moneroWalletInfoBox);
      keysStorage = KeyService(_secureStorage);
      WalletInfo walletInfo;
      WalletCredentials credentials;
      String name = _walletId;
      final dirPath =
          await _pathForWalletDir(name: name, type: WalletType.wownero);
      final path = await _pathForWallet(name: name, type: WalletType.wownero);
      credentials = wownero.createWowneroRestoreWalletFromSeedCredentials(
        name: name,
        height: height,
        mnemonic: mnemonic.trim(),
      );
      try {
        walletInfo = WalletInfo.external(
            id: WalletBase.idFor(name, WalletType.wownero),
            name: name,
            type: WalletType.wownero,
            isRecovery: false,
            restoreHeight: credentials.height ?? 0,
            date: DateTime.now(),
            path: path,
            dirPath: dirPath,
            // TODO: find out what to put for address
            address: '');
        credentials.walletInfo = walletInfo;

        _walletCreationService = WalletCreationService(
          secureStorage: _secureStorage,
          walletService: walletService,
          keyService: keysStorage,
        );
        _walletCreationService!.changeWalletType();
        // To restore from a seed
        final wallet =
            await _walletCreationService!.restoreFromSeed(credentials);
        walletInfo.address = wallet.walletAddresses.address;
        await DB.instance
            .add<WalletInfo>(boxName: WalletInfo.boxName, value: walletInfo);
        walletBase?.close();
        walletBase = wallet as WowneroWalletBase;

        await Future.wait([
          updateCachedId(walletId),
          updateCachedIsFavorite(false),
        ]);
      } catch (e, s) {
        //todo: come back to this
        debugPrint(e.toString());
        debugPrint(s.toString());
      }
      final node = await _getCurrentNode();
      final host = Uri.parse(node.host).host;
      await walletBase?.connectToNode(
        node: Node(
          uri: "$host:${node.port}",
          type: WalletType.wownero,
          trusted: node.trusted ?? false,
        ),
      );
      await walletBase?.rescan(height: credentials.height);
      walletBase?.close();
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from recoverFromMnemonic(): $e\n$s",
          level: LogLevel.Error);
      longMutex = false;
      rethrow;
    }
    longMutex = false;

    final end = DateTime.now();
    Logging.instance.log(
        "$walletName Recovery time: ${end.difference(start).inMilliseconds} millis",
        level: LogLevel.Info);
  }

  @override
  Future<void> refresh() async {
    if (refreshMutex) {
      Logging.instance.log("$walletId $walletName refreshMutex denied",
          level: LogLevel.Info);
      return;
    } else {
      refreshMutex = true;
    }

    GlobalEventBus.instance.fire(
      WalletSyncStatusChangedEvent(
        WalletSyncStatus.syncing,
        walletId,
        coin,
      ),
    );

    await _refreshTransactions();
    await _updateBalance();

    await _checkCurrentReceivingAddressesForTransactions();

    if (walletBase?.syncStatus is SyncedSyncStatus) {
      refreshMutex = false;
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );
    }
  }

  @override
  Future<bool> testNetworkConnection() async {
    return await walletBase?.isConnected() ?? false;
  }

  bool _isActive = false;

  @override
  void Function(bool)? get onIsActiveWalletChanged => (isActive) async {
        if (_isActive == isActive) {
          return;
        }
        _isActive = isActive;

        if (isActive) {
          _hasCalledExit = false;
          String? password;
          try {
            password =
                await keysStorage?.getWalletPassword(walletName: _walletId);
          } catch (e, s) {
            throw Exception("Password not found $e, $s");
          }
          walletBase = (await walletService?.openWallet(_walletId, password!))
              as WowneroWalletBase?;

          walletBase!.onNewBlock = onNewBlock;
          walletBase!.onNewTransaction = onNewTransaction;
          walletBase!.syncStatusChanged = syncStatusChanged;

          if (!(await walletBase!.isConnected())) {
            final node = await _getCurrentNode();
            final host = Uri.parse(node.host).host;
            await walletBase?.connectToNode(
              node: Node(
                uri: "$host:${node.port}",
                type: WalletType.wownero,
                trusted: node.trusted ?? false,
              ),
            );
          }
          await walletBase?.startSync();
          await refresh();
          _autoSaveTimer?.cancel();
          _autoSaveTimer = Timer.periodic(
            const Duration(seconds: 193),
            (_) async => await walletBase?.save(),
          );
        } else {
          await exit();
        }
      };

  Future<void> _updateCachedBalance(int sats) async {
    await DB.instance.put<dynamic>(
      boxName: walletId,
      key: "cachedWowneroBalanceSats",
      value: sats,
    );
  }

  int _getCachedBalance() =>
      DB.instance.get<dynamic>(
        boxName: walletId,
        key: "cachedWowneroBalanceSats",
      ) as int? ??
      0;

  Future<void> _updateBalance() async {
    final total = await _totalBalance;
    final available = await _availableBalance;
    _balance = Balance(
      total: total,
      spendable: available,
      blockedTotal: Amount(
        rawValue: BigInt.zero,
        fractionDigits: coin.decimals,
      ),
      pendingSpendable: total - available,
    );
    await updateCachedBalance(_balance!);
  }

  Future<Amount> get _availableBalance async {
    try {
      int runningBalance = 0;
      for (final entry in walletBase!.balance!.entries) {
        runningBalance += entry.value.unlockedBalance;
      }
      return Amount(
        rawValue: BigInt.from(runningBalance),
        fractionDigits: coin.decimals,
      );
    } catch (_) {
      return Amount(
        rawValue: BigInt.zero,
        fractionDigits: coin.decimals,
      );
    }
  }

  Future<Amount> get _totalBalance async {
    try {
      final balanceEntries = walletBase?.balance?.entries;
      if (balanceEntries != null) {
        int bal = 0;
        for (var element in balanceEntries) {
          bal = bal + element.value.fullBalance;
        }
        await _updateCachedBalance(bal);
        return Amount(
          rawValue: BigInt.from(bal),
          fractionDigits: coin.decimals,
        );
      } else {
        final transactions = walletBase!.transactionHistory!.transactions;
        int transactionBalance = 0;
        for (var tx in transactions!.entries) {
          if (tx.value.direction == TransactionDirection.incoming) {
            transactionBalance += tx.value.amount!;
          } else {
            transactionBalance += -tx.value.amount! - tx.value.fee!;
          }
        }

        await _updateCachedBalance(transactionBalance);
        return Amount(
          rawValue: BigInt.from(transactionBalance),
          fractionDigits: coin.decimals,
        );
      }
    } catch (_) {
      return Amount(
        rawValue: BigInt.from(_getCachedBalance()),
        fractionDigits: coin.decimals,
      );
    }
  }

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    final node = await _getCurrentNode();

    final host = Uri.parse(node.host).host;
    await walletBase?.connectToNode(
      node: Node(
        uri: "$host:${node.port}",
        type: WalletType.wownero,
        trusted: node.trusted ?? false,
      ),
    );

    // TODO: is this sync call needed? Do we need to notify ui here?
    await walletBase?.startSync();

    if (shouldRefresh) {
      await refresh();
    }
  }

  @override
  Future<void> updateSentCachedTxData(Map<String, dynamic> txData) async {
    // not used for xmr
    return;
  }

  @override
  bool validateAddress(String address) => walletBase!.validateAddress(address);

  @override
  String get walletId => _walletId;

  Future<isar_models.Address> _generateAddressForChain(
    int chain,
    int index,
  ) async {
    //
    String address = walletBase!.getTransactionAddress(chain, index);

    return isar_models.Address(
      walletId: walletId,
      derivationIndex: index,
      derivationPath: null,
      value: address,
      publicKey: [],
      type: isar_models.AddressType.cryptonote,
      subType: chain == 0
          ? isar_models.AddressSubType.receiving
          : isar_models.AddressSubType.change,
    );
  }

  Future<FeeObject> _getFees() async {
    // TODO: not use random hard coded values here
    return FeeObject(
      numberOfBlocksFast: 10,
      numberOfBlocksAverage: 15,
      numberOfBlocksSlow: 20,
      fast: MoneroTransactionPriority.fast.raw!,
      medium: MoneroTransactionPriority.regular.raw!,
      slow: MoneroTransactionPriority.slow.raw!,
    );
  }

  Future<void> _refreshTransactions() async {
    await walletBase!.updateTransactions();
    final transactions = walletBase?.transactionHistory!.transactions;

    // final cachedTransactions =
    // DB.instance.get<dynamic>(boxName: walletId, key: 'latest_tx_model')
    // as TransactionData?;
    // int latestTxnBlockHeight =
    //     DB.instance.get<dynamic>(boxName: walletId, key: "storedTxnDataHeight")
    //     as int? ??
    //         0;
    //
    // final txidsList = DB.instance
    //     .get<dynamic>(boxName: walletId, key: "cachedTxids") as List? ??
    //     [];
    //
    // final Set<String> cachedTxids = Set<String>.from(txidsList);

    // TODO: filter to skip cached + confirmed txn processing in next step
    // final unconfirmedCachedTransactions =
    //     cachedTransactions?.getAllTransactions() ?? {};
    // unconfirmedCachedTransactions
    //     .removeWhere((key, value) => value.confirmedStatus);
    //
    // if (cachedTransactions != null) {
    //   for (final tx in allTxHashes.toList(growable: false)) {
    //     final txHeight = tx["height"] as int;
    //     if (txHeight > 0 &&
    //         txHeight < latestTxnBlockHeight - MINIMUM_CONFIRMATIONS) {
    //       if (unconfirmedCachedTransactions[tx["tx_hash"] as String] == null) {
    //         allTxHashes.remove(tx);
    //       }
    //     }
    //   }
    // }

    final List<Tuple2<isar_models.Transaction, isar_models.Address?>> txnsData =
        [];

    if (transactions != null) {
      for (var tx in transactions.entries) {
        // cachedTxids.add(tx.value.id);
        // Logging.instance.log(
        //     "${tx.value.accountIndex} ${tx.value.addressIndex} ${tx.value.amount} ${tx.value.date} "
        //     "${tx.value.direction} ${tx.value.fee} ${tx.value.height} ${tx.value.id} ${tx.value.isPending} ${tx.value.key} "
        //     "${tx.value.recipientAddress}, ${tx.value.additionalInfo} con:${tx.value.confirmations}"
        //     " ${tx.value.keyIndex}",
        //     level: LogLevel.Info);
        // String am = wowneroAmountToString(amount: tx.value.amount!);
        // final worthNow = (currentPrice * Decimal.parse(am)).toStringAsFixed(2);
        // Map<String, dynamic> midSortedTx = {};
        // // // create final tx map
        // midSortedTx["txid"] = tx.value.id;
        // midSortedTx["confirmed_status"] = !tx.value.isPending &&
        //     tx.value.confirmations != null &&
        //     tx.value.confirmations! >= MINIMUM_CONFIRMATIONS;
        // midSortedTx["confirmations"] = tx.value.confirmations ?? 0;
        // midSortedTx["timestamp"] =
        //     (tx.value.date.millisecondsSinceEpoch ~/ 1000);
        // midSortedTx["txType"] =
        //     tx.value.direction == TransactionDirection.incoming
        //         ? "Received"
        //         : "Sent";
        // midSortedTx["amount"] = tx.value.amount;
        // midSortedTx["worthNow"] = worthNow;
        // midSortedTx["worthAtBlockTimestamp"] = worthNow;
        // midSortedTx["fees"] = tx.value.fee;
        // if (tx.value.direction == TransactionDirection.incoming) {
        //   final addressInfo = tx.value.additionalInfo;
        //
        //   midSortedTx["address"] = walletBase?.getTransactionAddress(
        //     addressInfo!['accountIndex'] as int,
        //     addressInfo['addressIndex'] as int,
        //   );
        // } else {
        //   midSortedTx["address"] = "";
        // }
        //
        // final int txHeight = tx.value.height ?? 0;
        // midSortedTx["height"] = txHeight;
        // // if (txHeight >= latestTxnBlockHeight) {
        // //   latestTxnBlockHeight = txHeight;
        // // }
        //
        // midSortedTx["aliens"] = <dynamic>[];
        // midSortedTx["inputSize"] = 0;
        // midSortedTx["outputSize"] = 0;
        // midSortedTx["inputs"] = <dynamic>[];
        // midSortedTx["outputs"] = <dynamic>[];
        // midSortedArray.add(midSortedTx);

        isar_models.Address? address;
        isar_models.TransactionType type;
        if (tx.value.direction == TransactionDirection.incoming) {
          final addressInfo = tx.value.additionalInfo;

          final addressString = walletBase?.getTransactionAddress(
            addressInfo!['accountIndex'] as int,
            addressInfo['addressIndex'] as int,
          );

          if (addressString != null) {
            address = await db
                .getAddresses(walletId)
                .filter()
                .valueEqualTo(addressString)
                .findFirst();
          }

          type = isar_models.TransactionType.incoming;
        } else {
          // txn.address = "";
          type = isar_models.TransactionType.outgoing;
        }

        final txn = isar_models.Transaction(
          walletId: walletId,
          txid: tx.value.id,
          timestamp: (tx.value.date.millisecondsSinceEpoch ~/ 1000),
          type: type,
          subType: isar_models.TransactionSubType.none,
          amount: tx.value.amount ?? 0,
          amountString: Amount(
            rawValue: BigInt.from(tx.value.amount ?? 0),
            fractionDigits: coin.decimals,
          ).toJsonString(),
          fee: tx.value.fee ?? 0,
          height: tx.value.height,
          isCancelled: false,
          isLelantus: false,
          slateId: null,
          otherData: null,
          nonce: null,
          inputs: [],
          outputs: [],
        );

        txnsData.add(Tuple2(txn, address));
      }
    }

    await db.addNewTransactionData(txnsData, walletId);

    // quick hack to notify manager to call notifyListeners if
    // transactions changed
    if (txnsData.isNotEmpty) {
      GlobalEventBus.instance.fire(
        UpdatedInBackgroundEvent(
          "Transactions updated/added for: $walletId $walletName  ",
          walletId,
        ),
      );
    }
  }

  Future<String> _pathForWalletDir({
    required String name,
    required WalletType type,
  }) async {
    Directory root = await StackFileSystem.applicationRootDirectory();

    final prefix = walletTypeToString(type).toLowerCase();
    final walletsDir = Directory('${root.path}/wallets');
    final walletDire = Directory('${walletsDir.path}/$prefix/$name');

    if (!walletDire.existsSync()) {
      walletDire.createSync(recursive: true);
    }

    return walletDire.path;
  }

  Future<String> _pathForWallet({
    required String name,
    required WalletType type,
  }) async =>
      await _pathForWalletDir(name: name, type: type)
          .then((path) => '$path/$name');

  Future<NodeModel> _getCurrentNode() async {
    return NodeService(secureStorageInterface: _secureStorage)
            .getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);
  }

  void onNewBlock({required int height, required int blocksLeft}) {
    //
    print("=============================");
    print("New Wownero Block! :: $walletName");
    print("=============================");
    updateCachedChainHeight(height);
    _refreshTxDataHelper();
  }

  bool _txRefreshLock = false;
  int _lastCheckedHeight = -1;
  int _txCount = 0;

  Future<void> _refreshTxDataHelper() async {
    if (_txRefreshLock) return;
    _txRefreshLock = true;

    final syncStatus = walletBase?.syncStatus;

    if (syncStatus != null && syncStatus is SyncingSyncStatus) {
      final int blocksLeft = syncStatus.blocksLeft;
      final tenKChange = blocksLeft ~/ 10000;

      // only refresh transactions periodically during a sync
      if (_lastCheckedHeight == -1 || tenKChange < _lastCheckedHeight) {
        _lastCheckedHeight = tenKChange;
        await _refreshTxData();
      }
    } else {
      await _refreshTxData();
    }

    _txRefreshLock = false;
  }

  Future<void> _refreshTxData() async {
    await _refreshTransactions();
    final count = await db.getTransactions(walletId).count();

    if (count > _txCount) {
      _txCount = count;
      await _updateBalance();
      GlobalEventBus.instance.fire(
        UpdatedInBackgroundEvent(
          "New transaction data found in $walletId $walletName!",
          walletId,
        ),
      );
    }
  }

  void onNewTransaction() {
    //
    print("=============================");
    print("New Wownero Transaction! :: $walletName");
    print("=============================");

    // call this here?
    GlobalEventBus.instance.fire(
      UpdatedInBackgroundEvent(
        "New data found in $walletId $walletName in background!",
        walletId,
      ),
    );
  }

  void syncStatusChanged() async {
    final syncStatus = walletBase?.syncStatus;
    if (syncStatus != null) {
      if (syncStatus.progress() == 1) {
        refreshMutex = false;
      }

      WalletSyncStatus? status;
      _isConnected = true;

      if (syncStatus is SyncingSyncStatus) {
        final int blocksLeft = syncStatus.blocksLeft;

        // ensure at least 1 to prevent math errors
        final int height = max(1, syncStatus.height);

        final nodeHeight = height + blocksLeft;

        final percent = height / nodeHeight;

        final highest = max(highestPercentCached, percent);

        // update cached
        if (highestPercentCached < percent) {
          highestPercentCached = percent;
        }
        await updateCachedChainHeight(height);

        GlobalEventBus.instance.fire(
          RefreshPercentChangedEvent(
            highest,
            walletId,
          ),
        );
        GlobalEventBus.instance.fire(
          BlocksRemainingEvent(
            blocksLeft,
            walletId,
          ),
        );
      } else if (syncStatus is SyncedSyncStatus) {
        status = WalletSyncStatus.synced;
      } else if (syncStatus is NotConnectedSyncStatus) {
        status = WalletSyncStatus.unableToSync;
        _isConnected = false;
      } else if (syncStatus is StartingSyncStatus) {
        status = WalletSyncStatus.syncing;
        GlobalEventBus.instance.fire(
          RefreshPercentChangedEvent(
            highestPercentCached,
            walletId,
          ),
        );
      } else if (syncStatus is FailedSyncStatus) {
        status = WalletSyncStatus.unableToSync;
        _isConnected = false;
      } else if (syncStatus is ConnectingSyncStatus) {
        status = WalletSyncStatus.syncing;
        GlobalEventBus.instance.fire(
          RefreshPercentChangedEvent(
            highestPercentCached,
            walletId,
          ),
        );
      } else if (syncStatus is ConnectedSyncStatus) {
        status = WalletSyncStatus.syncing;
        GlobalEventBus.instance.fire(
          RefreshPercentChangedEvent(
            highestPercentCached,
            walletId,
          ),
        );
      } else if (syncStatus is LostConnectionSyncStatus) {
        status = WalletSyncStatus.unableToSync;
        _isConnected = false;
      }

      if (status != null) {
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(
            status,
            walletId,
            coin,
          ),
        );
      }
    }
  }

  Future<void> _checkCurrentReceivingAddressesForTransactions() async {
    try {
      await _checkReceivingAddressForTransactions();
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkCurrentReceivingAddressesForTransactions(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _checkReceivingAddressForTransactions() async {
    try {
      int highestIndex = -1;
      for (var element
          in walletBase!.transactionHistory!.transactions!.entries) {
        if (element.value.direction == TransactionDirection.incoming) {
          int curAddressIndex =
              element.value.additionalInfo!['addressIndex'] as int;
          if (curAddressIndex > highestIndex) {
            highestIndex = curAddressIndex;
          }
        }
      }

      // Check the new receiving index
      final currentReceiving = await _currentReceivingAddress;
      final curIndex = currentReceiving?.derivationIndex ?? -1;

      if (highestIndex >= curIndex) {
        // First increment the receiving index
        final newReceivingIndex = curIndex + 1;

        // Use new index to derive a new receiving address
        final newReceivingAddress =
            await _generateAddressForChain(0, newReceivingIndex);

        final existing = await db
            .getAddresses(walletId)
            .filter()
            .valueEqualTo(newReceivingAddress.value)
            .findFirst();
        if (existing == null) {
          // Add that new change address
          await db.putAddress(newReceivingAddress);
        } else {
          // we need to update the address
          await db.updateAddress(existing, newReceivingAddress);
        }
        // keep checking until address with no tx history is set as current
        await _checkReceivingAddressForTransactions();
      }
    } on SocketException catch (se, s) {
      Logging.instance.log(
          "SocketException caught in _checkReceivingAddressForTransactions(): $se\n$s",
          level: LogLevel.Error);
      return;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from _checkReceivingAddressForTransactions(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  double get highestPercentCached =>
      DB.instance.get<dynamic>(boxName: walletId, key: "highestPercentCached")
          as double? ??
      0;

  set highestPercentCached(double value) => DB.instance.put<dynamic>(
        boxName: walletId,
        key: "highestPercentCached",
        value: value,
      );

  @override
  int get storedChainHeight => getCachedChainHeight();

  @override
  Balance get balance => _balance ??= getCachedBalance();
  Balance? _balance;

  @override
  Future<List<isar_models.Transaction>> get transactions =>
      db.getTransactions(walletId).sortByTimestampDesc().findAll();

  @override
  // TODO: implement utxos
  Future<List<isar_models.UTXO>> get utxos => throw UnimplementedError();
}
