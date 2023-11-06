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
import 'package:cw_monero/api/exceptions/creation_transaction_exception.dart';
import 'package:cw_wownero/api/wallet.dart';
import 'package:cw_wownero/pending_wownero_transaction.dart';
import 'package:cw_wownero/wownero_wallet.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_libmonero/core/key_service.dart';
import 'package:flutter_libmonero/core/wallet_creation_service.dart';
import 'package:flutter_libmonero/view_model/send/output.dart'
    as wownero_output;
import 'package:flutter_libmonero/wownero/wownero.dart' as wow_dart;
import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/models/balance.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/services/event_bus/events/global/blocks_remaining_event.dart';
import 'package:stackwallet/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/stack_file_system.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/wownero.dart';
import 'package:stackwallet/wallets/models/tx_data.dart';
import 'package:stackwallet/wallets/wallet/intermediate/cryptonote_wallet.dart';
import 'package:stackwallet/wallets/wallet/mixins/multi_address.dart';
import 'package:tuple/tuple.dart';

class WowneroWallet extends CryptonoteWallet with MultiAddress {
  WowneroWallet(Wownero wownero) : super(wownero);

  final prepareSendMutex = Mutex();
  final estimateFeeMutex = Mutex();

  bool _hasCalledExit = false;

  WalletService? cwWalletService;
  KeyService? cwKeysStorage;
  WowneroWalletBase? cwWalletBase;
  WalletCreationService? cwWalletCreationService;
  Timer? _autoSaveTimer;

  bool _txRefreshLock = false;
  int _lastCheckedHeight = -1;
  int _txCount = 0;
  int _currentKnownChainHeight = 0;
  double _highestPercentCached = 0;

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

    dynamic approximateFee;
    await estimateFeeMutex.protect(() async {
      {
        try {
          final data = await prepareSend(
            txData: TxData(
              recipients: [
                // This address is only used for getting an approximate fee, never for sending
                (
                  address:
                      "WW3iVcnoAY6K9zNdU4qmdvZELefx6xZz4PMpTwUifRkvMQckyadhSPYMVPJhBdYE8P9c27fg9RPmVaWNFx1cDaj61HnetqBiy",
                  amount: amount,
                ),
              ],
              feeRateType: feeRateType,
            ),
          );
          approximateFee = data.fee!;

          // unsure why this delay?
          await Future<void>.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          approximateFee = cwWalletBase!.calculateEstimatedFee(
            priority,
            amount.raw.toInt(),
          );
        }
      }
    });

    if (approximateFee is Amount) {
      return approximateFee as Amount;
    } else {
      return Amount(
        rawValue: BigInt.from(approximateFee as int),
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    }
  }

  @override
  Future<FeeObject> get fees async => FeeObject(
        numberOfBlocksFast: 10,
        numberOfBlocksAverage: 15,
        numberOfBlocksSlow: 20,
        fast: MoneroTransactionPriority.fast.raw!,
        medium: MoneroTransactionPriority.regular.raw!,
        slow: MoneroTransactionPriority.slow.raw!,
      );

  @override
  Future<bool> pingCheck() async {
    return await cwWalletBase?.isConnected() ?? false;
  }

  @override
  Future<void> updateBalance() async {
    final total = await _totalBalance;
    final available = await _availableBalance;

    final balance = Balance(
      total: total,
      spendable: available,
      blockedTotal: Amount(
        rawValue: BigInt.zero,
        fractionDigits: cryptoCurrency.fractionDigits,
      ),
      pendingSpendable: total - available,
    );

    await info.updateBalance(newBalance: balance, isar: mainDB.isar);
  }

  @override
  Future<void> updateChainHeight() async {
    await info.updateCachedChainHeight(
      newHeight: _currentKnownChainHeight,
      isar: mainDB.isar,
    );
  }

  @override
  Future<void> updateNode() async {
    final node = getCurrentNode();

    final host = Uri.parse(node.host).host;
    await cwWalletBase?.connectToNode(
      node: Node(
        uri: "$host:${node.port}",
        type: WalletType.wownero,
        trusted: node.trusted ?? false,
      ),
    );

    // TODO: is this sync call needed? Do we need to notify ui here?
    // await cwWalletBase?.startSync();

    // if (shouldRefresh) {
    // await refresh();
    // }
  }

