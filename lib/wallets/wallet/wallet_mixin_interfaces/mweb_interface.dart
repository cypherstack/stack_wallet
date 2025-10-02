import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:coinlib_flutter/coinlib_flutter.dart' as cl;
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:isar_community/isar.dart';
import 'package:mweb_client/mweb_client.dart';

import '../../../db/drift/database.dart';
import '../../../models/balance.dart';
import '../../../models/input.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../services/event_bus/events/global/blocks_remaining_event.dart';
import '../../../services/event_bus/events/global/refresh_percent_changed_event.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../services/mwebd_service.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/enums/fee_rate_type_enum.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../isar/models/wallet_info.dart';
import '../../models/tx_data.dart';
import '../intermediate/external_wallet.dart';
import 'electrumx_interface.dart';

mixin MwebInterface<T extends ElectrumXCurrencyInterface>
    on ElectrumXInterface<T>
    implements ExternalWallet<T> {
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
        .and()
        .subTypeEqualTo(AddressSubType.receiving)
        .sortByDerivationIndexDesc()
        .findFirst();
  }

  Future<Address?> getMwebChangeAddress() async {
    return await mainDB.isar.addresses
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .typeEqualTo(AddressType.mweb)
        .and()
        .subTypeEqualTo(AddressSubType.change)
        .and()
        .derivationIndexEqualTo(0)
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

  WalletSyncStatus? _syncStatusMwebCache;
  WalletSyncStatus? get _syncStatusMweb => _syncStatusMwebCache;
  set _syncStatusMweb(WalletSyncStatus? newValue) {
    switch (newValue) {
      case null:
        doNotFireRefreshEvents = true;
      case WalletSyncStatus.unableToSync:
        doNotFireRefreshEvents = true;
      case WalletSyncStatus.synced:
        doNotFireRefreshEvents = false;
      case WalletSyncStatus.syncing:
        doNotFireRefreshEvents = true;
    }

    _syncStatusMwebCache = newValue;
  }

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

        Logging.instance.t(
          "$walletId ${info.name} _polling mwebd status: $status",
        );

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
          syncStatus = WalletSyncStatus.synced;
        }

        _syncStatusMweb = syncStatus;
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(syncStatus, walletId, info.coin),
        );
      } catch (e, s) {
        Logging.instance.e(
          "mweb wallet polling error",
          error: e,
          stackTrace: s,
        );
        _syncStatusMweb = WalletSyncStatus.unableToSync;
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(_syncStatusMweb!, walletId, info.coin),
        );
      }
    });
  }

  Future<void> _stopUpdateMwebUtxos() async =>
      await _mwebUtxoSubscription?.cancel();

  Future<void> _startUpdateMwebUtxos() async {
    await _stopUpdateMwebUtxos();

    final client = await _client;

    Logging.instance.i("info.restoreHeight: ${info.restoreHeight}");
    Logging.instance.i(
      "info.otherData[WalletInfoKeys.mwebScanHeight]: ${info.otherData[WalletInfoKeys.mwebScanHeight]}",
    );
    final fromHeight =
        info.otherData[WalletInfoKeys.mwebScanHeight] as int? ??
        info.restoreHeight;

    final request = UtxosRequest(
      fromHeight: fromHeight,
      scanSecret: await _scanSecret,
    );

    final db = Drift.get(walletId);
    _mwebUtxoSubscription = (await client.utxos(request)).listen((utxo) async {
      Logging.instance.t(
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

            if (prev == null) {
              final newUtxo = MwebUtxosCompanion(
                outputId: Value(utxo.outputId),
                address: Value(utxo.address),
                value: Value(utxo.value.toInt()),
                height: Value(utxo.height),
                blockTime: Value(utxo.blockTime),
                blocked: const Value(false),
                used: const Value(false),
              );

              await db.into(db.mwebUtxos).insert(newUtxo);
            } else {
              await db
                  .update(db.mwebUtxos)
                  .replace(
                    prev.copyWith(
                      blockTime: utxo.blockTime,
                      height: utxo.height,
                    ),
                  );
            }
          });

          Address? addr = await mainDB.getAddress(walletId, utxo.address);
          while (addr == null || addr.value != utxo.address) {
            addr = await generateNextMwebAddress();
            await mainDB.updateOrPutAddresses([addr]);
          }

          // TODO get real txid one day
          final fakeTxid = "mweb_outputId_${utxo.outputId}";

          final tx = TransactionV2(
            walletId: walletId,
            blockHash: null, // ??
            hash: "",
            txid: fakeTxid,
            timestamp:
                utxo.height < 1
                    ? DateTime.now().millisecondsSinceEpoch ~/ 1000
                    : utxo.blockTime,
            height: utxo.height,
            inputs: [],
            outputs: [
              OutputV2.isarCantDoRequiredInDefaultConstructor(
                scriptPubKeyHex: "",
                valueStringSats: utxo.value.toString(),
                addresses: [utxo.address],
                walletOwns: true,
              ),
            ],
            version: 2, // probably
            type: TransactionType.incoming,
            subType: TransactionSubType.mweb,
            otherData: jsonEncode({
              TxV2OdKeys.overrideFee:
                  Amount(
                    rawValue:
                        BigInt
                            .zero, // TODO fill in correctly when we have a real txid
                    fractionDigits: cryptoCurrency.fractionDigits,
                  ).toJsonString(),
            }),
          );

          await mainDB.updateOrPutTransactionV2s([tx]);

          await updateBalance();

          if (utxo.height > fromHeight) {
            await info.updateOtherData(
              newEntries: {WalletInfoKeys.mwebScanHeight: utxo.height},
              isar: mainDB.isar,
            );
          }
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
        await MwebdService.instance.initService(cryptoCurrency.network);
      }

      _startPollingMwebd();
    } catch (e, s) {
      Logging.instance.e("testing initMweb failed", error: e, stackTrace: s);
    }
  }

  /// [isChange] will always return the change address at index 0 !!!!!
  Future<Address> generateNextMwebAddress({bool isChange = false}) async {
    if (!info.isMwebEnabled) {
      throw Exception(
        "Tried calling generateNextMwebAddress with mweb disabled for $walletId ${info.name}",
      );
    }

    final int nextIndex;
    if (isChange) {
      nextIndex = 0;
    } else {
      final highestStoredIndex =
          (await getCurrentReceivingMwebAddress())?.derivationIndex ?? 0;

      nextIndex = highestStoredIndex + 1;
    }

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
      subType: isChange ? AddressSubType.change : AddressSubType.receiving,
    );
  }

  Future<void> checkMwebSpends() async {
    final pending =
        await mainDB.isar.transactionV2s
            .where()
            .walletIdEqualTo(walletId)
            .filter()
            .heightIsNull()
            .and()
            .blockHashIsNull()
            .and()
            .subTypeEqualTo(TransactionSubType.mweb)
            .and()
            .typeEqualTo(TransactionType.outgoing)
            .findAll();

    Logging.instance.f(pending);

    final client = await _client;
    for (final tx in pending) {
      for (final input in tx.inputs) {
        if (input.addresses.length == 1) {
          final address = await mainDB.getAddress(
            walletId,
            input.addresses.first,
          );
          if (address?.type == AddressType.mweb) {
            final response = await client.spent(
              SpentRequest(outputId: [input.outpoint!.txid]),
            );
            if (response.outputId.contains(input.outpoint!.txid)) {
              // dummy to show tx as confirmed. Need a better way to handle this as its kind of stupid, resulting in terrible UX
              final dummyHeight = await chainHeight;

              TransactionV2? transaction =
                  await mainDB.isar.transactionV2s
                      .where()
                      .txidWalletIdEqualTo(tx.txid, walletId)
                      .findFirst();

              if (transaction == null || transaction.height == null) {
                transaction = (transaction ?? tx).copyWith(height: dummyHeight);
                await mainDB.updateOrPutTransactionV2s([transaction]);
              }
            }
          }
        }
      }
    }
  }

  Future<TxData> processMwebTransaction(TxData txData) async {
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

    if (txData.type == TxType.mwebPegIn) {
      cl.Transaction clTx = cl.Transaction.fromBytes(
        Uint8List.fromList(response.rawTx),
      );

      assert(response.rawTx.toString() == clTx.toBytes().toList().toString());
      final List<cl.Output> prevOuts = [];

      for (int i = 0; i < txData.usedUTXOs!.length; i++) {
        final data = txData.usedUTXOs![i];
        if (data is StandardInput) {
          final prevOutput = cl.Output.fromAddress(
            BigInt.from(data.utxo.value),
            cl.Address.fromString(
              data.utxo.address!,
              cryptoCurrency.networkParams,
            ),
          );

          prevOuts.add(prevOutput);
        }
      }

      for (int i = 0; i < txData.usedUTXOs!.length; i++) {
        final data = txData.usedUTXOs![i];

        if (data is MwebInput) {
          // do nothing
        } else if (data is StandardInput) {
          final value = BigInt.from(data.utxo.value);
          final key = data.key!.privateKey!;
          if (clTx.inputs[i] is cl.TaprootKeyInput) {
            final taproot = cl.Taproot(internalKey: data.key!.publicKey);

            clTx = clTx.signTaproot(
              inputN: i,
              key: taproot.tweakPrivateKey(key),
              prevOuts: prevOuts,
            );
          } else if (clTx.inputs[i] is cl.LegacyWitnessInput) {
            clTx = clTx.signLegacyWitness(inputN: i, key: key, value: value);
          } else if (clTx.inputs[i] is cl.LegacyInput) {
            clTx = clTx.signLegacy(inputN: i, key: key);
          } else if (clTx.inputs[i] is cl.TaprootSingleScriptSigInput) {
            clTx = clTx.signTaprootSingleScriptSig(
              inputN: i,
              key: key,
              prevOuts: prevOuts,
            );
          } else {
            throw Exception(
              "Unable to sign input of type ${clTx.inputs[i].runtimeType}",
            );
          }
        } else {
          throw Exception("Unknown input type: ${data.runtimeType}");
        }
      }
      return txData.copyWith(raw: clTx.toHex());
    } else {
      return txData.copyWith(raw: Uint8List.fromList(response.rawTx).toHex);
    }
  }

  Future<TxData> _confirmSendMweb({required TxData txData}) async {
    if (!info.isMwebEnabled) {
      throw Exception(
        "Tried calling _confirmSendMweb with mweb disabled for $walletId ${info.name}",
      );
    }

    try {
      Logging.instance.d("_confirmSendMweb txData: $txData");

      final client = await _client;

      final response = await client.broadcast(
        BroadcastRequest(rawTx: txData.raw!.toUint8ListFromHex),
      );

      final txHash = response.txid;
      Logging.instance.d("Sent txHash: $txHash");

      txData = txData.copyWith(
        usedUTXOs:
            txData.usedUTXOs!.map((e) {
              if (e is StandardInput) {
                return StandardInput(
                  e.utxo.copyWith(used: true),
                  derivePathType: e.derivePathType,
                );
              } else if (e is MwebInput) {
                return MwebInput(e.utxo.copyWith(used: true));
              } else {
                return e;
              }
            }).toList(),
        txHash: txHash,
        txid: txHash,
      );

      // mark utxos as used
      await mainDB.putUTXOs(
        txData.usedUTXOs!
            .whereType<StandardInput>()
            .map((e) => e.utxo)
            .toList(),
      );

      // Update used mweb utxos as used in database
      final usedMwebUtxos =
          txData.usedUTXOs!.whereType<MwebInput>().map((e) => e.utxo).toList();

      Logging.instance.i("Used mweb inputs: $usedMwebUtxos");

      if (usedMwebUtxos.isNotEmpty) {
        final db = Drift.get(walletId);
        await db.transaction(() async {
          for (final used in usedMwebUtxos) {
            await db.update(db.mwebUtxos).replace(used);
          }
        });
      }

      return await updateSentCachedTxData(txData: txData);
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from _confirmSendMweb(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<TxData> prepareSend({required TxData txData}) async {
    final hasMwebOutputs =
        txData.recipients!
            .where((e) => e.addressType == AddressType.mweb)
            .isNotEmpty;
    if (hasMwebOutputs) {
      // assume pegin tx
      txData = txData.copyWith(type: TxType.mwebPegIn);
    }

    return super.prepareSend(txData: txData);
  }

  /// prepare mweb transaction where spending mweb outputs
  Future<TxData> prepareSendMweb({required TxData txData}) async {
    final hasMwebOutputs =
        txData.recipients!
            .where((e) => e.addressType == AddressType.mweb)
            .isNotEmpty;

    final type = hasMwebOutputs ? TxType.mweb : TxType.mwebPegOut;

    txData = txData.copyWith(type: type);

    return super.prepareSend(txData: txData);
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

      final amount = spendableUtxos.fold(
        Amount.zeroWith(fractionDigits: cryptoCurrency.fractionDigits),
        (p, e) =>
            p +
            Amount(
              rawValue: BigInt.from(e.value),
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
      );

      // TODO finish
      final txData = await prepareSend(
        txData: TxData(
          type: TxType.mwebPegIn,
          feeRateType: FeeRateType.average,
          recipients: [
            TxRecipient(
              address: (await getCurrentReceivingMwebAddress())!.value,
              amount: amount,
              isChange: false,
              addressType: AddressType.mweb,
            ),
          ],
        ),
      );

      await _confirmSendMweb(txData: txData);
    } catch (e, s) {
      Logging.instance.w(
        "Exception caught in anonymizeAllMweb(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<void> _checkAddresses() async {
    // check change first as it is index 0
    Address? changeAddress = await getMwebChangeAddress();
    if (changeAddress == null) {
      changeAddress = await generateNextMwebAddress(isChange: true);
      await mainDB.putAddress(changeAddress);
    }

    // check recieving
    Address? address = await getCurrentReceivingMwebAddress();
    if (address == null) {
      address = await generateNextMwebAddress();
      await mainDB.putAddress(address);
    }
  }

  // ===========================================================================

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    if (txData.type.isMweb()) {
      return await _confirmSendMweb(txData: txData);
    } else {
      return await super.confirmSend(txData: txData);
    }
  }

  @override
  Future<void> open() async {
    if (info.isMwebEnabled) {
      try {
        await _initMweb();

        await _checkAddresses();

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
  Future<void> recover({required bool isRescan}) async {
    if (isViewOnly) {
      await recoverViewOnly(isRescan: isRescan);
      return;
    }

    final start = DateTime.now();
    final root = await getRootHDNode();

    final List<Future<({int index, List<Address> addresses})>> receiveFutures =
        [];
    final List<Future<({int index, List<Address> addresses})>> changeFutures =
        [];

    const receiveChain = 0;
    const changeChain = 1;

    const txCountBatchSize = 12;

    try {
      await refreshMutex.protect(() async {
        if (isRescan) {
          await _stopUpdateMwebUtxos();

          // clear cache
          await electrumXCachedClient.clearSharedTransactionCache(
            cryptoCurrency: info.coin,
          );
          // clear blockchain info
          await mainDB.deleteWalletBlockchainData(walletId);

          // reset scan/listen height
          await info.updateOtherData(
            newEntries: {WalletInfoKeys.mwebScanHeight: info.restoreHeight},
            isar: mainDB.isar,
          );

          // reset balance to 0
          await info.updateBalanceSecondary(
            newBalance: Balance.zeroFor(currency: cryptoCurrency),
            isar: mainDB.isar,
          );

          // clear all mweb utxos
          final db = Drift.get(walletId);
          await db.transaction(() async => await db.delete(db.mwebUtxos).go());

          if (info.isMwebEnabled) {
            await _checkAddresses();

            // only restart scanning if mweb enabled
            unawaited(_startUpdateMwebUtxos());
          }
        }

        // receiving addresses
        Logging.instance.i("checking receiving addresses...");

        final canBatch = await serverCanBatch;

        for (final type in cryptoCurrency.supportedDerivationPathTypes) {
          receiveFutures.add(
            canBatch
                ? checkGapsBatched(txCountBatchSize, root, type, receiveChain)
                : checkGapsLinearly(root, type, receiveChain),
          );
        }

        // change addresses
        Logging.instance.d("checking change addresses...");
        for (final type in cryptoCurrency.supportedDerivationPathTypes) {
          changeFutures.add(
            canBatch
                ? checkGapsBatched(txCountBatchSize, root, type, changeChain)
                : checkGapsLinearly(root, type, changeChain),
          );
        }

        // io limitations may require running these linearly instead
        final futuresResult = await Future.wait([
          Future.wait(receiveFutures),
          Future.wait(changeFutures),
        ]);

        final receiveResults = futuresResult[0];
        final changeResults = futuresResult[1];

        final List<Address> addressesToStore = [];

        int highestReceivingIndexWithHistory = 0;

        for (final tuple in receiveResults) {
          if (tuple.addresses.isEmpty) {
            if (info.otherData[WalletInfoKeys.reuseAddress] != true) {
              await checkReceivingAddressForTransactions();
            }
          } else {
            highestReceivingIndexWithHistory = math.max(
              tuple.index,
              highestReceivingIndexWithHistory,
            );
            addressesToStore.addAll(tuple.addresses);
          }
        }

        int highestChangeIndexWithHistory = 0;
        // If restoring a wallet that never sent any funds with change, then set changeArray
        // manually. If we didn't do this, it'd store an empty array.
        for (final tuple in changeResults) {
          if (tuple.addresses.isEmpty) {
            await checkChangeAddressForTransactions();
          } else {
            highestChangeIndexWithHistory = math.max(
              tuple.index,
              highestChangeIndexWithHistory,
            );
            addressesToStore.addAll(tuple.addresses);
          }
        }

        // remove extra addresses to help minimize risk of creating a large gap
        addressesToStore.removeWhere(
          (e) =>
              e.subType == AddressSubType.change &&
              e.derivationIndex > highestChangeIndexWithHistory,
        );
        addressesToStore.removeWhere(
          (e) =>
              e.subType == AddressSubType.receiving &&
              e.derivationIndex > highestReceivingIndexWithHistory,
        );

        await mainDB.updateOrPutAddresses(addressesToStore);
      });

      unawaited(refresh());
      Logging.instance.i(
        "Mweb recover for "
        "${info.name}: ${DateTime.now().difference(start)}",
      );
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from mweb_interface recover(): ",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> exit() async {
    _mwebdPolling?.cancel();
    _mwebdPolling = null;
    await super.exit();
  }

  bool isMwebAddress(String address) {
    try {
      cl.MwebAddress.fromString(address, network: cryptoCurrency.networkParams);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Amount> mwebFee({required TxData txData}) async {
    final outputs = txData.recipients!;
    final utxos = txData.usedUTXOs!;

    final sumOfUtxosValue = utxos.fold(BigInt.zero, (p, e) => p + e.value);

    final preOutputSum = outputs.fold(BigInt.zero, (p, e) => p + e.amount.raw);
    final fee = sumOfUtxosValue - preOutputSum;

    final client = await _client;

    final resp = await client.create(
      CreateRequest(
        rawTx: txData.raw!.toUint8ListFromHex,
        scanSecret: await _scanSecret,
        spendSecret: await _spendSecret,
        feeRatePerKb: Int64(txData.feeRateAmount!.toInt()),
        dryRun: true,
      ),
    );

    final processedTx = cl.Transaction.fromBytes(
      Uint8List.fromList(resp.rawTx),
    );

    BigInt maxBI(BigInt a, BigInt b) => a > b ? a : b;
    final posUtxos =
        utxos
            .where(
              (utxo) => processedTx.inputs.any(
                (input) =>
                    input.prevOut.hash.toHex ==
                    Uint8List.fromList(
                      utxo.id.toUint8ListFromHex.reversed.toList(),
                    ).toHex,
              ),
            )
            .toList();

    final posOutputSum = processedTx.outputs.fold(
      BigInt.zero,
      (acc, output) => acc + output.value,
    );
    final mwebInputSum =
        sumOfUtxosValue - posUtxos.fold(BigInt.zero, (p, e) => p + e.value);
    final expectedPegin = maxBI(BigInt.zero, (preOutputSum - mwebInputSum));
    BigInt feeIncrease = posOutputSum - expectedPegin;

    if (expectedPegin > BigInt.zero) {
      feeIncrease +=
          BigInt.from((txData.feeRateAmount! / BigInt.from(1000)).ceil()) *
          BigInt.from(41);
    }

    // bandaid: add one to account for a rounding error that happens sometimes
    return Amount(
      rawValue: fee + feeIncrease + BigInt.one,
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }
}
