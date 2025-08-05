import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cs_salvium/cs_salvium.dart' as lib_salvium;
import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stack_wallet_backup/generate_password.dart';

import '../../../models/balance.dart';
import '../../../models/input.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/utxo.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/keys/cw_key_data.dart';
import '../../../models/keys/view_only_wallet_data.dart';
import '../../../models/node_model.dart';
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

abstract class LibSalviumWallet<T extends CryptonoteCurrency>
    extends CryptonoteWallet<T>
    with ViewOnlyOptionInterface<T>
    implements MultiAddressInterface<T> {
  @override
  int get isarTransactionVersion => 2;

  LibSalviumWallet(super.currency) {
    final bus = GlobalEventBus.instance;

    // Listen for tor status changes.
    _torStatusListener = bus.on<TorConnectionStatusChangedEvent>().listen((
      event,
    ) async {
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
    });

    // Listen for tor preference changes.
    _torPreferenceListener = bus.on<TorPreferenceChangedEvent>().listen((
      event,
    ) async {
      await updateNode();
    });

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
              lib_salvium.Logging.log?.i("_startInit", error: e, stackTrace: s);
            }
          });
    });
  }

  lib_salvium.Wallet? libSalviumWallet;

  SyncStatus? get syncStatus => _syncStatus;
  SyncStatus? _syncStatus;
  int _syncedCount = 0;
  void _setSyncStatus(SyncStatus status) {
    if (status is SyncedSyncStatus) {
      if (_syncStatus is SyncedSyncStatus) {
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

  Future<void> loadWallet({required String path, required String password});

  Future<lib_salvium.Wallet> getCreatedWallet({
    required String path,
    required String password,
    required int wordCount,
    required String seedOffset,
  });

  Future<lib_salvium.Wallet> getRestoredWallet({
    required String path,
    required String password,
    required String mnemonic,
    required String seedOffset,
    int height = 0,
  });

  Future<lib_salvium.Wallet> getRestoredFromViewKeyWallet({
    required String path,
    required String password,
    required String address,
    required String privateViewKey,
    int height = 0,
  });

  void invalidSeedLengthCheck(int length);

  bool walletExists(String path);

  String getTxKeyFor({required String txid}) {
    if (libSalviumWallet == null) {
      throw Exception("Cannot get tx key in uninitialized libSalviumWallet");
    }
    return libSalviumWallet!.getTxKey(txid);
  }

  void _setListener() {
    if (libSalviumWallet != null && libSalviumWallet!.getListeners().isEmpty) {
      libSalviumWallet?.addListener(
        lib_salvium.WalletListener(
          onSyncingUpdate: onSyncingUpdate,
          onNewBlock: onNewBlock,
          onBalancesChanged: onBalancesChanged,
          onError: (e, s) {
            Logging.instance.w("$e\n$s", error: e, stackTrace: s);
          },
        ),
      );
    }
  }

  @override
  Future<void> open() async {
    bool wasNull = false;

    if (libSalviumWallet == null) {
      wasNull = true;
      // await libSalviumWallet?.close();
      final path = await pathForWallet(name: walletId);

      final String password;
      try {
        password =
            (await secureStorageInterface.read(
              key: _libSalviumWalletPasswordKey(walletId.toUpperCase()),
            ))!;
      } catch (e, s) {
        throw Exception("Password not found $e, $s");
      }

      await loadWallet(path: path, password: password);

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
        _setSyncStatus(ConnectingSyncStatus());
        libSalviumWallet?.startSyncing();
      } catch (_) {
        _setSyncStatus(FailedSyncStatus());
        // TODO log
      }
    }
    _setListener();
    libSalviumWallet?.startListeners();
    libSalviumWallet?.startAutoSaving();

    unawaited(refresh());
  }

  Future<void> save() async {
    if (!Platform.isWindows) {
      final appRoot = await StackFileSystem.applicationRootDirectory();
      await _backupWalletFiles(name: walletId, appRoot: appRoot);
    }
    await libSalviumWallet!.save();
  }

  Address addressFor({required int index, int account = 0}) {
    final address = libSalviumWallet!.getAddress(
      accountIndex: account,
      addressIndex: index,
    );

    if (address.value.contains("111")) {
      throw Exception("111 address found!");
    }

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
    final base = libSalviumWallet;

    if (base == null) {
      return null;
    }
    try {
      return CWKeyData(
        walletId: walletId,
        publicViewKey: base.getPublicViewKey(),
        privateViewKey: base.getPrivateViewKey(),
        publicSpendKey: base.getPublicSpendKey(),
        privateSpendKey: base.getPrivateSpendKey(),
      );
    } catch (e, s) {
      Logging.instance.f("getKeys failed: ", error: e, stackTrace: s);
      return CWKeyData(
        walletId: walletId,
        publicViewKey: "ERROR",
        privateViewKey: "ERROR",
        publicSpendKey: "ERROR",
        privateSpendKey: "ERROR",
      );
    }
  }

  Future<(String, String)>
  hackToCreateNewViewOnlyWalletDataFromNewlyCreatedWalletThisFunctionShouldNotBeCalledUnlessYouKnowWhatYouAreDoing() async {
    final path = await pathForWallet(name: walletId);
    final String password;
    try {
      password =
          (await secureStorageInterface.read(
            key: _libSalviumWalletPasswordKey(walletId),
          ))!;
    } catch (e, s) {
      throw Exception("Password not found $e, $s");
    }
    await loadWallet(path: path, password: password);
    final wallet = libSalviumWallet!;
    return (wallet.getAddress().value, wallet.getPrivateViewKey());
  }

  @override
  Future<void> init({bool? isRestore, int? wordCount}) async {
    final path = await pathForWallet(name: walletId);
    if (!(walletExists(path)) && isRestore != true) {
      wordCount ??= 25;
      try {
        final password = generatePassword();
        await secureStorageInterface.write(
          key: _libSalviumWalletPasswordKey(walletId),
          value: password,
        );
        final wallet = await getCreatedWallet(
          path: path,
          password: password,
          wordCount: wordCount,
          seedOffset: "", // default for non restored wallets for now
        );

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
        Logging.instance.f("", error: e, stackTrace: s);
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
        unawaited(libSalviumWallet?.rescanBlockchain());
        libSalviumWallet?.startSyncing();
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
      final seedOffset = await getMnemonicPassphrase();
      final seedLength = mnemonic.trim().split(" ").length;

      invalidSeedLengthCheck(seedLength);

      try {
        final height = max(info.restoreHeight, 0);

        await info.updateRestoreHeight(
          newRestoreHeight: height,
          isar: mainDB.isar,
        );

        final String name = walletId;

        final path = await pathForWallet(name: name);

        try {
          final password = generatePassword();
          await secureStorageInterface.write(
            key: _libSalviumWalletPasswordKey(walletId),
            value: password,
          );
          final wallet = await getRestoredWallet(
            path: path,
            password: password,
            mnemonic: mnemonic,
            height: height,
            seedOffset: seedOffset,
          );

          if (libSalviumWallet != null) {
            await exit();
          }

          libSalviumWallet = wallet;

          _setListener();

          final newReceivingAddress =
              await getCurrentReceivingAddress() ??
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
          Logging.instance.f("", error: e, stackTrace: s);
          rethrow;
        }
        await updateNode();
        _setListener();

        // libSalviumWallet?.setRecoveringFromSeed(isRecovery: true);
        unawaited(libSalviumWallet?.rescanBlockchain());
        libSalviumWallet?.startSyncing();

        // await save();
        libSalviumWallet?.startListeners();
        libSalviumWallet?.startAutoSaving();
      } catch (e, s) {
        Logging.instance.e(
          "Exception rethrown from recoverFromMnemonic(): ",
          error: e,
          stackTrace: s,
        );
        rethrow;
      }
    });
  }

  bool _canPing = false;

  @override
  Future<bool> pingCheck() async {
    if (_canPing) {
      return (await libSalviumWallet?.isConnectedToDaemon()) ?? false;
    } else {
      return false;
    }
  }

  @override
  Future<void> updateNode() async {
    final node = getCurrentNode();

    if (_torNodeMismatchGuard(node)) {
      throw Exception("TOR – clearnet mismatch");
    }

    final host =
        node.host.endsWith(".onion") ? node.host : Uri.parse(node.host).host;
    ({InternetAddress host, int port})? proxy;
    proxy =
        prefs.useTor && !node.forceNoTor
            ? TorService.sharedInstance.getProxyInfo()
            : null;

    _setSyncStatus(ConnectingSyncStatus());
    try {
      if (_requireMutex) {
        await _torConnectingLock.protect(() async {
          await libSalviumWallet?.connect(
            daemonAddress: "$host:${node.port}",
            daemonUsername: node.loginName,
            daemonPassword: await node.getPassword(secureStorageInterface),
            trusted: node.trusted ?? false,
            useSSL: node.useSSL,
            socksProxyAddress:
                node.forceNoTor
                    ? null
                    : proxy == null
                    ? null
                    : "${proxy.host.address}:${proxy.port}",
          );
        });
      } else {
        await libSalviumWallet?.connect(
          daemonAddress: "$host:${node.port}",
          daemonUsername: node.loginName,
          daemonPassword: await node.getPassword(secureStorageInterface),
          trusted: node.trusted ?? false,
          useSSL: node.useSSL,
          socksProxyAddress:
              node.forceNoTor
                  ? null
                  : proxy == null
                  ? null
                  : "${proxy.host.address}:${proxy.port}",
        );
      }
      libSalviumWallet?.startSyncing();
      libSalviumWallet?.startListeners();
      libSalviumWallet?.startAutoSaving();

      // _setSyncStatus(ConnectedSyncStatus());
    } catch (e, s) {
      // _setSyncStatus(FailedSyncStatus());
      Logging.instance.e(
        "Exception caught in $runtimeType.updateNode(): ",
        error: e,
        stackTrace: s,
      );
    }

    return;
  }

  @override
  Future<void> updateTransactions() async {
    final base = libSalviumWallet;

    if (base == null) {
      return;
    }

    final localTxids =
        await mainDB.isar.transactionV2s
            .where()
            .walletIdEqualTo(walletId)
            .filter()
            .heightGreaterThan(0)
            .txidProperty()
            .findAll();

    final allTxids = await base.getAllTxids(refresh: true);

    final txidsToFetch = allTxids.toSet().difference(localTxids.toSet());

    if (txidsToFetch.isEmpty) {
      return;
    }

    final transactions = await base.getTxs(txids: txidsToFetch, refresh: false);

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
        blockHash: null, // not exposed via current cs_salvium
        hash: tx.hash,
        txid: tx.hash,
        timestamp: (tx.timeStamp.millisecondsSinceEpoch ~/ 1000),
        height: tx.blockHeight,
        inputs: inputs,
        outputs: outputs,
        version: -1, // not exposed via current cs_salvium
        type: type,
        subType: TransactionSubType.none,
        otherData: jsonEncode({
          TxV2OdKeys.overrideFee:
              Amount(
                rawValue: tx.fee,
                fractionDigits: cryptoCurrency.fractionDigits,
              ).toJsonString(),
          TxV2OdKeys.moneroAmount:
              Amount(
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
        rawValue: libSalviumWallet!.getUnlockedBalance(),
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    } catch (_) {
      return info.cachedBalance.spendable;
    }
  }

  Future<Amount> get totalBalance async {
    try {
      final full = libSalviumWallet?.getBalance();
      if (full != null) {
        return Amount(
          rawValue: full,
          fractionDigits: cryptoCurrency.fractionDigits,
        );
      } else {
        final transactions = await libSalviumWallet!.getAllTxs(refresh: true);
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
    Logging.instance.i("exit called on $walletId");
    libSalviumWallet?.stopAutoSaving();
    libSalviumWallet?.stopListeners();
    libSalviumWallet?.stopSyncing();
    await libSalviumWallet?.save();
  }

  Future<String> pathForWalletDir({required String name}) async {
    final Directory root = await StackFileSystem.applicationRootDirectory();
    return _pathForWalletDir(name: name, appRoot: root);
  }

  Future<String> pathForWallet({required String name}) async =>
      await pathForWalletDir(name: name).then((path) => '$path/$name');

  void onSyncingUpdate({
    required int syncHeight,
    required int nodeHeight,
    String? message,
  }) {
    if (nodeHeight > 0 && syncHeight >= 0) {
      currentKnownChainHeight = nodeHeight;
      updateChainHeight();
      final blocksLeft = nodeHeight - syncHeight;
      final SyncStatus status;
      if (blocksLeft < 100) {
        status = SyncedSyncStatus();

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

        status = SyncingSyncStatus(
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
  }) async {
    try {
      await updateBalance();
      await updateTransactions();
    } catch (e, s) {
      Logging.instance.w("onBalancesChanged(): ", error: e, stackTrace: s);
    }
  }

  void onNewBlock(int nodeHeight) async {
    try {
      await updateTransactions();
    } catch (e, s) {
      Logging.instance.w("onNewBlock(): ", error: e, stackTrace: s);
    }
  }

  final _utxosUpdateLock = Mutex();
  Future<void> onUTXOsChanged(List<UTXO> utxos) async {
    await _utxosUpdateLock.protect(() async {
      final cwUtxos = await libSalviumWallet?.getOutputs(refresh: true) ?? [];

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
              await libSalviumWallet?.freezeOutput(cw.keyImage);
              // changed = true;
            }
          } else {
            if (cw.isFrozen) {
              await libSalviumWallet?.thawOutput(cw.keyImage);
              // changed = true;
            }
          }
        }
      }

      // if (changed) {
      //   await libSalviumWallet?.updateUTXOs();
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

      if (_syncStatus is SyncingSyncStatus) {
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
          RefreshPercentChangedEvent(highest, walletId),
        );
        GlobalEventBus.instance.fire(
          BlocksRemainingEvent(blocksLeft, walletId),
        );
      } else if (_syncStatus is SyncedSyncStatus) {
        status = WalletSyncStatus.synced;
      } else if (_syncStatus is NotConnectedSyncStatus) {
        status = WalletSyncStatus.unableToSync;
        xmrAndWowSyncSpecificFunctionThatShouldBeGottenRidOfInTheFuture(false);
      } else if (_syncStatus is StartingSyncStatus) {
        status = WalletSyncStatus.syncing;
        GlobalEventBus.instance.fire(
          RefreshPercentChangedEvent(highestPercentCached, walletId),
        );
      } else if (_syncStatus is FailedSyncStatus) {
        status = WalletSyncStatus.unableToSync;
        xmrAndWowSyncSpecificFunctionThatShouldBeGottenRidOfInTheFuture(false);
      } else if (_syncStatus is ConnectingSyncStatus) {
        status = WalletSyncStatus.syncing;
        GlobalEventBus.instance.fire(
          RefreshPercentChangedEvent(highestPercentCached, walletId),
        );
      } else if (_syncStatus is ConnectedSyncStatus) {
        status = WalletSyncStatus.syncing;
        GlobalEventBus.instance.fire(
          RefreshPercentChangedEvent(highestPercentCached, walletId),
        );
      } else if (_syncStatus is LostConnectionSyncStatus) {
        status = WalletSyncStatus.unableToSync;
        xmrAndWowSyncSpecificFunctionThatShouldBeGottenRidOfInTheFuture(false);
      }

      if (status != null) {
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(status, walletId, info.coin),
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

    if (_syncStatus != null && _syncStatus is SyncingSyncStatus) {
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

  bool _torNodeMismatchGuard(NodeModel node) {
    _canPing = true; // Reset.

    final bool mismatch =
        (prefs.useTor && node.clearnetEnabled && !node.torEnabled) ||
        (!prefs.useTor && !node.clearnetEnabled && node.torEnabled);

    if (mismatch) {
      _canPing = false;
      libSalviumWallet?.stopAutoSaving();
      libSalviumWallet?.stopListeners();
      libSalviumWallet?.stopSyncing();
      _setSyncStatus(FailedSyncStatus());
    }

    return mismatch; // Caller decides whether to throw.
  }

  // ============ Overrides ====================================================

  @override
  FilterOperation? get changeAddressFilterOperation => null;

  @override
  FilterOperation? get receivingAddressFilterOperation => null;

  @override
  Future<bool> updateUTXOs() async {
    final List<UTXO> outputArray = [];
    final utxos =
        await libSalviumWallet?.getOutputs(refresh: true) ??
        <lib_salvium.Output>[];
    for (final rawUTXO in utxos) {
      if (!rawUTXO.spent) {
        final current =
            await mainDB.isar.utxos
                .where()
                .walletIdEqualTo(walletId)
                .filter()
                .voutEqualTo(rawUTXO.vout)
                .and()
                .txidEqualTo(rawUTXO.hash)
                .findFirst();
        final tx =
            await mainDB.isar.transactionV2s
                .where()
                .walletIdEqualTo(walletId)
                .filter()
                .txidEqualTo(rawUTXO.hash)
                .findFirst();

        final otherDataMap = {
          UTXOOtherDataKeys.keyImage: rawUTXO.keyImage,
          UTXOOtherDataKeys.spent: rawUTXO.spent,
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

    if (_torNodeMismatchGuard(node)) {
      throw Exception("TOR – clearnet mismatch");
    }

    // this acquire should be almost instant due to above check.
    // Slight possibility of race but should be irrelevant
    await refreshMutex.acquire();

    libSalviumWallet?.startSyncing();
    _setSyncStatus(StartingSyncStatus());

    await updateTransactions();
    await updateBalance();

    if (info.otherData[WalletInfoKeys.reuseAddress] != true) {
      await checkReceivingAddressForTransactions();
    }

    if (refreshMutex.isLocked) {
      refreshMutex.release();
    }

    final synced = await libSalviumWallet?.isSynced();

    if (synced == true) {
      _setSyncStatus(SyncedSyncStatus());
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
      Logging.instance.e(
        "Exception in generateNewAddress(): ",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> checkReceivingAddressForTransactions() async {
    if (info.otherData[WalletInfoKeys.reuseAddress] == true) {
      try {
        throw Exception();
      } catch (_, s) {
        Logging.instance.e(
          "checkReceivingAddressForTransactions called but reuse address flag set: $s",
          error: e,
          stackTrace: s,
        );
      }
    }

    try {
      int highestIndex = -1;
      final entries = await libSalviumWallet?.getAllTxs(refresh: true);
      if (entries != null) {
        for (final element in entries) {
          if (!element.isSpend) {
            final int curAddressIndex =
                element.addressIndexes.isEmpty
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

        final existing =
            await mainDB
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
      Logging.instance.e(
        "SocketException caught in _checkReceivingAddressForTransactions(): $se\n$s",
        error: e,
        stackTrace: s,
      );
      return;
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from _checkReceivingAddressForTransactions(): ",
        error: e,
        stackTrace: s,
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
    fast: BigInt.from(lib_salvium.TransactionPriority.high.value),
    medium: BigInt.from(lib_salvium.TransactionPriority.medium.value),
    slow: BigInt.from(lib_salvium.TransactionPriority.normal.value),
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
        lib_salvium.TransactionPriority feePriority;
        switch (feeRate) {
          case FeeRateType.fast:
            feePriority = lib_salvium.TransactionPriority.high;
            break;
          case FeeRateType.average:
            feePriority = lib_salvium.TransactionPriority.medium;
            break;
          case FeeRateType.slow:
            feePriority = lib_salvium.TransactionPriority.normal;
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
                .fold(BigInt.zero, (p, e) => p + e);
            sweep = txData.amount!.raw == totalInputsValue;
          }

          // TODO: test this one day
          // cs_salvium may not support this yet properly
          if (sweep && txData.recipients!.length > 1) {
            throw Exception("Send all not supported with multiple recipients");
          }

          final List<lib_salvium.Recipient> outputs = [];
          for (final recipient in txData.recipients!) {
            final output = lib_salvium.Recipient(
              address: recipient.address,
              amount: recipient.amount.raw,
            );

            outputs.add(output);
          }

          if (outputs.isEmpty) {
            throw Exception("No recipients provided");
          }

          final height = await chainHeight;
          final inputs =
              txData.utxos
                  ?.whereType<StandardInput>()
                  .map(
                    (e) => lib_salvium.Output(
                      address: e.utxo.address!,
                      hash: e.utxo.txid,
                      keyImage: e.utxo.keyImage!,
                      value: e.value,
                      isFrozen: e.utxo.isBlocked,
                      isUnlocked:
                          e.utxo.blockHeight != null &&
                          (height - (e.utxo.blockHeight ?? 0)) >=
                              cryptoCurrency.minConfirms,
                      height: e.utxo.blockHeight ?? 0,
                      vout: e.utxo.vout,
                      spent: e.utxo.used ?? false,
                      spentHeight: null, // doesn't matter here
                      coinbase: e.utxo.isCoinbase,
                    ),
                  )
                  .toList();

          return await prepareSendMutex.protect(() async {
            final lib_salvium.PendingTransaction pendingTransaction;
            if (outputs.length == 1) {
              pendingTransaction = await libSalviumWallet!.createTx(
                output: outputs.first,
                paymentId: "",
                sweep: sweep,
                priority: feePriority,
                preferredInputs: inputs,
                accountIndex: 0, // sw only uses account 0 at this time
              );
            } else {
              pendingTransaction = await libSalviumWallet!.createTxMultiDest(
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
              pendingSalviumTransaction: pendingTransaction,
            );
          });
        } catch (e) {
          rethrow;
        }
      } else {
        throw ArgumentError("Invalid fee rate argument provided!");
      }
    } catch (e, s) {
      Logging.instance.i(
        "Exception rethrown from prepare send(): ",
        error: e,
        stackTrace: s,
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
        await libSalviumWallet!.commitTx(txData.pendingSalviumTransaction!);

        Logging.instance.d(
          "transaction ${txData.pendingSalviumTransaction!.txid} has been sent",
        );
        return txData.copyWith(txid: txData.pendingSalviumTransaction!.txid);
      } catch (e, s) {
        Logging.instance.e(
          "${info.name} confirmSend: ",
          error: e,
          stackTrace: s,
        );
        rethrow;
      }
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from confirmSend(): ",
        error: e,
        stackTrace: s,
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

        final path = await pathForWallet(name: name);

        final password = generatePassword();
        await secureStorageInterface.write(
          key: _libSalviumWalletPasswordKey(walletId.toUpperCase()),
          value: password,
        );
        final wallet = await getRestoredFromViewKeyWallet(
          path: path,
          password: password,
          address: data.address,
          privateViewKey: data.privateViewKey,
          height: height,
        );

        if (libSalviumWallet != null) {
          await exit();
        }

        libSalviumWallet = wallet;

        _setListener();

        final newReceivingAddress =
            await getCurrentReceivingAddress() ??
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

        unawaited(libSalviumWallet?.rescanBlockchain());
        libSalviumWallet?.startSyncing();

        // await save();
        libSalviumWallet?.startListeners();
        libSalviumWallet?.startAutoSaving();
      } catch (e, s) {
        Logging.instance.e(
          "Exception rethrown from recoverViewOnly(): ",
          error: e,
          stackTrace: s,
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

String _libSalviumWalletPasswordKey(String walletName) =>
    "SALVIUM_WALLET_PASSWORD_${walletName.toUpperCase()}";

String _backupFileName(String originalPath) {
  final pathParts = originalPath.split('/');
  final newName = '#_${pathParts.last}';
  pathParts.removeLast();
  pathParts.add(newName);
  return pathParts.join('/');
}

Future<void> _backupWalletFiles({
  required String name,
  required Directory appRoot,
}) async {
  final path = await _pathForWallet(name: name, appRoot: appRoot);
  final cacheFile = File(path);
  final keysFile = File('$path.keys');
  final addressListFile = File('$path.address.txt');
  final newCacheFilePath = _backupFileName(cacheFile.path);
  final newKeysFilePath = _backupFileName(keysFile.path);
  final newAddressListFilePath = _backupFileName(addressListFile.path);

  if (cacheFile.existsSync()) {
    await cacheFile.copy(newCacheFilePath);
  }

  if (keysFile.existsSync()) {
    await keysFile.copy(newKeysFilePath);
  }

  if (addressListFile.existsSync()) {
    await addressListFile.copy(newAddressListFilePath);
  }
}

Future<String> _pathForWalletDir({
  required String name,
  required Directory appRoot,
}) async {
  final walletsDir = Directory('${appRoot.path}/wallets');
  final walletDire = Directory('${walletsDir.path}/salvium/$name');

  if (!walletDire.existsSync()) {
    walletDire.createSync(recursive: true);
  }

  return walletDire.path;
}

Future<String> _pathForWallet({
  required String name,
  required Directory appRoot,
}) async => await _pathForWalletDir(
  name: name,
  appRoot: appRoot,
).then((path) => '$path/$name');

Future<String> salviumWalletDir({
  required String walletId,
  required Directory appRoot,
}) => _pathForWalletDir(name: walletId, appRoot: appRoot);

// =============================================================================
// The following sync status stuff copy pasted here for now to simplify the
// integration of salvium.
// TODO: eventually rework this (one day)

abstract class SyncStatus {
  const SyncStatus();
  double progress();
}

class SyncingSyncStatus extends SyncStatus {
  SyncingSyncStatus(this.blocksLeft, this.ptc, this.height);

  final double ptc;
  final int blocksLeft;
  final int height;

  @override
  double progress() => ptc;

  @override
  String toString() => '$blocksLeft';
}

class SyncedSyncStatus extends SyncStatus {
  @override
  double progress() => 1.0;
}

class NotConnectedSyncStatus extends SyncStatus {
  const NotConnectedSyncStatus();

  @override
  double progress() => 0.0;
}

class StartingSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;
}

class FailedSyncStatus extends SyncStatus {
  @override
  double progress() => 1.0;
}

class ConnectingSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;
}

class ConnectedSyncStatus extends SyncStatus {
  @override
  double progress() => 0.0;
}

class LostConnectionSyncStatus extends SyncStatus {
  @override
  double progress() => 1.0;
}

// =============================================================================
