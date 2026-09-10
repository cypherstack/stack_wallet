import 'dart:async';

import 'package:isar_community/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stack_wallet_backup/generate_password.dart';

import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/stack_file_system.dart';
import '../../../wl_gen/interfaces/lib_xelis_interface.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../../models/xelis_transaction.dart';
import '../intermediate/lib_xelis_wallet.dart';
import '../intermediate/xelis_operation_coordinator.dart';
import '../wallet.dart';

class XelisWallet extends LibXelisWallet<Xelis> {
  XelisWallet(CryptoCurrencyNetwork network, {super.native})
    : super(Xelis(network));

  /// Set only by Wallet.create for an explicit new-wallet request. Loading an
  /// existing database record must never silently generate another identity.
  bool allowNewWallet = false;
  Future<void>? _initializing;
  final _sendMutex = Mutex();
  final _balanceMutex = Mutex();
  final _historyMutex = Mutex();
  final _rescanMutex = Mutex();
  late final _operationCoordinator = XelisOperationCoordinator(refreshMutex);
  XelisPreparedTransaction? _prepared;
  OpaqueXelisWallet? _preparedHandle;
  int? _preparedGeneration;
  String? _reviewedDestination;
  int _prepareRequest = 0;

  @override
  int get isarTransactionVersion => 2;

  Amount _amount(BigInt raw) =>
      Amount(rawValue: raw, fractionDigits: cryptoCurrency.fractionDigits);

  @override
  Future<void> init({bool? isRestore}) async {
    if (exitInProgress) throw StateError('Xelis session is closing');
    final previous = _initializing;
    if (previous != null) return previous;
    if (wallet != null) return super.init();
    final attempt = _initialize(isRestore: isRestore == true);
    _initializing = attempt;
    try {
      await attempt;
    } finally {
      if (identical(_initializing, attempt)) _initializing = null;
    }
  }

