import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:compat/compat.dart' as lib_monero_compat;
import 'package:cs_monero/cs_monero.dart' as lib_monero;
import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stack_wallet_backup/generate_password.dart';

import '../../../db/hive/db.dart';
import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/utxo.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/keys/cw_key_data.dart';
import '../../../models/keys/view_only_wallet_data.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../services/event_bus/events/global/blocks_remaining_event.dart';
import '../../../services/event_bus/events/global/refresh_percent_changed_event.dart';
import '../../../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../../../services/event_bus/events/global/tor_status_changed_event.dart';
import '../../../services/event_bus/events/global/updated_in_background_event.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../services/tor_service.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/stack_file_system.dart';
import '../../crypto_currency/intermediate/cryptonote_currency.dart';
import '../../isar/models/wallet_info.dart';
import '../../models/tx_data.dart';
import '../wallet.dart';
import '../wallet_mixin_interfaces/multi_address_interface.dart';
import '../wallet_mixin_interfaces/view_only_option_interface.dart';
import 'cryptonote_wallet.dart';

abstract class LibMoneroWallet<T extends CryptonoteCurrency>
    extends CryptonoteWallet<T>
    with ViewOnlyOptionInterface<T>
    implements MultiAddressInterface<T> {
  @override
  int get isarTransactionVersion => 2;

  LibMoneroWallet(super.currency, this.compatType) {
    final bus = GlobalEventBus.instance;

    // Listen for tor status changes.
    _torStatusListener = bus.on<TorConnectionStatusChangedEvent>().listen(
      (event) async {
        switch (event.newStatus) {
          case TorConnectionStatus.connecting:
            if (!_torConnectingLock.isLocked) {
              await _torConnectingLock.acquire();
            }
            _requireMutex = true;
            break;

          case TorConnectionStatus.connected:
          case TorConnectionStatus.disconnected:
            if (_torConnectingLock.isLocked) {
              _torConnectingLock.release();
            }
            _requireMutex = false;
            break;
        }
      },
    );

    // Listen for tor preference changes.
    _torPreferenceListener = bus.on<TorPreferenceChangedEvent>().listen(
      (event) async {
        await updateNode();
      },
    );

    // Potentially dangerous hack. See comments in _startInit()
    _startInit();
  }
  // cw based wallet listener to handle synchronization of utxo frozen states
  late final StreamSubscription<List<UTXO>> _streamSub;
  Future<void> _startInit() async {
    // Delay required as `mainDB` is not initialized in constructor.
    // This is a hack and could lead to a race condition.
    Future.delayed(const Duration(seconds: 2), () {
      _streamSub = mainDB.isar.utxos
          .where()
          .walletIdEqualTo(walletId)
          .watch(fireImmediately: true)
          .listen((utxos) async {
        try {
          await onUTXOsChanged(utxos);
          await updateBalance(shouldUpdateUtxos: false);
        } catch (e, s) {
          lib_monero.Logging.log?.i(
            "_startInit",
            error: e,
            stackTrace: s,
          );
        }
      });
    });
  }

  final lib_monero_compat.WalletType compatType;
  lib_monero.Wallet? libMoneroWallet;

  lib_monero_compat.SyncStatus? get syncStatus => _syncStatus;
  lib_monero_compat.SyncStatus? _syncStatus;
  int _syncedCount = 0;
  void _setSyncStatus(lib_monero_compat.SyncStatus status) {
    if (status is lib_monero_compat.SyncedSyncStatus) {
      if (_syncStatus is lib_monero_compat.SyncedSyncStatus) {
        _syncedCount++;
      }
    } else {
      _syncedCount = 0;
    }

    if (_syncedCount < 3) {
      _syncStatus = status;
      syncStatusChanged();
    }
  }

  final prepareSendMutex = Mutex();
  final estimateFeeMutex = Mutex();

  bool _txRefreshLock = false;
  int _lastCheckedHeight = -1;
  int _txCount = 0;
  int currentKnownChainHeight = 0;
  double highestPercentCached = 0;

  void loadWallet({required String path, required String password});

  Future<lib_monero.Wallet> getCreatedWallet({
    required String path,
    required String password,
  });

  Future<lib_monero.Wallet> getRestoredWallet({
    required String path,
    required String password,
    required String mnemonic,
    int height = 0,
  });

  Future<lib_monero.Wallet> getRestoredFromViewKeyWallet({
    required String path,
    required String password,
    required String address,
    required String privateViewKey,
    int height = 0,
  });

  void invalidSeedLengthCheck(int length);

  bool walletExists(String path);

  void _setListener() {
    if (libMoneroWallet != null && libMoneroWallet!.getListeners().isEmpty) {
      libMoneroWallet?.addListener(
        lib_monero.WalletListener(
          onSyncingUpdate: onSyncingUpdate,
          onNewBlock: onNewBlock,
          onBalancesChanged: onBalancesChanged,
          onError: (e, s) {
            Logging.instance.log("$e\n$s", level: LogLevel.Warning);
          },
        ),
      );
    }
  }

  Future<void> open() async {
    bool wasNull = false;

    if (libMoneroWallet == null) {
      wasNull = true;
      // libMoneroWalletT?.close();
      final path = await pathForWallet(
        name: walletId,
        type: compatType,
      );

      final String password;
      try {
        password = (await secureStorageInterface.read(
          key: lib_monero_compat.libMoneroWalletPasswordKey(walletId),
        ))!;
      } catch (e, s) {
        throw Exception("Password not found $e, $s");
      }

      loadWallet(path: path, password: password);

      _setListener();

      await updateNode();
    }

    Address? currentAddress = await getCurrentReceivingAddress();
    if (currentAddress == null) {
      currentAddress = addressFor(index: 0);
      await mainDB.updateOrPutAddresses([currentAddress]);
    }
    if (info.cachedReceivingAddress != currentAddress.value) {
      await info.updateReceivingAddress(
        newAddress: currentAddress.value,
        isar: mainDB.isar,
      );
    }

    if (wasNull) {
      try {
        _setSyncStatus(lib_monero_compat.ConnectingSyncStatus());
        libMoneroWallet?.startSyncing();
      } catch (_) {
        _setSyncStatus(lib_monero_compat.FailedSyncStatus());
        // TODO log
      }
    }
    _setListener();
    libMoneroWallet?.startListeners();
    libMoneroWallet?.startAutoSaving();

    unawaited(refresh());
  }

  @Deprecated("Only used in the case of older wallets")
  lib_monero_compat.WalletInfo? getLibMoneroWalletInfo(
    String walletId,
  ) {
    try {
      return DB.instance.moneroWalletInfoBox.values.firstWhere(
        (info) => info.id == lib_monero_compat.hiveIdFor(walletId, compatType),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save() async {
    if (!Platform.isWindows) {
      final appRoot = await StackFileSystem.applicationRootDirectory();
      await lib_monero_compat.backupWalletFiles(
        name: walletId,
        type: compatType,
        appRoot: appRoot,
      );
    }
    await libMoneroWallet!.save();
  }

  Address addressFor({required int index, int account = 0}) {
    final address = libMoneroWallet!.getAddress(
      accountIndex: account,
      addressIndex: index,
    );

    final newReceivingAddress = Address(
      walletId: walletId,
      derivationIndex: index,
      derivationPath: null,
      value: address.value,
      publicKey: [],
      type: AddressType.cryptonote,
      subType: AddressSubType.receiving,
    );

    return newReceivingAddress;
  }

  Future<CWKeyData?> getKeys() async {
    final base = libMoneroWallet;

    final oldInfo = getLibMoneroWalletInfo(
      walletId,
    );
    if (base == null || (oldInfo != null && oldInfo.name != walletId)) {
      return null;
    }

    return CWKeyData(
      walletId: walletId,
      publicViewKey: base.getPublicViewKey(),
      privateViewKey: base.getPrivateViewKey(),
      publicSpendKey: base.getPublicSpendKey(),
      privateSpendKey: base.getPrivateSpendKey(),
    );
  }

  Future<(String, String)>
      hackToCreateNewViewOnlyWalletDataFromNewlyCreatedWalletThisFunctionShouldNotBeCalledUnlessYouKnowWhatYouAreDoing() async {
    final path = await pathForWallet(name: walletId, type: compatType);
    final String password;
    try {
      password = (await secureStorageInterface.read(
        key: lib_monero_compat.libMoneroWalletPasswordKey(walletId),
      ))!;
    } catch (e, s) {
      throw Exception("Password not found $e, $s");
    }
    loadWallet(path: path, password: password);
    final wallet = libMoneroWallet!;
    return (wallet.getAddress().value, wallet.getPrivateViewKey());
  }

  @override
  Future<void> init({bool? isRestore}) async {
    final path = await pathForWallet(
      name: walletId,
      type: compatType,
    );
    if (!(walletExists(path)) && isRestore != true) {
      try {
        final password = generatePassword();
        await secureStorageInterface.write(
          key: lib_monero_compat.libMoneroWalletPasswordKey(walletId),
          value: password,
        );
        final wallet = await getCreatedWallet(path: path, password: password);

        final height = wallet.getRefreshFromBlockHeight();

        await info.updateRestoreHeight(
          newRestoreHeight: height,
          isar: mainDB.isar,
        );

        // special case for xmr/wow. Normally mnemonic + passphrase is saved
        // before wallet.init() is called
        await secureStorageInterface.write(
          key: Wallet.mnemonicKey(walletId: walletId),
          value: wallet.getSeed().trim(),
        );
        await secureStorageInterface.write(
          key: Wallet.mnemonicPassphraseKey(walletId: walletId),
          value: "",
        );
      } catch (e, s) {
        Logging.instance.log("$e\n$s", level: LogLevel.Fatal);
      }
      await updateNode();
    }

    return super.init();
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    if (isRescan) {
      await refreshMutex.protect(() async {
        // clear blockchain info
        await mainDB.deleteWalletBlockchainData(walletId);

        highestPercentCached = 0;
        unawaited(libMoneroWallet?.rescanBlockchain());
        libMoneroWallet?.startSyncing();
        // unawaited(save());
      });
      unawaited(refresh());
      return;
    }

    if (isViewOnly) {
      await recoverViewOnly();
      return;
    }

    await refreshMutex.protect(() async {
      final mnemonic = await getMnemonic();
      final seedLength = mnemonic.trim().split(" ").length;

      invalidSeedLengthCheck(seedLength);

      try {
        final height = max(info.restoreHeight, 0);

        await info.updateRestoreHeight(
          newRestoreHeight: height,
          isar: mainDB.isar,
        );

        final String name = walletId;

        final path = await pathForWallet(
          name: name,
          type: compatType,
        );

        try {
          final password = generatePassword();
          await secureStorageInterface.write(
            key: lib_monero_compat.libMoneroWalletPasswordKey(walletId),
            value: password,
          );
          final wallet = await getRestoredWallet(
            path: path,
            password: password,
            mnemonic: mnemonic,
            height: height,
          );

          if (libMoneroWallet != null) {
            await exit();
          }

          libMoneroWallet = wallet;

          _setListener();

          final newReceivingAddress = await getCurrentReceivingAddress() ??
              Address(
                walletId: walletId,
                derivationIndex: 0,
                derivationPath: null,
                value: wallet.getAddress().value,
                publicKey: [],
                type: AddressType.cryptonote,
                subType: AddressSubType.receiving,
              );

          await mainDB.updateOrPutAddresses([newReceivingAddress]);
          await info.updateReceivingAddress(
            newAddress: newReceivingAddress.value,
            isar: mainDB.isar,
          );
        } catch (e, s) {
          Logging.instance.log("$e\n$s", level: LogLevel.Fatal);
        }
        await updateNode();
        _setListener();

        // libMoneroWallet?.setRecoveringFromSeed(isRecovery: true);
        unawaited(libMoneroWallet?.rescanBlockchain());
        libMoneroWallet?.startSyncing();

        // await save();
        libMoneroWallet?.startListeners();
        libMoneroWallet?.startAutoSaving();
      } catch (e, s) {
        Logging.instance.log(
          "Exception rethrown from recoverFromMnemonic(): $e\n$s",
          level: LogLevel.Error,
        );
        rethrow;
      }
    });
  }

  @override
  Future<bool> pingCheck() async {
    return (await libMoneroWallet?.isConnectedToDaemon()) ?? false;
  }

  @override
  Future<void> updateNode() async {
    final node = getCurrentNode();

    final host = Uri.parse(node.host).host;
    ({InternetAddress host, int port})? proxy;
    if (prefs.useTor) {
      if (node.plainEnabled && !node.torEnabled) {
        libMoneroWallet?.stopAutoSaving();
        libMoneroWallet?.stopListeners();
        libMoneroWallet?.stopSyncing();
        _setSyncStatus(lib_monero_compat.FailedSyncStatus());
        throw Exception("TOR - clearnet mismatch");
      }
      proxy = TorService.sharedInstance.getProxyInfo();
    } else {
      if (!node.plainEnabled && node.torEnabled) {
        libMoneroWallet?.stopAutoSaving();
        libMoneroWallet?.stopListeners();
        libMoneroWallet?.stopSyncing();
        _setSyncStatus(lib_monero_compat.FailedSyncStatus());
        throw Exception("TOR - clearnet mismatch");
      }
    }

    _setSyncStatus(lib_monero_compat.ConnectingSyncStatus());
    try {
      if (_requireMutex) {
        await _torConnectingLock.protect(() async {
          await libMoneroWallet?.connect(
            daemonAddress: "$host:${node.port}",
            daemonUsername: node.loginName,
            daemonPassword: await node.getPassword(secureStorageInterface),
            trusted: node.trusted ?? false,
            useSSL: node.useSSL,
            socksProxyAddress:
                proxy == null ? null : "${proxy.host.address}:${proxy.port}",
          );
        });
      } else {
        await libMoneroWallet?.connect(
          daemonAddress: "$host:${node.port}",
          daemonUsername: node.loginName,
          daemonPassword: await node.getPassword(secureStorageInterface),
          trusted: node.trusted ?? false,
          useSSL: node.useSSL,
          socksProxyAddress:
              proxy == null ? null : "${proxy.host.address}:${proxy.port}",
        );
      }
      libMoneroWallet?.startSyncing();
      libMoneroWallet?.startListeners();
      libMoneroWallet?.startAutoSaving();

      _setSyncStatus(lib_monero_compat.ConnectedSyncStatus());
    } catch (e, s) {
      _setSyncStatus(lib_monero_compat.FailedSyncStatus());
      Logging.instance.log(
        "Exception caught in $runtimeType.updateNode(): $e\n$s",
        level: LogLevel.Error,
      );
    }

    return;
  }

  @override
  Future<void> updateTransactions() async {
    final base = libMoneroWallet;

    if (base == null) {
      return;
    }

    final transactions = await base.getTxs(refresh: true);

    final allOutputs = await base.getOutputs(includeSpent: true, refresh: true);

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

    final List<TransactionV2> txns = [];

    for (final tx in transactions) {
      final associatedOutputs = allOutputs.where((e) => e.hash == tx.hash);
      final List<InputV2> inputs = [];
      final List<OutputV2> outputs = [];
      TransactionType type;
      if (!tx.isSpend) {
        type = TransactionType.incoming;
        for (final output in associatedOutputs) {
          outputs.add(
            OutputV2.isarCantDoRequiredInDefaultConstructor(
              scriptPubKeyHex: "",
              valueStringSats: output.value.toString(),
              addresses: [output.address],
              walletOwns: true,
            ),
          );
        }
      } else {
        type = TransactionType.outgoing;
        for (final output in associatedOutputs) {
          inputs.add(
            InputV2.isarCantDoRequiredInDefaultConstructor(
              scriptSigHex: null,
              scriptSigAsm: null,
              sequence: null,
              outpoint: null,
              addresses: [output.address],
              valueStringSats: output.value.toString(),
              witness: null,
              innerRedeemScriptAsm: null,
              coinbase: null,
              walletOwns: true,
            ),
          );
        }
      }

      final txn = TransactionV2(
        walletId: walletId,
        blockHash: null, // not exposed via current cs_monero
        hash: tx.hash,
        txid: tx.hash,
        timestamp: (tx.timeStamp.millisecondsSinceEpoch ~/ 1000),
        height: tx.blockHeight,
        inputs: inputs,
        outputs: outputs,
        version: -1, // not exposed via current cs_monero
        type: type,
        subType: TransactionSubType.none,
        otherData: jsonEncode({
          TxV2OdKeys.overrideFee: Amount(
            rawValue: tx.fee,
            fractionDigits: cryptoCurrency.fractionDigits,
          ).toJsonString(),
          TxV2OdKeys.moneroAmount: Amount(
            rawValue: tx.amount,
            fractionDigits: cryptoCurrency.fractionDigits,
          ).toJsonString(),
          TxV2OdKeys.moneroAccountIndex: tx.accountIndex,
          TxV2OdKeys.isMoneroTransaction: true,
        }),
      );

      txns.add(txn);
    }

    await mainDB.updateOrPutTransactionV2s(txns);
  }

  Future<Amount> get availableBalance async {
    try {
      return Amount(
        rawValue: libMoneroWallet!.getUnlockedBalance(),
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    } catch (_) {
      return info.cachedBalance.spendable;
    }
  }

  Future<Amount> get totalBalance async {
    try {
      final full = libMoneroWallet?.getBalance();
      if (full != null) {
        return Amount(
          rawValue: full,
          fractionDigits: cryptoCurrency.fractionDigits,
        );
      } else {
        final transactions = await libMoneroWallet!.getTxs(refresh: true);
        BigInt transactionBalance = BigInt.zero;
        for (final tx in transactions) {
          if (!tx.isSpend) {
            transactionBalance += tx.amount;
          } else {
            transactionBalance += -tx.amount - tx.fee;
          }
        }

        return Amount(
          rawValue: transactionBalance,
          fractionDigits: cryptoCurrency.fractionDigits,
        );
      }
    } catch (_) {
      return info.cachedBalance.total;
    }
  }

  @override
  Future<void> exit() async {
    libMoneroWallet?.stopAutoSaving();
    libMoneroWallet?.stopListeners();
    libMoneroWallet?.stopSyncing();
    await libMoneroWallet?.save();
  }

  Future<String> pathForWalletDir({
    required String name,
    required lib_monero_compat.WalletType type,
  }) async {
    final Directory root = await StackFileSystem.applicationRootDirectory();
    return lib_monero_compat.pathForWalletDir(
      name: name,
      type: type.name.toLowerCase(),
      appRoot: root,
    );
  }

  Future<String> pathForWallet({
    required String name,
    required lib_monero_compat.WalletType type,
  }) async =>
      await pathForWalletDir(name: name, type: type)
          .then((path) => '$path/$name');

  void onSyncingUpdate({
    required int syncHeight,
    required int nodeHeight,
    String? message,
  }) {
    if (nodeHeight > 0 && syncHeight >= 0) {
      currentKnownChainHeight = nodeHeight;
      updateChainHeight();
      final blocksLeft = nodeHeight - syncHeight;
      final lib_monero_compat.SyncStatus status;
      if (blocksLeft < 100) {
        status = lib_monero_compat.SyncedSyncStatus();

        // if (!_hasSyncAfterStartup) {
        //   _hasSyncAfterStartup = true;
        //   await save();
        // }
        //
        // if (walletInfo.isRecovery!) {
        //   await setAsRecovered();
        // }
      } else {
        final percent = syncHeight / currentKnownChainHeight;

        status = lib_monero_compat.SyncingSyncStatus(
          blocksLeft,
          percent,
          currentKnownChainHeight,
        );
      }

      _setSyncStatus(status);
      _refreshTxDataHelper();
    }
  }

  void onBalancesChanged({
    required BigInt newBalance,
    required BigInt newUnlockedBalance,
  }) {
    // do something?
  }

  void onNewBlock(int nodeHeight) {
    // do something?
  }

  final _utxosUpdateLock = Mutex();
  Future<void> onUTXOsChanged(List<UTXO> utxos) async {
    await _utxosUpdateLock.protect(() async {
      final cwUtxos = await libMoneroWallet?.getOutputs(refresh: true) ?? [];

      // bool changed = false;

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
              await libMoneroWallet?.freezeOutput(cw.keyImage);
              // changed = true;
            }
          } else {
            if (cw.isFrozen) {
              await libMoneroWallet?.thawOutput(cw.keyImage);
              // changed = true;
            }
          }
        }
      }

      // if (changed) {
      //   await libMoneroWallet?.updateUTXOs();
      // }
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
    final _syncStatus = syncStatus;

    if (_syncStatus != null) {
      if (_syncStatus.progress() == 1 && refreshMutex.isLocked) {
        refreshMutex.release();
      }

      WalletSyncStatus? status;
      xmrAndWowSyncSpecificFunctionThatShouldBeGottenRidOfInTheFuture(true);

      if (_syncStatus is lib_monero_compat.SyncingSyncStatus) {
        final int blocksLeft = _syncStatus.blocksLeft;

        // ensure at least 1 to prevent math errors
        final int height = max(1, _syncStatus.height);

        final nodeHeight = height + blocksLeft;
        currentKnownChainHeight = nodeHeight;

        // final percent = height / nodeHeight;
        final percent = _syncStatus.ptc;

        final highest = max(highestPercentCached, percent);

        final unchanged = highest == highestPercentCached;
        if (unchanged) {
          return;
        }

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
      } else if (_syncStatus is lib_monero_compat.SyncedSyncStatus) {
        status = WalletSyncStatus.synced;
      } else if (_syncStatus is lib_monero_compat.NotConnectedSyncStatus) {
        status = WalletSyncStatus.unableToSync;
        xmrAndWowSyncSpecificFunctionThatShouldBeGottenRidOfInTheFuture(false);
      } else if (_syncStatus is lib_monero_compat.StartingSyncStatus) {
        status = WalletSyncStatus.syncing;
        GlobalEventBus.instance.fire(
          RefreshPercentChangedEvent(
            highestPercentCached,
            walletId,
          ),
        );
      } else if (_syncStatus is lib_monero_compat.FailedSyncStatus) {
        status = WalletSyncStatus.unableToSync;
        xmrAndWowSyncSpecificFunctionThatShouldBeGottenRidOfInTheFuture(false);
      } else if (_syncStatus is lib_monero_compat.ConnectingSyncStatus) {
        status = WalletSyncStatus.syncing;
        GlobalEventBus.instance.fire(
          RefreshPercentChangedEvent(
            highestPercentCached,
            walletId,
          ),
        );
      } else if (_syncStatus is lib_monero_compat.ConnectedSyncStatus) {
        status = WalletSyncStatus.syncing;
        GlobalEventBus.instance.fire(
          RefreshPercentChangedEvent(
            highestPercentCached,
            walletId,
          ),
        );
      } else if (_syncStatus is lib_monero_compat.LostConnectionSyncStatus) {
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

  // ============ Private ======================================================
  Future<void> _refreshTxDataHelper() async {
    if (_txRefreshLock) return;
    _txRefreshLock = true;

    final _syncStatus = syncStatus;

    if (_syncStatus != null &&
        _syncStatus is lib_monero_compat.SyncingSyncStatus) {
      final int blocksLeft = _syncStatus.blocksLeft;
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
    final List<UTXO> outputArray = [];
    final utxos = await libMoneroWallet?.getOutputs(refresh: true) ??
        <lib_monero.Output>[];
    for (final rawUTXO in utxos) {
      if (!rawUTXO.spent) {
        final current = await mainDB.isar.utxos
            .where()
            .walletIdEqualTo(walletId)
            .filter()
            .voutEqualTo(rawUTXO.vout)
            .and()
            .txidEqualTo(rawUTXO.hash)
            .findFirst();
        final tx = await mainDB.isar.transactionV2s
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
          value: rawUTXO.value.toInt(),
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

    final node = getCurrentNode();

    if (prefs.useTor) {
      if (node.plainEnabled && !node.torEnabled) {
        libMoneroWallet?.stopAutoSaving();
        libMoneroWallet?.stopListeners();
        libMoneroWallet?.stopSyncing();
        _setSyncStatus(lib_monero_compat.FailedSyncStatus());
        throw Exception("TOR - clearnet mismatch");
      }
    } else {
      if (!node.plainEnabled && node.torEnabled) {
        libMoneroWallet?.stopAutoSaving();
        libMoneroWallet?.stopListeners();
        libMoneroWallet?.stopSyncing();
        _setSyncStatus(lib_monero_compat.FailedSyncStatus());
        throw Exception("TOR - clearnet mismatch");
      }
    }

    // this acquire should be almost instant due to above check.
    // Slight possibility of race but should be irrelevant
    await refreshMutex.acquire();

    libMoneroWallet?.startSyncing();
    _setSyncStatus(lib_monero_compat.StartingSyncStatus());

    await updateTransactions();
    await updateBalance();

    if (info.otherData[WalletInfoKeys.reuseAddress] != true) {
      await checkReceivingAddressForTransactions();
    }

    if (refreshMutex.isLocked) {
      refreshMutex.release();
    }

    final synced = await libMoneroWallet?.isSynced();

    if (synced == true) {
      _setSyncStatus(lib_monero_compat.SyncedSyncStatus());
    }
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
      final entries = await libMoneroWallet?.getTxs(refresh: true);
      if (entries != null) {
        for (final element in entries) {
          if (!element.isSpend) {
            final int curAddressIndex = element.addressIndexes.isEmpty
                ? 0
                : element.addressIndexes.reduce(max);
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

  // TODO: this needs some work. Prio's may need to be changed as well as estimated blocks
  @override
  Future<FeeObject> get fees async => FeeObject(
        numberOfBlocksFast: 10,
        numberOfBlocksAverage: 15,
        numberOfBlocksSlow: 20,
        fast: lib_monero.TransactionPriority.high.value,
        medium: lib_monero.TransactionPriority.medium.value,
        slow: lib_monero.TransactionPriority.normal.value,
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

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    try {
      final feeRate = txData.feeRateType;
      if (feeRate is FeeRateType) {
        lib_monero.TransactionPriority feePriority;
        switch (feeRate) {
          case FeeRateType.fast:
            feePriority = lib_monero.TransactionPriority.high;
            break;
          case FeeRateType.average:
            feePriority = lib_monero.TransactionPriority.medium;
            break;
          case FeeRateType.slow:
            feePriority = lib_monero.TransactionPriority.normal;
            break;
          default:
            throw ArgumentError("Invalid use of custom fee");
        }

        try {
          final bool sweep;

          if (txData.utxos == null) {
            final balance = await availableBalance;
            sweep = txData.amount! == balance;
          } else {
            final totalInputsValue = txData.utxos!
                .map((e) => e.value)
                .fold(BigInt.zero, (p, e) => p + BigInt.from(e));
            sweep = txData.amount!.raw == totalInputsValue;
          }

          // TODO: test this one day
          // cs_monero may not support this yet properly
          if (sweep && txData.recipients!.length > 1) {
            throw Exception("Send all not supported with multiple recipients");
          }

          final List<lib_monero.Recipient> outputs = [];
          for (final recipient in txData.recipients!) {
            final output = lib_monero.Recipient(
              address: recipient.address,
              amount: recipient.amount.raw,
            );

            outputs.add(output);
          }

          if (outputs.isEmpty) {
            throw Exception("No recipients provided");
          }

          final height = await chainHeight;
          final inputs = txData.utxos
              ?.map(
                (e) => lib_monero.Output(
                  address: e.address!,
                  hash: e.txid,
                  keyImage: e.keyImage!,
                  value: BigInt.from(e.value),
                  isFrozen: e.isBlocked,
                  isUnlocked: e.blockHeight != null &&
                      (height - (e.blockHeight ?? 0)) >=
                          cryptoCurrency.minConfirms,
                  height: e.blockHeight ?? 0,
                  vout: e.vout,
                  spent: e.used ?? false,
                  spentHeight: null, // doesn't matter here
                  coinbase: e.isCoinbase,
                ),
              )
              .toList();

          return await prepareSendMutex.protect(() async {
            final lib_monero.PendingTransaction pendingTransaction;
            if (outputs.length == 1) {
              pendingTransaction = await libMoneroWallet!.createTx(
                output: outputs.first,
                paymentId: "",
                sweep: sweep,
                priority: feePriority,
                preferredInputs: inputs,
                accountIndex: 0, // sw only uses account 0 at this time
              );
            } else {
              pendingTransaction = await libMoneroWallet!.createTxMultiDest(
                outputs: outputs,
                paymentId: "",
                priority: feePriority,
                preferredInputs: inputs,
                sweep: sweep,
                accountIndex: 0, // sw only uses account 0 at this time
              );
            }

            final realFee = Amount(
              rawValue: pendingTransaction.fee,
              fractionDigits: cryptoCurrency.fractionDigits,
            );

            return txData.copyWith(
              fee: realFee,
              pendingTransaction: pendingTransaction,
            );
          });
        } catch (e) {
          rethrow;
        }
      } else {
        throw ArgumentError("Invalid fee rate argument provided!");
      }
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from prepare send(): $e\n$s",
        level: LogLevel.Info,
      );

      if (e.toString().contains("Incorrect unlocked balance")) {
        throw Exception("Insufficient balance!");
      } else {
        throw Exception("Transaction failed with error: $e");
      }
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      try {
        await libMoneroWallet!.commitTx(
          txData.pendingTransaction!,
        );

        Logging.instance.log(
          "transaction ${txData.pendingTransaction!.txid} has been sent",
          level: LogLevel.Info,
        );
        return txData.copyWith(txid: txData.pendingTransaction!.txid);
      } catch (e, s) {
        Logging.instance.log(
          "${info.name} ${compatType.name.toLowerCase()} confirmSend: $e\n$s",
          level: LogLevel.Error,
        );
        rethrow;
      }
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from confirmSend(): $e\n$s",
        level: LogLevel.Info,
      );
      rethrow;
    }
  }

  // ============== View only ==================================================

  @override
  Future<void> recoverViewOnly() async {
    await refreshMutex.protect(() async {
      final data =
          await getViewOnlyWalletData() as CryptonoteViewOnlyWalletData;

      try {
        final height = max(info.restoreHeight, 0);

        await info.updateRestoreHeight(
          newRestoreHeight: height,
          isar: mainDB.isar,
        );

        final String name = walletId;

        final path = await pathForWallet(
          name: name,
          type: compatType,
        );

        final password = generatePassword();
        await secureStorageInterface.write(
          key: lib_monero_compat.libMoneroWalletPasswordKey(walletId),
          value: password,
        );
        final wallet = await getRestoredFromViewKeyWallet(
          path: path,
          password: password,
          address: data.address,
          privateViewKey: data.privateViewKey,
          height: height,
        );

        if (libMoneroWallet != null) {
          await exit();
        }

        libMoneroWallet = wallet;

        _setListener();

        final newReceivingAddress = await getCurrentReceivingAddress() ??
            Address(
              walletId: walletId,
              derivationIndex: 0,
              derivationPath: null,
              value: wallet.getAddress().value,
              publicKey: [],
              type: AddressType.cryptonote,
              subType: AddressSubType.receiving,
            );

        await mainDB.updateOrPutAddresses([newReceivingAddress]);
        await info.updateReceivingAddress(
          newAddress: newReceivingAddress.value,
          isar: mainDB.isar,
        );

        await updateNode();
        _setListener();

        unawaited(libMoneroWallet?.rescanBlockchain());
        libMoneroWallet?.startSyncing();

        // await save();
        libMoneroWallet?.startListeners();
        libMoneroWallet?.startAutoSaving();
      } catch (e, s) {
        Logging.instance.log(
          "Exception rethrown from recoverViewOnly(): $e\n$s",
          level: LogLevel.Error,
        );
        rethrow;
      }
    });
  }

  // ============== Private ====================================================

  StreamSubscription<TorConnectionStatusChangedEvent>? _torStatusListener;
  StreamSubscription<TorPreferenceChangedEvent>? _torPreferenceListener;

  final Mutex _torConnectingLock = Mutex();
  bool _requireMutex = false;
}
