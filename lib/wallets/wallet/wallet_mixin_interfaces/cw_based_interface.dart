import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/utxo.dart' as cw;
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_libmonero/core/key_service.dart';
import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';

import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/utxo.dart';
import '../../../models/keys/cw_key_data.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../services/event_bus/events/global/blocks_remaining_event.dart';
import '../../../services/event_bus/events/global/refresh_percent_changed_event.dart';
import '../../../services/event_bus/events/global/updated_in_background_event.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/stack_file_system.dart';
import '../../crypto_currency/intermediate/cryptonote_currency.dart';
import '../../isar/models/wallet_info.dart';
import '../intermediate/cryptonote_wallet.dart';
import 'multi_address_interface.dart';

mixin CwBasedInterface<T extends CryptonoteCurrency, U extends WalletBase,
        V extends WalletService> on CryptonoteWallet<T>
    implements MultiAddressInterface<T> {
  final prepareSendMutex = Mutex();
  final estimateFeeMutex = Mutex();

  KeyService? _cwKeysStorageCached;
  KeyService get cwKeysStorage =>
      _cwKeysStorageCached ??= KeyService(secureStorageInterface);

  bool _txRefreshLock = false;
  int _lastCheckedHeight = -1;
  int _txCount = 0;
  int currentKnownChainHeight = 0;
  double highestPercentCached = 0;

  Timer? autoSaveTimer;
  Future<String> pathForWalletDir({
    required String name,
    required WalletType type,
  }) async {
    final Directory root = await StackFileSystem.applicationRootDirectory();

    final prefix = walletTypeToString(type).toLowerCase();
    final walletsDir = Directory('${root.path}/wallets');
    final walletDire = Directory('${walletsDir.path}/$prefix/$name');

    if (!walletDire.existsSync()) {
      walletDire.createSync(recursive: true);
    }

    return walletDire.path;
  }

  Future<String> pathForWallet({
    required String name,
    required WalletType type,
  }) async =>
      await pathForWalletDir(name: name, type: type)
          .then((path) => '$path/$name');

  void onNewBlock({required int height, required int blocksLeft}) {
    currentKnownChainHeight = height;
    updateChainHeight();
    _refreshTxDataHelper();
  }

  final _utxosUpdateLock = Mutex();
  Future<void> onUTXOsCHanged(List<UTXO> utxos) async {
    await _utxosUpdateLock.protect(() async {
      final cwUtxos = cwWalletBase?.utxos ?? [];

      bool changed = false;

      for (final cw in cwUtxos) {
        final match = utxos.where(
          (e) =>
              e.keyImage != null &&
              e.keyImage!.isNotEmpty &&
              e.keyImage == cw.keyImage,
        );

        if (match.isNotEmpty) {
          final u = match.first;

          if (u.isBlocked) {
            if (!cw.isFrozen) {
              await cwWalletBase?.freeze(cw.keyImage);
              changed = true;
            }
          } else {
            if (cw.isFrozen) {
              await cwWalletBase?.thaw(cw.keyImage);
              changed = true;
            }
          }
        }
      }

      if (changed) {
        await cwWalletBase?.updateUTXOs();
      }
    });
  }

  void onNewTransaction() {
    // TODO: [prio=low] get rid of UpdatedInBackgroundEvent and move to
    // adding the v2 tx to the db which would update ui automagically since the
    // db is watched by the ui
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
      if (syncStatus.progress() == 1 && refreshMutex.isLocked) {
        refreshMutex.release();
      }

      WalletSyncStatus? status;
      xmrAndWowSyncSpecificFunctionThatShouldBeGottenRidOfInTheFuture(true);

      if (syncStatus is SyncingSyncStatus) {
        final int blocksLeft = syncStatus.blocksLeft;

        // ensure at least 1 to prevent math errors
        final int height = max(1, syncStatus.height);

        final nodeHeight = height + blocksLeft;
        currentKnownChainHeight = nodeHeight;

        final percent = height / nodeHeight;

        final highest = max(highestPercentCached, percent);

        // update cached
        if (highestPercentCached < percent) {
          highestPercentCached = percent;
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
            highestPercentCached,
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

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    // this doesn't work without opening the wallet first which takes a while
  }

  // ============ Interface ====================================================

  U? get cwWalletBase;
  V? get cwWalletService;

  Future<Amount> get availableBalance;
  Future<Amount> get totalBalance;

  Future<void> open();

  Address addressFor({required int index, int account = 0});

  Future<CWKeyData?> getKeys();

  // ============ Private ======================================================
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

  // ============ Overrides ====================================================

  @override
  FilterOperation? get changeAddressFilterOperation => null;

  @override
  FilterOperation? get receivingAddressFilterOperation => null;

  @override
  Future<bool> updateUTXOs() async {
    await cwWalletBase?.updateUTXOs();

    final List<UTXO> outputArray = [];
    for (final rawUTXO in (cwWalletBase?.utxos ?? <cw.UTXO>[])) {
      if (!rawUTXO.spent) {
        final current = await mainDB.isar.utxos
            .where()
            .walletIdEqualTo(walletId)
            .filter()
            .voutEqualTo(rawUTXO.vout)
            .and()
            .txidEqualTo(rawUTXO.hash)
            .findFirst();
        final tx = await mainDB.isar.transactions
            .where()
            .walletIdEqualTo(walletId)
            .filter()
            .txidEqualTo(rawUTXO.hash)
            .findFirst();

        final otherDataMap = {
          "keyImage": rawUTXO.keyImage,
          "spent": rawUTXO.spent,
        };

        final utxo = UTXO(
          address: rawUTXO.address,
          walletId: walletId,
          txid: rawUTXO.hash,
          vout: rawUTXO.vout,
          value: rawUTXO.value,
          name: current?.name ?? "",
          isBlocked: current?.isBlocked ?? rawUTXO.isFrozen,
          blockedReason: current?.blockedReason ?? "",
          isCoinbase: rawUTXO.coinbase,
          blockHash: "",
          blockHeight:
              tx?.height ?? (rawUTXO.height > 0 ? rawUTXO.height : null),
          blockTime: tx?.timestamp,
          otherData: jsonEncode(otherDataMap),
        );

        outputArray.add(utxo);
      }
    }

    await mainDB.updateUTXOs(walletId, outputArray);

    return true;
  }

  @override
  Future<void> updateBalance({bool shouldUpdateUtxos = true}) async {
    if (shouldUpdateUtxos) {
      await updateUTXOs();
    }

    final total = await totalBalance;
    final available = await availableBalance;

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

    if (info.otherData[WalletInfoKeys.reuseAddress] != true) {
      await checkReceivingAddressForTransactions();
    }

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
  Future<void> exit() async {
    autoSaveTimer?.cancel();
    await cwWalletBase?.save();
    cwWalletBase?.close();
  }

  @override
  Future<void> generateNewReceivingAddress() async {
    try {
      final currentReceiving = await getCurrentReceivingAddress();

      final newReceivingIndex =
          currentReceiving == null ? 0 : currentReceiving.derivationIndex + 1;

      final newReceivingAddress = addressFor(index: newReceivingIndex);

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
    if (info.otherData[WalletInfoKeys.reuseAddress] == true) {
      try {
        throw Exception();
      } catch (_, s) {
        Logging.instance.log(
          "checkReceivingAddressForTransactions called but reuse address flag set: $s",
          level: LogLevel.Error,
        );
      }
    }

    try {
      int highestIndex = -1;
      final entries = cwWalletBase?.transactionHistory?.transactions?.entries;
      if (entries != null) {
        for (final element in entries) {
          if (element.value.direction == TransactionDirection.incoming) {
            final int curAddressIndex =
                element.value.additionalInfo!['addressIndex'] as int;
            if (curAddressIndex > highestIndex) {
              highestIndex = curAddressIndex;
            }
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
        final newReceivingAddress = addressFor(index: newReceivingIndex);

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
        if (info.otherData[WalletInfoKeys.reuseAddress] != true) {
          // keep checking until address with no tx history is set as current
          await checkReceivingAddressForTransactions();
        }
      }
    } on SocketException catch (se, s) {
      Logging.instance.log(
        "SocketException caught in _checkReceivingAddressForTransactions(): $se\n$s",
        level: LogLevel.Error,
      );
      return;
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from _checkReceivingAddressForTransactions(): $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
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
  Future<void> updateChainHeight() async {
    await info.updateCachedChainHeight(
      newHeight: currentKnownChainHeight,
      isar: mainDB.isar,
    );
  }

  @override
  Future<void> checkChangeAddressForTransactions() async {
    // do nothing
  }

  @override
  Future<void> generateNewChangeAddress() async {
    // do nothing
  }
}