  Future<void> _initialize({required bool isRestore}) async {
    final generation = sessionGeneration;
    final directory = await StackFileSystem.applicationXelisDirectory();
    final exists = await LibXelisWallet.checkWalletExists(walletId);
    final seed = await secureStorageInterface.read(
      key: Wallet.mnemonicKey(walletId: walletId),
    );
    final passwordKey = Wallet.mnemonicPassphraseKey(walletId: walletId);
    var password = await secureStorageInterface.read(key: passwordKey);
    final tablesPath = await getPrecomputedTablesPath();
    final tables = await getTableState();
    if (exitInProgress || generation != sessionGeneration) {
      throw StateError('Xelis session was closed');
    }
    OpaqueXelisWallet? opened;
    try {
      if (exists) {
        if (password == null) {
          throw StateError('Xelis wallet password is missing');
        }
        opened = await xelis.openXelisWallet(
          walletId,
          name: walletId,
          directory: directory.path,
          password: password,
          network: cryptoCurrency.network,
          precomputedTablesPath: tablesPath,
          stack_l1Low: tables.currentSize.isLow,
        );
      } else if (seed != null && seed.trim().isNotEmpty) {
        final normalizedSeed = seed.trim().split(RegExp(r'\s+')).join(' ');
        invalidSeedLengthCheck(normalizedSeed.split(' ').length);
        password ??= generatePassword();
        await secureStorageInterface.write(key: passwordKey, value: password);
        opened = await xelis.createXelisWallet(
          walletId,
          name: walletId,
          directory: directory.path,
          password: password,
          seed: normalizedSeed,
          network: cryptoCurrency.network,
          precomputedTablesPath: tablesPath,
          stack_l1Low: tables.currentSize.isLow,
        );
      } else {
        if (isRestore || !allowNewWallet) {
          throw StateError('Xelis wallet data and recovery seed are missing');
        }
        password ??= generatePassword();
        await secureStorageInterface.write(key: passwordKey, value: password);
        opened = await xelis.createXelisWallet(
          walletId,
          name: walletId,
          directory: directory.path,
          password: password,
          network: cryptoCurrency.network,
          precomputedTablesPath: tablesPath,
          stack_l1Low: tables.currentSize.isLow,
        );
      }
      if (exitInProgress || generation != sessionGeneration) {
        throw StateError('Xelis session was closed');
      }
      wallet = opened;
      final address = xelis.getAddress(opened);
      final previous = await getCurrentReceivingAddress();
      if (!isCurrentSession(opened, generation)) {
        throw StateError('Xelis session was closed');
      }
      final cachedAddress = info.cachedReceivingAddress;
      if ((previous != null && previous.value != address) ||
          (cachedAddress.isNotEmpty && cachedAddress != address)) {
        throw StateError(
          'Xelis wallet address does not match the saved wallet',
        );
      }
      if (seed == null || seed.trim().isEmpty) {
        // Also repairs an interrupted creation: native storage may have been
        // committed before Stack saved the recovery words.
        final nativeSeed = await xelis.getSeed(opened);
        if (!isCurrentSession(opened, generation)) {
          throw StateError('Xelis session was closed');
        }
        await secureStorageInterface.write(
          key: Wallet.mnemonicKey(walletId: walletId),
          value: nativeSeed.trim(),
        );
      }
      await mainDB.updateOrPutAddresses([
        previous ??
            Address(
              walletId: walletId,
              derivationIndex: 0,
              derivationPath: null,
              value: address,
              publicKey: [],
              type: AddressType.xelis,
              subType: AddressSubType.receiving,
            ),
      ]);
      if (!isCurrentSession(opened, generation)) {
        throw StateError('Xelis session was closed');
      }
      await info.updateReceivingAddress(newAddress: address, isar: mainDB.isar);
      if (!isCurrentSession(opened, generation)) {
        throw StateError('Xelis session was closed');
      }
      allowNewWallet = false;
      await super.init();
      if (tables.currentSize != tables.desiredSize) {
        unawaited(
          updateTablesToDesiredSize().catchError((
            Object error,
            StackTrace stack,
          ) {
            Logging.instance.e(
              'Xelis table update failed',
              error: error,
              stackTrace: stack,
            );
          }),
        );
      }
    } catch (error, stack) {
      if (identical(wallet, opened)) wallet = null;
      if (opened != null) {
        try {
          await xelis.closeWallet(opened);
        } catch (cleanupError, cleanupStack) {
          Logging.instance.e(
            'Xelis initialization cleanup failed',
            error: cleanupError,
            stackTrace: cleanupStack,
          );
        }
      }
      Error.throwWithStackTrace(error, stack);
    }
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    if (!isRescan) return open();
    checkInitialized();
    final handle = wallet!;
    final generation = sessionGeneration;
    await _rescanMutex.protect(() async {
      if (!isCurrentSession(handle, generation)) return;
      final daemon = await xelis.getDaemonInfo(handle);
      if (!isCurrentSession(handle, generation)) return;
      pruningHeight = daemon.prunedTopoheight ?? BigInt.zero;
      _status(WalletSyncStatus.syncing);
      await xelis.rescan(handle, topoheight: pruningHeight);
    });
  }

  void _status(WalletSyncStatus status) => GlobalEventBus.instance.fire(
    WalletSyncStatusChangedEvent(status, walletId, info.coin),
  );