  @override
  Future<void> updateTransactions() async {
    await cwWalletBase!.updateTransactions();
    final transactions = cwWalletBase?.transactionHistory!.transactions;

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

    final List<Tuple2<Transaction, Address?>> txnsData = [];

    if (transactions != null) {
      for (var tx in transactions.entries) {
        Address? address;
        TransactionType type;
        if (tx.value.direction == TransactionDirection.incoming) {
          final addressInfo = tx.value.additionalInfo;

          final addressString = cwWalletBase?.getTransactionAddress(
            addressInfo!['accountIndex'] as int,
            addressInfo['addressIndex'] as int,
          );

          if (addressString != null) {
            address = await mainDB
                .getAddresses(walletId)
                .filter()
                .valueEqualTo(addressString)
                .findFirst();
          }

          type = TransactionType.incoming;
        } else {
          // txn.address = "";
          type = TransactionType.outgoing;
        }

        final txn = Transaction(
          walletId: walletId,
          txid: tx.value.id,
          timestamp: (tx.value.date.millisecondsSinceEpoch ~/ 1000),
          type: type,
          subType: TransactionSubType.none,
          amount: tx.value.amount ?? 0,
          amountString: Amount(
            rawValue: BigInt.from(tx.value.amount ?? 0),
            fractionDigits: cryptoCurrency.fractionDigits,
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
          numberOfMessages: null,
        );

        txnsData.add(Tuple2(txn, address));
      }
    }

    await mainDB.addNewTransactionData(txnsData, walletId);
  }

  @override
  Future<void> init() async {
    cwWalletService = wow_dart.wownero
        .createWowneroWalletService(DB.instance.moneroWalletInfoBox);
    cwKeysStorage = KeyService(secureStorageInterface);

    if (await cwWalletService!.isWalletExit(walletId)) {
      String? password;
      try {
        password = await cwKeysStorage!.getWalletPassword(walletName: walletId);
      } catch (e, s) {
        throw Exception("Password not found $e, $s");
      }
      cwWalletBase = (await cwWalletService!.openWallet(walletId, password))
          as WowneroWalletBase;
    } else {
      WalletInfo walletInfo;
      WalletCredentials credentials;
      try {
        String name = walletId;
        final dirPath =
            await _pathForWalletDir(name: name, type: WalletType.wownero);
        final path = await _pathForWallet(name: name, type: WalletType.wownero);
        credentials = wow_dart.wownero.createWowneroNewWalletCredentials(
          name: name,
          language: "English",
          seedWordsLength: 14,
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

        final _walletCreationService = WalletCreationService(
          secureStorage: secureStorageInterface,
          walletService: cwWalletService,
          keyService: cwKeysStorage,
        );
        // _walletCreationService.changeWalletType();
        _walletCreationService.type = WalletType.wownero;
        // To restore from a seed
        final wallet = await _walletCreationService.create(credentials);
        //
        // final bufferedCreateHeight = (seedWordsLength == 14)
        //     ? getSeedHeightSync(wallet?.seed.trim() as String)
        //     : wownero.getHeightByDate(
        //     date: DateTime.now().subtract(const Duration(
        //         days:
        //         2))); // subtract a couple days to ensure we have a buffer for SWB
        final bufferedCreateHeight = getSeedHeightSync(wallet!.seed.trim());

        // TODO: info.updateRestoreHeight
        await DB.instance.put<dynamic>(
            boxName: walletId,
            key: "restoreHeight",
            value: bufferedCreateHeight);

        walletInfo.restoreHeight = bufferedCreateHeight;

        walletInfo.address = wallet.walletAddresses.address;
        await DB.instance
            .add<WalletInfo>(boxName: WalletInfo.boxName, value: walletInfo);

        cwWalletBase?.close();
        cwWalletBase = wallet as WowneroWalletBase;
      } catch (e, s) {
        Logging.instance.log("$e\n$s", level: LogLevel.Fatal);
        cwWalletBase?.close();
      }
      await updateNode();
      await cwWalletBase?.startSync();

      cwWalletBase?.close();
    }

    return super.init();
  }

  @override
  Future<void> exit() async {
    if (!_hasCalledExit) {
      _hasCalledExit = true;
      cwWalletBase?.onNewBlock = null;
      cwWalletBase?.onNewTransaction = null;
      cwWalletBase?.syncStatusChanged = null;
      _autoSaveTimer?.cancel();
      await cwWalletBase?.save(prioritySave: true);
      cwWalletBase?.close();
    }
  }

  @override
  Future<void> generateNewReceivingAddress() async {
    try {
      final currentReceiving = await getCurrentReceivingAddress();

      final newReceivingIndex =
          currentReceiving == null ? 0 : currentReceiving.derivationIndex + 1;

      final newReceivingAddress = _addressFor(index: newReceivingIndex);

      // Add that new receiving address
      await mainDB.putAddress(newReceivingAddress);
      await info.updateReceivingAddress(
        newAddress: newReceivingAddress.value,
        isar: mainDB.isar,
      );
    } catch (e, s) {
      Logging.instance.log(
        "Exception in generateNewAddress(): $e\n$s",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<void> checkReceivingAddressForTransactions() async {
    try {
      int highestIndex = -1;
      for (var element
          in cwWalletBase!.transactionHistory!.transactions!.entries) {
        if (element.value.direction == TransactionDirection.incoming) {
          int curAddressIndex =
              element.value.additionalInfo!['addressIndex'] as int;
          if (curAddressIndex > highestIndex) {
            highestIndex = curAddressIndex;
          }
        }
      }

      // Check the new receiving index
      final currentReceiving = await getCurrentReceivingAddress();
      final curIndex = currentReceiving?.derivationIndex ?? -1;

      if (highestIndex >= curIndex) {
        // First increment the receiving index
        final newReceivingIndex = curIndex + 1;

        // Use new index to derive a new receiving address
        final newReceivingAddress = _addressFor(index: newReceivingIndex);

        final existing = await mainDB
            .getAddresses(walletId)
            .filter()
            .valueEqualTo(newReceivingAddress.value)
            .findFirst();
        if (existing == null) {
          // Add that new change address
          await mainDB.putAddress(newReceivingAddress);
        } else {
          // we need to update the address
          await mainDB.updateAddress(existing, newReceivingAddress);
        }
        // keep checking until address with no tx history is set as current
        await checkReceivingAddressForTransactions();
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

  @override
  Future<void> refresh() async {
    // Awaiting this lock could be dangerous.
    // Since refresh is periodic (generally)
    if (refreshMutex.isLocked) {
      return;
    }

    // this acquire should be almost instant due to above check.
    // Slight possibility of race but should be irrelevant
    await refreshMutex.acquire();

    GlobalEventBus.instance.fire(
      WalletSyncStatusChangedEvent(
        WalletSyncStatus.syncing,
        walletId,
        info.coin,
      ),
    );

    await updateTransactions();
    await updateBalance();

    await checkReceivingAddressForTransactions();

    if (cwWalletBase?.syncStatus is SyncedSyncStatus) {
      refreshMutex.release();
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          info.coin,
        ),
      );
    }
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    if (isRescan) {
      await refreshMutex.protect(() async {
        // clear blockchain info
        await mainDB.deleteWalletBlockchainData(walletId);

        var restoreHeight = cwWalletBase?.walletInfo.restoreHeight;
        _highestPercentCached = 0;
        await cwWalletBase?.rescan(height: restoreHeight);
      });
      await refresh();
      return;
    }

    await refreshMutex.protect(() async {
      final mnemonic = await getMnemonic();
      final seedLength = mnemonic.trim().split(" ").length;

      if (!(seedLength == 14 || seedLength == 25)) {
        throw Exception("Invalid wownero mnemonic length found: $seedLength");
      }

      try {
        int height = info.restoreHeight;

        // extract seed height from 14 word seed
        if (seedLength == 14) {
          height = getSeedHeightSync(mnemonic.trim());
        } else {
          // 25 word seed. TODO validate
          if (height == 0) {
            height = wow_dart.wownero.getHeightByDate(
              date: DateTime.now().subtract(
                const Duration(
                  // subtract a couple days to ensure we have a buffer for SWB
                  days: 2,
                ),
              ),
            );
          }
        }

        // TODO: info.updateRestoreHeight
        // await DB.instance
        //     .put<dynamic>(boxName: walletId, key: "restoreHeight", value: height);

        cwWalletService = wow_dart.wownero
            .createWowneroWalletService(DB.instance.moneroWalletInfoBox);
        cwKeysStorage = KeyService(secureStorageInterface);
        WalletInfo walletInfo;
        WalletCredentials credentials;
        String name = walletId;
        final dirPath =
            await _pathForWalletDir(name: name, type: WalletType.wownero);
        final path = await _pathForWallet(name: name, type: WalletType.wownero);
        credentials =
            wow_dart.wownero.createWowneroRestoreWalletFromSeedCredentials(
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

          cwWalletCreationService = WalletCreationService(
            secureStorage: secureStorageInterface,
            walletService: cwWalletService,
            keyService: cwKeysStorage,
          );
          cwWalletCreationService!.changeWalletType();
          // To restore from a seed
          final wallet =
              await cwWalletCreationService!.restoreFromSeed(credentials);
          walletInfo.address = wallet.walletAddresses.address;
          await DB.instance
              .add<WalletInfo>(boxName: WalletInfo.boxName, value: walletInfo);
          cwWalletBase?.close();
          cwWalletBase = wallet as WowneroWalletBase;
        } catch (e, s) {
          Logging.instance.log("$e\n$s", level: LogLevel.Fatal);
        }
        await updateNode();

        await cwWalletBase?.rescan(height: credentials.height);
        cwWalletBase?.close();
      } catch (e, s) {
        Logging.instance.log(
            "Exception rethrown from recoverFromMnemonic(): $e\n$s",
            level: LogLevel.Error);
        rethrow;
      }
    });
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    try {
      final feeRate = txData.feeRateType;
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
          default:
            throw ArgumentError("Invalid use of custom fee");
        }

        Future<PendingTransaction>? awaitPendingTransaction;
        try {
          // check for send all
          bool isSendAll = false;
          final balance = await _availableBalance;
          if (txData.amount! == balance &&
              txData.recipients!.first.amount == balance) {
            isSendAll = true;
          }

          List<wownero_output.Output> outputs = [];
          for (final recipient in txData.recipients!) {
            final output = wownero_output.Output(cwWalletBase!);
            output.address = recipient.address;
            output.sendAll = isSendAll;
            String amountToSend = recipient.amount.decimal.toString();
            output.setCryptoAmount(amountToSend);
          }

          final tmp =
              wow_dart.wownero.createWowneroTransactionCreationCredentials(
            outputs: outputs,
            priority: feePriority,
          );

          await prepareSendMutex.protect(() async {
            awaitPendingTransaction = cwWalletBase!.createTransaction(tmp);
          });
        } catch (e, s) {
          Logging.instance.log("Exception rethrown from prepareSend(): $e\n$s",
              level: LogLevel.Warning);
        }

        PendingWowneroTransaction pendingWowneroTransaction =
            await (awaitPendingTransaction!) as PendingWowneroTransaction;
        final realFee = Amount.fromDecimal(
          Decimal.parse(pendingWowneroTransaction.feeFormatted),
          fractionDigits: cryptoCurrency.fractionDigits,
        );

        return txData.copyWith(
          fee: realFee,
          pendingWowneroTransaction: pendingWowneroTransaction,
        );
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
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      try {
        await txData.pendingWowneroTransaction!.commit();
        Logging.instance.log(
            "transaction ${txData.pendingWowneroTransaction!.id} has been sent",
            level: LogLevel.Info);
        return txData.copyWith(txid: txData.pendingWowneroTransaction!.id);
      } catch (e, s) {
        Logging.instance.log("${info.name} wownero confirmSend: $e\n$s",
            level: LogLevel.Error);
        rethrow;
      }
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from confirmSend(): $e\n$s",
          level: LogLevel.Info);
      rethrow;
    }
  }

  // ====== private ============================================================

  void onNewBlock({required int height, required int blocksLeft}) {
    _currentKnownChainHeight = height;
    updateChainHeight();
    _refreshTxDataHelper();
  }

  void onNewTransaction() {
    // call this here?
    GlobalEventBus.instance.fire(
      UpdatedInBackgroundEvent(
        "New data found in $walletId ${info.name} in background!",
        walletId,
      ),
    );
  }

  void syncStatusChanged() async {
    final syncStatus = cwWalletBase?.syncStatus;
    if (syncStatus != null) {
      if (syncStatus.progress() == 1) {
        refreshMutex.release();
      }

      WalletSyncStatus? status;
      xmrAndWowSyncSpecificFunctionThatShouldBeGottenRidOfInTheFuture(true);

      if (syncStatus is SyncingSyncStatus) {
        final int blocksLeft = syncStatus.blocksLeft;

        // ensure at least 1 to prevent math errors
        final int height = max(1, syncStatus.height);

        final nodeHeight = height + blocksLeft;
        _currentKnownChainHeight = nodeHeight;

        final percent = height / nodeHeight;

        final highest = max(_highestPercentCached, percent);

        // update cached
        if (_highestPercentCached < percent) {
          _highestPercentCached = percent;
        }

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
        xmrAndWowSyncSpecificFunctionThatShouldBeGottenRidOfInTheFuture(false);
      } else if (syncStatus is StartingSyncStatus) {
        status = WalletSyncStatus.syncing;
        GlobalEventBus.instance.fire(
          RefreshPercentChangedEvent(
            _highestPercentCached,
            walletId,
          ),
        );
      } else if (syncStatus is FailedSyncStatus) {
        status = WalletSyncStatus.unableToSync;
        xmrAndWowSyncSpecificFunctionThatShouldBeGottenRidOfInTheFuture(false);
      } else if (syncStatus is ConnectingSyncStatus) {
        status = WalletSyncStatus.syncing;
        GlobalEventBus.instance.fire(
          RefreshPercentChangedEvent(
            _highestPercentCached,
            walletId,
          ),
        );
      } else if (syncStatus is ConnectedSyncStatus) {
        status = WalletSyncStatus.syncing;
        GlobalEventBus.instance.fire(
          RefreshPercentChangedEvent(
            _highestPercentCached,
            walletId,
          ),
        );
      } else if (syncStatus is LostConnectionSyncStatus) {
        status = WalletSyncStatus.unableToSync;
        xmrAndWowSyncSpecificFunctionThatShouldBeGottenRidOfInTheFuture(false);
      }

      if (status != null) {
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(
            status,
            walletId,
            info.coin,
          ),
        );
      }
    }
  }

  Address _addressFor({required int index, int account = 0}) {
    String address = cwWalletBase!.getTransactionAddress(account, index);

    final newReceivingAddress = Address(
      walletId: walletId,
      derivationIndex: index,
      derivationPath: null,
      value: address,
      publicKey: [],
      type: AddressType.cryptonote,
      subType: AddressSubType.receiving,
    );

    return newReceivingAddress;
  }

  Future<Amount> get _availableBalance async {
    try {
      int runningBalance = 0;
      for (final entry in cwWalletBase!.balance!.entries) {
        runningBalance += entry.value.unlockedBalance;
      }
      return Amount(
        rawValue: BigInt.from(runningBalance),
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    } catch (_) {
      return info.cachedBalance.spendable;
    }
  }

  Future<Amount> get _totalBalance async {
    try {
      final balanceEntries = cwWalletBase?.balance?.entries;
      if (balanceEntries != null) {
        int bal = 0;
        for (var element in balanceEntries) {
          bal = bal + element.value.fullBalance;
        }
        return Amount(
          rawValue: BigInt.from(bal),
          fractionDigits: cryptoCurrency.fractionDigits,
        );
      } else {
        final transactions = cwWalletBase!.transactionHistory!.transactions;
        int transactionBalance = 0;
        for (var tx in transactions!.entries) {
          if (tx.value.direction == TransactionDirection.incoming) {
            transactionBalance += tx.value.amount!;
          } else {
            transactionBalance += -tx.value.amount! - tx.value.fee!;
          }
        }

        return Amount(
          rawValue: BigInt.from(transactionBalance),
          fractionDigits: cryptoCurrency.fractionDigits,
        );
      }
    } catch (_) {
      return info.cachedBalance.total;
    }
  }

  Future<void> _refreshTxDataHelper() async {
    if (_txRefreshLock) return;
    _txRefreshLock = true;

    final syncStatus = cwWalletBase?.syncStatus;

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
    await updateTransactions();
    final count = await mainDB.getTransactions(walletId).count();

    if (count > _txCount) {
      _txCount = count;
      await updateBalance();
      GlobalEventBus.instance.fire(
        UpdatedInBackgroundEvent(
          "New transaction data found in $walletId ${info.name}!",
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

  // TODO: [prio=med/low] is this required?
  // bool _isActive = false;
  // @override
  // void Function(bool)? get onIsActiveWalletChanged => (isActive) async {
  //   if (_isActive == isActive) {
  //     return;
  //   }
  //   _isActive = isActive;
  //
  //   if (isActive) {
  //     _hasCalledExit = false;
  //     String? password;
  //     try {
  //       password =
  //       await keysStorage?.getWalletPassword(walletName: _walletId);
  //     } catch (e, s) {
  //       throw Exception("Password not found $e, $s");
  //     }
  //     walletBase = (await walletService?.openWallet(_walletId, password!))
  //     as WowneroWalletBase?;
  //
  //     walletBase!.onNewBlock = onNewBlock;
  //     walletBase!.onNewTransaction = onNewTransaction;
  //     walletBase!.syncStatusChanged = syncStatusChanged;
  //
  //     if (!(await walletBase!.isConnected())) {
  //       final node = await _getCurrentNode();
  //       final host = Uri.parse(node.host).host;
  //       await walletBase?.connectToNode(
  //         node: Node(
  //           uri: "$host:${node.port}",
  //           type: WalletType.wownero,
  //           trusted: node.trusted ?? false,
  //         ),
  //       );
  //     }
  //     await walletBase?.startSync();
  //     await refresh();
  //     _autoSaveTimer?.cancel();
  //     _autoSaveTimer = Timer.periodic(
  //       const Duration(seconds: 193),
  //           (_) async => await walletBase?.save(),
  //     );
  //   } else {
  //     await exit();
  //   }
  // };
}
