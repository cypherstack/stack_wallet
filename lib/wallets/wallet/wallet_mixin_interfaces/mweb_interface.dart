import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:isar/isar.dart';
import 'package:mweb_client/mweb_client.dart';

import '../../../db/drift/database.dart';
import '../../../models/balance.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../services/event_bus/events/global/blocks_remaining_event.dart';
import '../../../services/event_bus/events/global/refresh_percent_changed_event.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../services/mwebd_service.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../isar/models/wallet_info.dart';
import '../../models/tx_data.dart';
import 'electrumx_interface.dart';

mixin MwebInterface<T extends ElectrumXCurrencyInterface>
    on ElectrumXInterface<T> {
  // TODO

  StreamSubscription<Utxo>? _mwebUtxoSubscription;

  Future<Uint8List> get _scanSecret async =>
      (await getRootHDNode()).derivePath("m/1000'/0'").privateKey.data;
  Future<Uint8List> get _spendSecret async =>
      (await getRootHDNode()).derivePath("m/1000'/1'").privateKey.data;
  Future<Uint8List> get _spendPub async =>
      (await getRootHDNode()).derivePath("m/1000'/1'").publicKey.data;

  Future<Address?> getCurrentReceivingMwebAddress() async {
    return await mainDB.isar.addresses
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .typeEqualTo(AddressType.mweb)
        .sortByDerivationIndexDesc()
        .findFirst();
  }

  Future<MwebClient> get _client async {
    final client = await MwebdService.instance.getClient(
      cryptoCurrency.network,
    );
    if (client == null) {
      throw Exception("Fetched mweb client returned null");
    }
    return client;
  }

  WalletSyncStatus? _syncStatus;
  Timer? _mwebdPolling;
  int currentKnownChainHeight = 0;
  double highestPercentCached = 0;
  void _startPollingMwebd() async {
    _mwebdPolling?.cancel();
    _mwebdPolling = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final status = await MwebdService.instance.getServerStatus(
          cryptoCurrency.network,
        );

        Logging.instance.i("_polling mwebd status: $status");

        if (status == null) {
          throw Exception(
            "Mwebd server status is null. Was mwebd initialized?",
          );
        }

        final currentKnownChainHeight = await chainHeight;

        final ({int remaining, double percent})? syncInfo;

        if (status.blockHeaderHeight < currentKnownChainHeight) {
          syncInfo = (
            remaining: currentKnownChainHeight - status.blockHeaderHeight,
            percent: status.blockHeaderHeight / currentKnownChainHeight,
          );
        } else if (status.mwebHeaderHeight < currentKnownChainHeight) {
          syncInfo = (
            remaining: currentKnownChainHeight - status.mwebHeaderHeight,
            percent: status.mwebHeaderHeight / currentKnownChainHeight,
          );
        } else if (status.mwebUtxosHeight < currentKnownChainHeight) {
          syncInfo = (remaining: 1, percent: 0.99);
        } else {
          syncInfo = null;
        }

        WalletSyncStatus? syncStatus;

        if (syncInfo != null) {
          final previous = highestPercentCached;
          highestPercentCached = math.max(
            highestPercentCached,
            syncInfo.percent,
          );

          if (previous != highestPercentCached) {
            GlobalEventBus.instance.fire(
              RefreshPercentChangedEvent(highestPercentCached, walletId),
            );
            GlobalEventBus.instance.fire(
              BlocksRemainingEvent(syncInfo.remaining, walletId),
            );
          }

          syncStatus = WalletSyncStatus.syncing;
        } else {
          final walletMwebScanHeight =
              info.otherData[WalletInfoKeys.mwebScanHeight] as int? ??
              info.restoreHeight;

          if (status.mwebUtxosHeight > walletMwebScanHeight) {
            // TODO: check utxos and transactions?

            // then
            await info.updateOtherData(
              newEntries: {
                WalletInfoKeys.mwebScanHeight: status.mwebUtxosHeight,
              },
              isar: mainDB.isar,
            );
          }

          syncStatus = WalletSyncStatus.synced;
        }

        _syncStatus = syncStatus;
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(syncStatus, walletId, info.coin),
        );
      } catch (e, s) {
        Logging.instance.e(
          "mweb wallet polling error",
          error: e,
          stackTrace: s,
        );
        _syncStatus = WalletSyncStatus.unableToSync;
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(_syncStatus!, walletId, info.coin),
        );
      }
    });
  }

  Future<void> _startUpdateMwebUtxos() async {
    final client = await _client;

    Logging.instance.i("info.restoreHeight: ${info.restoreHeight}");
    final fromHeight = info.restoreHeight;

    final request = UtxosRequest(
      fromHeight: fromHeight,
      scanSecret: await _scanSecret,
    );

    await _mwebUtxoSubscription?.cancel();
    final db = Drift.get(walletId);
    _mwebUtxoSubscription = (await client.utxos(request)).listen((utxo) async {
      Logging.instance.i(
        "Found UTXO in stream: Utxo("
        "height: ${utxo.height}, "
        "value: ${utxo.value}, "
        "address: ${utxo.address}, "
        "outputId: ${utxo.outputId}, "
        "blockTime: ${utxo.blockTime}"
        ")",
      );

      if (utxo.address.isNotEmpty && utxo.outputId.isNotEmpty) {
        try {
          await db.transaction(() async {
            final prev =
                await (db.select(db.mwebUtxos)..where(
                  (e) => e.outputId.equals(utxo.outputId),
                )).getSingleOrNull();

            await db
                .into(db.mwebUtxos)
                .insertOnConflictUpdate(
                  MwebUtxosCompanion(
                    outputId: Value(prev?.outputId ?? utxo.outputId),
                    address: Value(prev?.address ?? utxo.address),
                    value: Value(utxo.value.toInt()),
                    height: Value(utxo.height),
                    blockTime: Value(utxo.blockTime),
                    blocked: Value(prev?.blocked ?? false),
                    used: Value(prev?.used ?? false),
                  ),
                );
          });
        } catch (e, s) {
          Logging.instance.f(
            "Failed to insert/update mweb utxo",
            error: e,
            stackTrace: s,
          );
        }
      } else {
        Logging.instance.w("Empty mweb utxo not added to db... ??");
      }
    });
  }

  Future<void> _initMweb() async {
    try {
      // check server is up
      final status = await MwebdService.instance.getServerStatus(
        cryptoCurrency.network,
      );
      if (status == null) {
        await MwebdService.instance.init(cryptoCurrency.network);
      }

      _startPollingMwebd();
    } catch (e, s) {
      Logging.instance.e("testing initMweb failed", error: e, stackTrace: s);
    }
  }

  Future<Address> generateNextMwebAddress() async {
    if (!info.isMwebEnabled) {
      throw Exception(
        "Tried calling generateNextMwebAddress with mweb disabled for $walletId ${info.name}",
      );
    }
    final highestStoredIndex =
        (await getCurrentReceivingMwebAddress())?.derivationIndex ?? -1;

    final nextIndex = highestStoredIndex + 1;

    final client = await _client;

    final response = await client.address(
      await _scanSecret,
      await _spendPub,
      nextIndex,
    );

    return Address(
      walletId: walletId,
      value: response,
      publicKey: [],
      derivationIndex: nextIndex,
      derivationPath: null,
      type: AddressType.mweb,
      subType: AddressSubType.receiving,
    );
  }

  Future<Amount> estimateFeeForMweb(Amount amount) async {
    if (!info.isMwebEnabled) {
      throw Exception(
        "Tried calling estimateFeeForMweb with mweb disabled for $walletId ${info.name}",
      );
    }
    throw UnimplementedError();
  }

  Future<TxData> prepareSendMweb({required TxData txData}) async {
    if (!info.isMwebEnabled) {
      throw Exception(
        "Tried calling prepareSendMweb with mweb disabled for $walletId ${info.name}",
      );
    }
    if (!txData.isMweb) {
      throw Exception("Invalid mweb flagged tx data");
    }

    final client = await _client;

    final response = await client.create(
      CreateRequest(
        rawTx: txData.raw!.toUint8ListFromHex,
        scanSecret: await _scanSecret,
        spendSecret: await _spendSecret,
        feeRatePerKb: Int64(txData.feeRateAmount!.toInt()),
        dryRun: false,
      ),
    );

    return txData.copyWith(raw: Uint8List.fromList(response.rawTx).toHex);
  }

  Future<TxData> confirmSendMweb({required TxData txData}) async {
    if (!info.isMwebEnabled) {
      throw Exception(
        "Tried calling confirmSendMweb with mweb disabled for $walletId ${info.name}",
      );
    }

    try {
      Logging.instance.d("confirmSend txData: $txData");

      final txHash = await electrumXClient.broadcastTransaction(
        rawTx: txData.raw!,
      );
      Logging.instance.d("Sent txHash: $txHash");

      txData = txData.copyWith(txHash: txHash, txid: txHash);

      // Update used mweb utxos as used in database. They should already have
      // been marked as isUsed.
      if (txData.usedMwebUtxos != null && txData.usedMwebUtxos!.isNotEmpty) {
        final db = Drift.get(walletId);
        await db.transaction(() async {
          for (final utxo in txData.usedMwebUtxos!) {
            await db
                .into(db.mwebUtxos)
                .insertOnConflictUpdate(utxo.toCompanion(false));
          }
        });
      } else {
        Logging.instance.w(
          "txData.usedMwebUtxos is empty or null when it very "
          "likely should not be!",
        );
      }

      return await updateSentCachedTxData(txData: txData);
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from confirmSendMweb(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Should only be called within the standard wallet [recover] function due to
  /// mutex locking. Otherwise behaviour MAY be undefined.
  Future<void> recoverMweb() async {
    if (!info.isMwebEnabled) {
      Logging.instance.e(
        "Tried calling recoverMweb with mweb disabled for $walletId ${info.name}",
      );
      return;
    }

    throw UnimplementedError();
  }

  Future<void> anonymizeAllMweb() async {
    if (!info.isMwebEnabled) {
      Logging.instance.e(
        "Tried calling anonymizeAllMweb with mweb disabled for $walletId ${info.name}",
      );
      return;
    }

    try {
      final currentHeight = await chainHeight;

      final spendableUtxos =
          await mainDB.isar.utxos
              .where()
              .walletIdEqualTo(walletId)
              .filter()
              .isBlockedEqualTo(false)
              .and()
              .group((q) => q.usedEqualTo(false).or().usedIsNull())
              .and()
              .valueGreaterThan(0)
              .findAll();

      spendableUtxos.removeWhere(
        (e) =>
            !e.isConfirmed(
              currentHeight,
              cryptoCurrency.minConfirms,
              cryptoCurrency.minCoinbaseConfirms,
            ),
      );

      if (spendableUtxos.isEmpty) {
        throw Exception("No available UTXOs found to anonymize");
      }

      // TODO finish
      final txData = await prepareSendMweb(
        txData: TxData(utxos: spendableUtxos.toSet()),
      );

      await confirmSendMweb(txData: txData);
    } catch (e, s) {
      Logging.instance.w(
        "Exception caught in anonymizeAllMweb(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // ===========================================================================

  @override
  Future<void> init() async {
    if (info.isMwebEnabled) {
      try {
        await _initMweb();
        Address? address = await getCurrentReceivingMwebAddress();
        if (address == null) {
          address = await generateNextMwebAddress();
          await mainDB.putAddress(address);
        }

        unawaited(_startUpdateMwebUtxos());
      } catch (e, s) {
        // do nothing, still allow user into wallet
        Logging.instance.e(
          "$runtimeType init() failed",
          error: e,
          stackTrace: s,
        );
      }
    }

    // await info.updateReceivingAddress(
    //   newAddress: address.value,
    //   isar: mainDB.isar,
    // );

    await super.init();
  }

  @override
  Future<void> updateBalance() async {
    // call to super to update transparent balance
    final normalBalanceFuture = super.updateBalance();

    if (info.isMwebEnabled) {
      final start = DateTime.now();
      try {
        final currentHeight = await chainHeight;
        final db = Drift.get(walletId);
        final mwebUtxos =
            await (db.select(db.mwebUtxos)
              ..where((e) => e.used.equals(false))).get();

        Amount satoshiBalanceTotal = Amount(
          rawValue: BigInt.zero,
          fractionDigits: cryptoCurrency.fractionDigits,
        );
        Amount satoshiBalancePending = Amount(
          rawValue: BigInt.zero,
          fractionDigits: cryptoCurrency.fractionDigits,
        );
        Amount satoshiBalanceSpendable = Amount(
          rawValue: BigInt.zero,
          fractionDigits: cryptoCurrency.fractionDigits,
        );
        Amount satoshiBalanceBlocked = Amount(
          rawValue: BigInt.zero,
          fractionDigits: cryptoCurrency.fractionDigits,
        );

        for (final utxo in mwebUtxos) {
          final utxoAmount = Amount(
            rawValue: BigInt.from(utxo.value),
            fractionDigits: cryptoCurrency.fractionDigits,
          );

          satoshiBalanceTotal += utxoAmount;

          if (utxo.blocked) {
            satoshiBalanceBlocked += utxoAmount;
          } else {
            if (utxo.isConfirmed(
              currentHeight,
              cryptoCurrency.minConfirms,
              // overrideMinConfirms: TODO: set this???
            )) {
              satoshiBalanceSpendable += utxoAmount;
            } else {
              satoshiBalancePending += utxoAmount;
            }
          }
        }

        final balance = Balance(
          total: satoshiBalanceTotal,
          spendable: satoshiBalanceSpendable,
          blockedTotal: satoshiBalanceBlocked,
          pendingSpendable: satoshiBalancePending,
        );

        await info.updateBalanceSecondary(
          newBalance: balance,
          isar: mainDB.isar,
        );
      } catch (e, s) {
        Logging.instance.e(
          "$runtimeType updateBalance mweb $walletId ${info.name}: ",
          error: e,
          stackTrace: s,
        );
      } finally {
        Logging.instance.d(
          "${info.name} updateBalance mweb duration:"
          " ${DateTime.now().difference(start)}",
        );
      }
    }

    // wait for normalBalanceFuture to complete before returning
    await normalBalanceFuture;
  }

  @override
  Future<void> refresh() async {
    if (isViewOnly || !info.isMwebEnabled) {
      await super.refresh();
      return;
    }

    // Awaiting this lock could be dangerous.
    // Since refresh is periodic (generally)
    if (refreshMutex.isLocked) {
      return;
    }

    // TODO

    // final node = getCurrentNode();
    //
    // if (_torNodeMismatchGuard(node)) {
    //   throw Exception("TOR – clearnet mismatch");
    // }
    //
    // // this acquire should be almost instant due to above check.
    // // Slight possibility of race but should be irrelevant
    // await refreshMutex.acquire();
    //
    // libMoneroWallet?.startSyncing();
    // _setSyncStatus(lib_monero_compat.StartingSyncStatus());
    //
    // await updateTransactions();
    // await updateBalance();
    //
    // if (info.otherData[WalletInfoKeys.reuseAddress] != true) {
    //   await checkReceivingAddressForTransactions();
    // }
    //
    // if (refreshMutex.isLocked) {
    //   refreshMutex.release();
    // }
    //
    // final synced = await libMoneroWallet?.isSynced();
    //
    // if (synced == true) {
    //   _setSyncStatus(lib_monero_compat.SyncedSyncStatus());
    // }
  }

  @override
  Future<void> exit() async {
    _mwebdPolling?.cancel();
    _mwebdPolling = null;
    await super.exit();
  }
}