  @override
  Future<bool> pingCheck() async {
    final handle = wallet;
    if (handle == null || exitInProgress) return false;
    try {
      await xelis.getDaemonInfo(handle);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> updateBalance({
    BigInt? newBalance,
  }) => _balanceMutex.protect(() async {
    final handle = wallet;
    final generation = sessionGeneration;
    if (handle == null || exitInProgress) return;
    // A read includes a genuine zero and propagates storage errors. Never turn
    // an error into zero or keep the old balance merely because it disappeared.
    final raw = await xelis.getXelisBalanceRaw(handle);
    final history = await xelis.allHistory(handle);
    if (!isCurrentSession(handle, generation)) return;
    final address = xelis.getAddress(handle);
    final reserved = history
        .where((entry) => entry.topoheight == null)
        .map((entry) => _project(entry, address))
        .whereType<TransactionV2>()
        .expand((entry) => entry.inputs)
        .where((input) => input.walletOwns)
        .fold(BigInt.zero, (sum, input) => sum + input.value);
    // XWF exposes confirmed balances. Reserve the full pending debit, including
    // fees and self transfers, until confirmation; native preparation remains
    // authoritative for what can actually be spent.
    final blocked = reserved > raw ? raw : reserved;
    await info.updateBalance(
      newBalance: Balance(
        total: _amount(raw),
        spendable: _amount(raw - blocked),
        blockedTotal: _amount(blocked),
        pendingSpendable: _amount(BigInt.zero),
      ),
      isar: mainDB.isar,
    );
  });

  @override
  Future<void> updateChainHeight({int? topoheight}) async {
    final handle = wallet;
    final generation = sessionGeneration;
    if (handle == null || exitInProgress) return;
    final daemon = await xelis.getDaemonInfo(handle);
    if (!isCurrentSession(handle, generation)) return;
    pruningHeight = daemon.prunedTopoheight ?? BigInt.zero;
    await info.updateCachedChainHeight(
      newHeight: topoheight ?? xelisStorageInt(daemon.topoheight),
      isar: mainDB.isar,
    );
  }

  @override
  Future<void> updateNode() => connect();

  @override
  Future<List<String>> updateTransactions({
    bool isRescan = false,
    List<TransactionEntryWrapper>? objTransactions,
    int? topoheight,
  }) => _historyMutex.protect(() async {
    final handle = wallet;
    final generation = sessionGeneration;
    if (handle == null || exitInProgress) return [];
    final entries = objTransactions ?? await xelis.allHistory(handle);
    if (!isCurrentSession(handle, generation)) return [];
    final address = xelis.getAddress(handle);
    final transactions = entries
        .map((tx) => _project(tx, address))
        .whereType<TransactionV2>()
        .toList();
    await mainDB.isar.writeTxn(() async {
      if (!isCurrentSession(handle, generation)) return;
      final stored = await mainDB.isar.transactionV2s
          .where()
          .walletIdEqualTo(walletId)
          .findAll();
      final byHash = {for (final tx in stored) tx.txid: tx};
      for (final tx in transactions) {
        final existing = byHash.remove(tx.txid);
        if (existing != null) tx.id = existing.id;
      }
      await mainDB.isar.transactionV2s.putAll(transactions);
      if (objTransactions == null || isRescan) {
        // Reconcile disappeared pending entries and reorganized confirmations.
        // Keep addresses and user notes; their lifetime is not chain-dependent.
        await mainDB.isar.transactionV2s.deleteAll(
          byHash.values.map((tx) => tx.id).toList(),
        );
      }
    });
    return transactions.map((tx) => tx.txid).toList();
  });

  TransactionV2? _project(TransactionEntryWrapper tx, String ownAddress) =>
      projectXelisTransaction(
        tx: tx,
        ownAddress: ownAddress,
        walletId: walletId,
        xelisAsset: xelis.xelisAsset,
        fractionDigits: cryptoCurrency.fractionDigits,
      );
  @override
  Future<bool> updateUTXOs() async => false;
  @override
  Future<void> checkSaveInitialReceivingAddress() async {}
  @override
  FilterOperation? get changeAddressFilterOperation => null;
  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  @override
  Future<FeeObject> get fees async => FeeObject(
    numberOfBlocksFast: 1,
    numberOfBlocksAverage: 1,
    numberOfBlocksSlow: 1,
    fast: BigInt.one,
    medium: BigInt.one,
    slow: BigInt.one,
  );

  @override
  Future<Amount> estimateFeeFor(
    Amount amount,
    BigInt feeRate, {
    double? feeMultiplier,
    List<TxRecipient> recipients = const [],
    String? assetId,
  }) async {
    checkInitialized();
    if (assetId != null && assetId != xelis.xelisAsset) {
      throw UnsupportedError('Stack sends XEL only');
    }
    if (recipients.length != 1) {
      throw StateError('Enter a Xelis recipient to estimate fees');
    }
    final fee = await xelis.estimateFees(
      wallet!,
      transfers: [
        XelisTransfer(
          destination: recipients.single.address,
          amountAtomic: amount.raw,
          asset: xelis.xelisAsset,
        ),
      ],
    );
    return _amount(fee);
  }

  @override
  Future<TxData> prepareSend({required TxData txData, String? assetId}) async {
    final request = ++_prepareRequest;
    checkInitialized();
    final handle = wallet!;
    final generation = sessionGeneration;
    return _sendMutex.protect(() async {
      bool current() =>
          request == _prepareRequest && isCurrentSession(handle, generation);
      if (!current()) throw StateError('Xelis preparation was superseded');
      final previous = _prepared;
      _prepared = null;
      if (previous != null) {
        await xelis.discardPreparedTransaction(handle, transaction: previous);
      }
      if (!current()) throw StateError('Xelis session was changed');
      if (assetId != null && assetId != xelis.xelisAsset) {
        throw UnsupportedError('Stack sends XEL only');
      }
      final recipients = txData.recipients;
      if (recipients == null || recipients.length != 1) {
        throw ArgumentError('Xelis requires one recipient');
      }
      final recipient = recipients.single;
      if (!xelis.isAddressValid(
        address: recipient.address,
        network: cryptoCurrency.network,
      )) {
        throw ArgumentError('Invalid Xelis destination');
      }
      if (!txData.xelisSendAll && recipient.amount.raw <= BigInt.zero) {
        throw ArgumentError('Xelis amount must be positive');
      }
      final prepared = txData.xelisSendAll
          ? await xelis.prepareTransferAll(
              handle,
              destination: recipient.address,
            )
          : await xelis.prepareTransfers(
              handle,
              transfers: [
                XelisTransfer(
                  destination: recipient.address,
                  amountAtomic: recipient.amount.raw,
                  asset: xelis.xelisAsset,
                ),
              ],
            );
      if (!current()) {
        await xelis.discardPreparedTransaction(handle, transaction: prepared);
        throw StateError('Xelis preparation was superseded');
      }
      _prepared = prepared;
      _preparedHandle = handle;
      _preparedGeneration = generation;
      _reviewedDestination = recipient.address;
      return txData.copyWith(
        xelisPreparedTransaction: prepared,
        fee: _amount(prepared.feeAtomic),
        recipients: [
          TxRecipient(
            address: recipient.address,
            amount: _amount(prepared.transfers.single.amountAtomic),
            isChange: false,
            addressType: AddressType.xelis,
          ),
        ],
      );
    });
  }

  @override
  Future<void> cancelSend({required TxData txData}) async {
    final prepared = txData.xelisPreparedTransaction;
    if (prepared == null || !identical(prepared, _prepared)) return;
    ++_prepareRequest;
    await _sendMutex.protect(() async {
      if (!identical(prepared, _prepared)) return;
      _prepared = null;
      final handle = wallet;
      if (handle != null && !exitInProgress) {
        await xelis.discardPreparedTransaction(handle, transaction: prepared);
      }
    });
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    final handle = wallet;
    final generation = sessionGeneration;
    final prepared = txData.xelisPreparedTransaction;
    return _sendMutex.protect(() async {
      if (handle == null ||
          prepared == null ||
          !isCurrentSession(handle, generation) ||
          !identical(handle, _preparedHandle) ||
          generation != _preparedGeneration ||
          !identical(_prepared, prepared)) {
        throw StateError('Review a new Xelis transaction before sending');
      }
      final recipients = txData.recipients;
      if (recipients == null ||
          recipients.length != 1 ||
          recipients.single.address != _reviewedDestination ||
          recipients.single.amount.raw !=
              prepared.transfers.single.amountAtomic ||
          txData.fee?.raw != prepared.feeAtomic) {
        throw StateError('Xelis transaction differs from its reviewed values');
      }
      final outcome = await xelis.broadcastTransaction(
        handle,
        transaction: prepared,
      );
      if (outcome.disposition != XelisBroadcastDisposition.retryable) {
        _prepared = null;
      }
      if (!outcome.wasSubmitted) {
        throw outcome.failure ?? StateError('Xelis submission failed');
      }
      if (outcome.failure != null) {
        Logging.instance.w(
          'Xelis submitted; reconciliation required',
          error: outcome.failure,
        );
      }
      if (isCurrentSession(handle, generation)) unawaited(refresh());
      return txData.copyWith(txid: prepared.hash);
    });
  }

  @override
  Future<void> drainSessionOperations() async {
    ++_prepareRequest;
    // init owns cleanup of a partially opened handle. Do not close it twice.
    try {
      await _initializing;
    } catch (_) {
      // The caller of init receives the original failure.
    }
    await _sendMutex.protect(() async {
      _prepared = null;
      _reviewedDestination = null;
    });
    await _balanceMutex.protect(() async {});
    await _historyMutex.protect(() async {});
    await _rescanMutex.protect(() async {});
  }

  @override
  Future<void> handleEvent(
    Event event, {
    required bool Function() isCurrent,
  }) async {
    if (!isCurrent()) return;
    switch (event) {
      case Online():
        _status(WalletSyncStatus.syncing);
      case Offline():
        _status(WalletSyncStatus.unableToSync);
        scheduleReconnect();
      case NewTopoheight():
        // Ordinary blocks do not emit HistorySynced. Read the daemon height
        // after each completed block sync so confirmations keep progressing.
        await updateChainHeight();
      case HistorySynced():
        await refresh();
      case Rescan():
        _status(WalletSyncStatus.syncing);
        await refreshMutex.protect(() async {
          if (!isCurrent()) return;
          await updateTransactions(isRescan: true);
        });
      case NewTransaction():
        await updateTransactions();
        if (isCurrent()) await updateBalance();
      case BalanceChanged(:final asset):
        if (asset == xelis.xelisAsset) await updateBalance();
      case NewAsset() || XelisStateInvalidated():
        await refresh();
      case XelisSyncIssue(:final failure):
        Logging.instance.w('Xelis sync issue', error: failure);
      case XelisChannelClosed(:final failure, :final isRuntime):
        Logging.instance.w('Xelis event channel closed', error: failure);
        _status(WalletSyncStatus.unableToSync);
        recoverEventChannel(isRuntime: isRuntime);
    }
  }

  @override
  Future<void> handleNewTopoHeight(BigInt height) => updateChainHeight();
  @override
  Future<void> handleNewTransaction(TransactionEntryWrapper tx) async {
    await updateTransactions(objTransactions: [tx]);
  }

  @override
  Future<void> handleBalanceChanged(BalanceChanged event) => updateBalance();

  @override
  Future<void> refresh({int? topoheight}) =>
      _operationCoordinator.refresh(() async {
        final handle = wallet;
        final generation = sessionGeneration;
        if (handle == null || exitInProgress) return;
        try {
          await updateTransactions();
          if (!isCurrentSession(handle, generation)) return;
          await updateBalance();
          if (!isCurrentSession(handle, generation)) return;
          if (await xelis.isOnline(handle)) {
            if (!isCurrentSession(handle, generation)) return;
            await updateChainHeight(topoheight: topoheight);
            if (!isCurrentSession(handle, generation)) return;
            final syncing = await xelis.isSyncing(handle);
            if (isCurrentSession(handle, generation)) {
              _status(
                syncing ? WalletSyncStatus.syncing : WalletSyncStatus.synced,
              );
            }
          }
        } catch (error, stack) {
          if (isCurrentSession(handle, generation)) {
            Logging.instance.e(
              'Xelis refresh failed',
              error: error,
              stackTrace: stack,
            );
            _status(WalletSyncStatus.unableToSync);
          }
        }
      });
}
