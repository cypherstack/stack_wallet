import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stack_wallet_backup/generate_password.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;
import 'package:xelis_flutter/src/api/wallet.dart' as x_wallet;

import '../../../models/balance.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/stack_file_system.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../intermediate/lib_xelis_wallet.dart';
import '../wallet.dart';

class XelisWallet extends LibXelisWallet {
  Completer<void>? _initCompleter;

  XelisWallet(CryptoCurrencyNetwork network) : super(Xelis(network));
  // ==================== Overrides ============================================

  @override
  int get isarTransactionVersion => 2;

  Future<void> _restoreWallet() async {
    final tablePath = await getPrecomputedTablesPath();
    final tableState = await getTableState();
    final xelisDir = await StackFileSystem.applicationXelisDirectory();
    final String name = walletId;
    final String directory = xelisDir.path;
    final password = await secureStorageInterface.read(
      key: Wallet.mnemonicPassphraseKey(walletId: info.walletId),
    );

    final mnemonic = await getMnemonic();
    final seedLength = mnemonic.trim().split(" ").length;

    invalidSeedLengthCheck(seedLength);

    Logging.instance.i("Xelis: recovering wallet");
    final wallet = await x_wallet.createXelisWallet(
      name: name,
      directory: directory,
      password: password!,
      seed: mnemonic.trim(),
      network: cryptoCurrency.network.xelisNetwork,
      precomputedTablesPath: tablePath,
      l1Low: tableState.currentSize.isLow,
    );

    await secureStorageInterface.write(
      key: Wallet.mnemonicKey(walletId: walletId),
      value: mnemonic.trim(),
    );

    libXelisWallet = wallet;

    await _finishInit();
  }

  Future<void> _createNewWallet() async {
    final tablePath = await getPrecomputedTablesPath();
    final tableState = await getTableState();
    final xelisDir = await StackFileSystem.applicationXelisDirectory();
    final String name = walletId;
    final String directory = xelisDir.path;
    final String password = generatePassword();

    Logging.instance.d("Xelis: storing password");
    await secureStorageInterface.write(
      key: Wallet.mnemonicPassphraseKey(walletId: info.walletId),
      value: password,
    );

    final wallet = await x_wallet.createXelisWallet(
      name: name,
      directory: directory,
      password: password,
      network: cryptoCurrency.network.xelisNetwork,
      precomputedTablesPath: tablePath,
      l1Low: tableState.currentSize.isLow,
    );

    final mnemonic = await wallet.getSeed();
    await secureStorageInterface.write(
      key: Wallet.mnemonicKey(walletId: walletId),
      value: mnemonic.trim(),
    );

    libXelisWallet = wallet;

    await _finishInit();
  }

  Future<void> _existingWallet() async {
    Logging.instance.i("Xelis: opening existing wallet");
    final tablePath = await getPrecomputedTablesPath();
    final tableState = await getTableState();
    final xelisDir = await StackFileSystem.applicationXelisDirectory();
    final String name = walletId;
    final String directory = xelisDir.path;
    final password = await secureStorageInterface.read(
      key: Wallet.mnemonicPassphraseKey(walletId: info.walletId),
    );

    libXelisWallet = await x_wallet.openXelisWallet(
      name: name,
      directory: directory,
      password: password!,
      network: cryptoCurrency.network.xelisNetwork,
      precomputedTablesPath: tablePath,
      l1Low: tableState.currentSize.isLow,
    );

    await _finishInit();
  }

  Future<void> _finishInit() async {
    if (await isTableUpgradeAvailable()) {
      unawaited(updateTablesToDesiredSize());
    }

    final newReceivingAddress =
        await getCurrentReceivingAddress() ??
        Address(
          walletId: walletId,
          derivationIndex: 0,
          derivationPath: null,
          value: libXelisWallet!.getAddressStr(),
          publicKey: [],
          type: AddressType.xelis,
          subType: AddressSubType.receiving,
        );

    await mainDB.updateOrPutAddresses([newReceivingAddress]);

    if (info.cachedReceivingAddress != newReceivingAddress.value) {
      await info.updateReceivingAddress(
        newAddress: newReceivingAddress.value,
        isar: mainDB.isar,
      );
    }
  }

  @override
  Future<void> init({bool? isRestore}) async {
    Logging.instance.d("Xelis: init");

    if (_initCompleter != null) {
      await _initCompleter!.future;
      return super.init();
    }

    _initCompleter = Completer<void>();

    try {
      final bool walletExists = await LibXelisWallet.checkWalletExists(
        walletId,
      );

      if (libXelisWallet == null) {
        if (isRestore == true) {
          await _restoreWallet();
        } else {
          if (!walletExists) {
            await _createNewWallet();
          } else {
            await _existingWallet();
          }
        }
      }
      _initCompleter!.complete();
    } catch (e, s) {
      _initCompleter!.completeError(e);
      Logging.instance.e(
        "Xelis init() rethrowing error",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }

    return super.init();
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    if (isRescan) {
      await refreshMutex.protect(() async {
        await mainDB.deleteWalletBlockchainData(walletId);
        await updateTransactions(isRescan: true, topoheight: 0);
      });
      return;
    }

    // Borrowed from libmonero for now, need to refactor for Xelis view keys
    // if (isViewOnly) {
    //   await recoverViewOnly();
    //   return;
    // }

    try {
      await open();
    } catch (e, s) {
      Logging.instance.e(
        "Error rethrown from $runtimeType recover(isRescan: $isRescan)",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<bool> pingCheck() async {
    try {
      await libXelisWallet!.getDaemonInfo();
      await handleOnline();
      return true;
    } catch (_) {
      await handleOffline();
      return false;
    }
  }

  final _balanceUpdateMutex = Mutex();

  @override
  Future<void> updateBalance({int? newBalance}) async {
    await _balanceUpdateMutex.protect(() async {
      try {
        if (await libXelisWallet!.hasXelisBalance()) {
          final BigInt xelBalance =
              newBalance != null
                  ? BigInt.from(newBalance)
                  : await libXelisWallet!
                      .getXelisBalanceRaw(); // in the future, use getAssetBalances and handle each
          final balance = Balance(
            total: Amount(
              rawValue: xelBalance,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            spendable: Amount(
              rawValue: xelBalance,
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            blockedTotal: Amount.zeroWith(
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
            pendingSpendable: Amount.zeroWith(
              fractionDigits: cryptoCurrency.fractionDigits,
            ),
          );
          await info.updateBalance(newBalance: balance, isar: mainDB.isar);
        }
      } catch (e, s) {
        Logging.instance.e(
          "Error in $runtimeType updateBalance()",
          error: e,
          stackTrace: s,
        );
      }
    });
  }

  Future<int> _fetchChainHeight() async {
    final infoString = await libXelisWallet!.getDaemonInfo();
    final Map<String, dynamic> nodeInfo =
        (json.decode(infoString) as Map).cast();

    pruningHeight =
        int.tryParse(nodeInfo['pruned_topoheight']?.toString() ?? '0') ?? 0;
    return int.parse(nodeInfo['topoheight'].toString());
  }

  @override
  Future<void> updateChainHeight({int? topoheight}) async {
    try {
      final height = topoheight ?? await _fetchChainHeight();

      await info.updateCachedChainHeight(
        newHeight: height.toInt(),
        isar: mainDB.isar,
      );
    } catch (e, s) {
      Logging.instance.e(
        "Error in $runtimeType updateChainHeight()",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateNode() async {
    try {
      final bool online = await libXelisWallet!.isOnline();
      if (online == true) {
        await libXelisWallet!.offlineMode();
      }
      await super.connect();
    } catch (e, s) {
      Logging.instance.e(
        "Error rethrown from $runtimeType updateNode()",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<List<String>> updateTransactions({
    bool isRescan = false,
    List<String>? rawTransactions,
    int? topoheight,
  }) async {
    checkInitialized();

    final newReceivingAddress =
        await getCurrentReceivingAddress() ??
        Address(
          walletId: walletId,
          derivationIndex: 0,
          derivationPath: null,
          value: libXelisWallet!.getAddressStr(),
          publicKey: [],
          type: AddressType.xelis,
          subType: AddressSubType.receiving,
        );

    final thisAddress = newReceivingAddress.value;

    int firstBlock = 0;
    if (!isRescan) {
      firstBlock =
          await mainDB.isar.transactionV2s
              .where()
              .walletIdEqualTo(walletId)
              .heightProperty()
              .max() ??
          0;

      if (firstBlock > 10) {
        // add some buffer
        firstBlock -= 10;
      }
    } else {
      await libXelisWallet!.rescan(topoheight: BigInt.from(pruningHeight));
    }

    final txListJson = rawTransactions ?? await libXelisWallet!.allHistory();

    final List<TransactionV2> txns = [];

    for (final jsonString in txListJson) {
      try {
        final transactionEntry = xelis_sdk.TransactionEntry.fromJson(
          (json.decode(jsonString) as Map).cast(),
        );

        // Check for duplicates
        final storedTx =
            await mainDB.isar.transactionV2s
                .where()
                .txidWalletIdEqualTo(transactionEntry.hash, walletId)
                .findFirst();

        if (storedTx != null &&
            storedTx.height != null &&
            storedTx.height! > 0) {
          continue; // Skip already processed transactions
        }

        final List<OutputV2> outputs = [];
        final List<InputV2> inputs = [];
        TransactionType? txType;
        const TransactionSubType txSubType = TransactionSubType.none;
        int? nonce;
        Amount fee = Amount(
          rawValue: BigInt.zero,
          fractionDigits: cryptoCurrency.fractionDigits,
        );
        final Map<String, dynamic> otherData = {};

        final entryType = transactionEntry.txEntryType;

        if (entryType is xelis_sdk.CoinbaseEntry) {
          final coinbase = entryType;
          txType = TransactionType.incoming;

          final int decimals = await libXelisWallet!.getAssetDecimals(
            asset: xelis_sdk.xelisAsset,
          );

          fee = Amount(rawValue: BigInt.zero, fractionDigits: decimals);

          outputs.add(
            OutputV2.isarCantDoRequiredInDefaultConstructor(
              scriptPubKeyHex: "",
              valueStringSats: coinbase.reward.toString(),
              addresses: [thisAddress],
              walletOwns: true,
            ),
          );
        } else if (entryType is xelis_sdk.BurnEntry) {
          final burn = entryType;
          txType = TransactionType.outgoing;

          final int decimals = await libXelisWallet!.getAssetDecimals(
            asset: burn.asset,
          );

          fee = Amount(
            rawValue: BigInt.from(burn.fee),
            fractionDigits: decimals,
          );

          inputs.add(
            InputV2.isarCantDoRequiredInDefaultConstructor(
              scriptSigAsm: null,
              scriptSigHex: null,
              sequence: null,
              outpoint: null,
              valueStringSats: burn.amount.toString(),
              addresses: [thisAddress],
              witness: null,
              innerRedeemScriptAsm: null,
              coinbase: null,
              walletOwns: true,
            ),
          );

          outputs.add(
            OutputV2.isarCantDoRequiredInDefaultConstructor(
              scriptPubKeyHex: "",
              valueStringSats: burn.amount.toString(),
              addresses: ['burn'],
              walletOwns: false,
            ),
          );

          otherData['burnAsset'] = burn.asset;
        } else if (entryType is xelis_sdk.IncomingEntry) {
          final incoming = entryType;
          txType =
              incoming.from == thisAddress
                  ? TransactionType.sentToSelf
                  : TransactionType.incoming;

          for (final transfer in incoming.transfers) {
            final int decimals = await libXelisWallet!.getAssetDecimals(
              asset: transfer.asset,
            );

            fee = Amount(rawValue: BigInt.zero, fractionDigits: decimals);

            outputs.add(
              OutputV2.isarCantDoRequiredInDefaultConstructor(
                scriptPubKeyHex: "",
                valueStringSats: transfer.amount.toString(),
                addresses: [thisAddress],
                walletOwns: true,
              ),
            );

            otherData['asset_${transfer.asset}'] = transfer.amount.toString();
            if (transfer.extraData != null) {
              otherData['extraData_${transfer.asset}'] =
                  transfer.extraData!.toJson();
            }
          }
        } else if (entryType is xelis_sdk.OutgoingEntry) {
          final outgoing = entryType;
          txType = TransactionType.outgoing;
          nonce = outgoing.nonce;

          for (final transfer in outgoing.transfers) {
            final int decimals = await libXelisWallet!.getAssetDecimals(
              asset: transfer.asset,
            );

            fee = Amount(
              rawValue: BigInt.from(outgoing.fee),
              fractionDigits: decimals,
            );

            inputs.add(
              InputV2.isarCantDoRequiredInDefaultConstructor(
                scriptSigHex: null,
                scriptSigAsm: null,
                sequence: null,
                outpoint: null,
                addresses: [thisAddress],
                valueStringSats: (transfer.amount + outgoing.fee).toString(),
                witness: null,
                innerRedeemScriptAsm: null,
                coinbase: null,
                walletOwns: true,
              ),
            );

            outputs.add(
              OutputV2.isarCantDoRequiredInDefaultConstructor(
                scriptPubKeyHex: "",
                valueStringSats: transfer.amount.toString(),
                addresses: [transfer.destination],
                walletOwns: false,
              ),
            );

            otherData['asset_${transfer.asset}_amount'] =
                transfer.amount.toString();
            otherData['asset_${transfer.asset}_fee'] = fee.raw.toString();
            if (transfer.extraData != null) {
              otherData['extraData_${transfer.asset}'] =
                  transfer.extraData!.toJson();
            }
          }
        } else {
          // Skip unknown entry types
          continue;
        }

        final txn = TransactionV2(
          walletId: walletId,
          blockHash: "", // Not provided in Xelis data
          hash: transactionEntry.hash,
          txid: transactionEntry.hash,
          timestamp:
              (transactionEntry.timestamp?.millisecondsSinceEpoch ?? 0) ~/ 1000,
          height: transactionEntry.topoheight,
          inputs: List.unmodifiable(inputs),
          outputs: List.unmodifiable(outputs),
          version: -1, // Version not provided
          type: txType,
          subType: txSubType,
          otherData: jsonEncode({
            ...otherData,
            if (nonce != null) 'nonce': nonce,
            'overrideFee': fee.toJsonString(),
          }),
        );

        // Logging.instance.log(
        //   "Entry done ${entryType.toString()}",
        //   level: LogLevel.Debug,
        // );

        txns.add(txn);
      } catch (e, s) {
        Logging.instance.w(
          "Error in $runtimeType handling transaction: $jsonString",
          error: e,
          stackTrace: s,
        );
      }
    }
    await updateBalance();

    await mainDB.updateOrPutTransactionV2s(txns);
    return txns.map((e) => e.txid).toList();
  }

  @override
  Future<bool> updateUTXOs() async {
    // not used in xel
    return false;
  }

  @override
  Future<void> checkSaveInitialReceivingAddress() async {
    // do nothing
  }

  @override
  FilterOperation? get changeAddressFilterOperation =>
      throw UnimplementedError("Not used for $runtimeType");

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  @override
  Future<FeeObject> get fees async {
    // TODO: implement _getFees... maybe
    return FeeObject(
      numberOfBlocksFast: 10,
      numberOfBlocksAverage: 10,
      numberOfBlocksSlow: 10,
      fast: 1,
      medium: 1,
      slow: 1,
    );
  }

  @override
  Future<TxData> prepareSend({required TxData txData, String? assetId}) async {
    try {
      checkInitialized();

      final recipients =
          txData.recipients?.isNotEmpty == true
              ? txData.recipients!
              : throw ArgumentError(
                'Address cannot be empty.',
              ); // in the future, support for multiple recipients will work.

      final asset = assetId ?? xelis_sdk.xelisAsset;

      // Calculate total send amount
      final totalSendAmount = recipients.fold<Amount>(
        Amount(
          rawValue: BigInt.zero,
          fractionDigits: cryptoCurrency.fractionDigits,
        ),
        (sum, recipient) => sum + recipient.amount,
      );

      // Check balance using raw method
      final xelBalance = await libXelisWallet!.getXelisBalanceRaw();
      final balance = Amount(
        rawValue: xelBalance,
        fractionDigits: cryptoCurrency.fractionDigits,
      );

      // Estimate fee using the shared method
      final boostedFee = await estimateFeeFor(
        totalSendAmount,
        1,
        feeMultiplier: 1.0,
        recipients: recipients,
        assetId: asset,
      );

      // Check if we have enough for both transfers and fee
      if (totalSendAmount + boostedFee > balance) {
        final requiredAmt = await libXelisWallet!.formatCoin(
          atomicAmount: (totalSendAmount + boostedFee).raw,
          assetHash: asset,
        );

        final availableAmt = await libXelisWallet!.formatCoin(
          atomicAmount: xelBalance,
          assetHash: asset,
        );

        throw Exception(
          "Insufficient balance to cover transfers and fees. "
          "Required: $requiredAmt, Available: $availableAmt",
        );
      }

      return txData.copyWith(
        fee: boostedFee,
        otherData: jsonEncode({'asset': asset}),
      );
    } catch (_) {
      // Logging.instance.log(
      //   "Exception rethrown from prepareSend(): $e\n$s",
      //   level: LogLevel.Error,
      // );
      rethrow;
    }
  }

  @override
  Future<Amount> estimateFeeFor(
    Amount amount,
    int feeRate, {
    double? feeMultiplier,
    List<TxRecipient> recipients = const [],
    String? assetId,
  }) async {
    try {
      checkInitialized();
      final asset = assetId ?? xelis_sdk.xelisAsset;

      // Default values for a new wallet or when estimation fails
      final defaultDecimals = cryptoCurrency.fractionDigits;
      final defaultFee = BigInt.from(0);

      // Use default address if recipients list is empty to ensure basic fee estimates are readily available
      final effectiveRecipients =
          recipients.isNotEmpty
              ? recipients
              : [
                (
                  address:
                      'xel:xz9574c80c4xegnvurazpmxhw5dlg2n0g9qm60uwgt75uqyx3pcsqzzra9m',
                  amount: amount,
                  isChange: false,
                ),
              ];

      try {
        final transfers = await Future.wait(
          effectiveRecipients.map((recipient) async {
            try {
              final amt = double.parse(
                await libXelisWallet!.formatCoin(
                  atomicAmount: recipient.amount.raw,
                  assetHash: asset,
                ),
              );
              return x_wallet.Transfer(
                floatAmount: amt,
                strAddress: recipient.address,
                assetHash: asset,
                extraData: null,
              );
            } catch (e, s) {
              // Handle formatCoin error - use default conversion
              Logging.instance.d(
                "formatCoin failed, using fallback conversion",
                error: e,
                stackTrace: s,
              );
              final rawAmount = recipient.amount.raw;
              final floatAmount =
                  rawAmount / BigInt.from(10).pow(defaultDecimals);
              return x_wallet.Transfer(
                floatAmount: floatAmount.toDouble(),
                strAddress: recipient.address,
                assetHash: asset,
                extraData: null,
              );
            }
          }),
        );

        final decimals = await libXelisWallet!.getAssetDecimals(asset: asset);
        final estimatedFee = double.parse(
          await libXelisWallet!.estimateFees(transfers: transfers),
        );
        final rawFee = (estimatedFee * pow(10, decimals)).round();
        return Amount(
          rawValue: BigInt.from(rawFee),
          fractionDigits: cryptoCurrency.fractionDigits,
        );
      } catch (e, s) {
        Logging.instance.d(
          "Fee estimation failed. Using fallback fee: $defaultFee",
          error: e,
          stackTrace: s,
        );
        return Amount(
          rawValue: defaultFee,
          fractionDigits: cryptoCurrency.fractionDigits,
        );
      }
    } catch (_) {
      // Logging.instance.log(
      //   "Exception rethrown from estimateFeeFor(): $e\n$s",
      //   level: LogLevel.Error,
      // );
      rethrow;
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      checkInitialized();

      // Validate recipients
      if (txData.recipients == null || txData.recipients!.length != 1) {
        throw Exception("$runtimeType confirmSend requires 1 recipient");
      }

      final recipient = txData.recipients!.first;
      final Amount sendAmount = recipient.amount;

      final asset =
          (txData.otherData != null
                  ? jsonDecode(txData.otherData!)
                  : null)?['asset']
              as String? ??
          xelis_sdk.xelisAsset;

      final amt = double.parse(
        await libXelisWallet!.formatCoin(
          atomicAmount: sendAmount.raw,
          assetHash: asset,
        ),
      );

      // Create a transfer transaction
      final txJson = await libXelisWallet!.createTransfersTransaction(
        transfers: [
          x_wallet.Transfer(
            floatAmount: amt,
            strAddress: recipient.address,
            assetHash: asset,
            extraData: null, // Add extra data if needed
          ),
        ],
      );

      final txMap = jsonDecode(txJson);
      final txHash = txMap['hash'] as String;

      // Broadcast the transaction
      await libXelisWallet!.broadcastTransaction(txHash: txHash);

      return await updateSentCachedTxData(
        txData: txData.copyWith(txid: txHash),
      );
    } catch (_) {
      // Logging.instance.log(
      //   "Exception rethrown from confirmSend(): $e\n$s",
      //   level: LogLevel.Error,
      // );
      rethrow;
    }
  }

  @override
  Future<void> handleEvent(Event event) async {
    try {
      switch (event) {
        case NewTopoheight(:final height):
          await handleNewTopoHeight(height);
        case NewAsset(:final asset):
          await handleNewAsset(asset);
        case NewTransaction(:final transaction):
          await handleNewTransaction(transaction);
        case BalanceChanged(:final event):
          await handleBalanceChanged(event);
        case Rescan(:final startTopoheight):
          await handleRescan(startTopoheight);
        case Online():
          await handleOnline();
        case Offline():
          await handleOffline();
        case HistorySynced(:final topoheight):
          await handleHistorySynced(topoheight);
      }
    } catch (e, s) {
      Logging.instance.e(
        "Error in $runtimeType handleEvent($event)",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> handleNewTopoHeight(int height) async {
    await info.updateCachedChainHeight(newHeight: height, isar: mainDB.isar);
  }

  @override
  Future<void> handleNewTransaction(xelis_sdk.TransactionEntry tx) async {
    try {
      final txListJson = [jsonEncode(tx.toString())];
      final newTxIds = await updateTransactions(
        isRescan: false,
        rawTransactions: txListJson,
      );

      await updateBalance();

      // Logging.instance.log(
      //   "New transaction processed: ${newTxIds.first}",
      //   level: LogLevel.Info,
      // );
    } catch (e, s) {
      Logging.instance.e(
        "Error in $runtimeType handleNewTransaction($tx)",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> handleBalanceChanged(xelis_sdk.BalanceChangedEvent event) async {
    try {
      final asset = event.assetHash;
      if (asset == xelis_sdk.xelisAsset) {
        await updateBalance(newBalance: event.balance);
      }

      // TODO: Update asset balances if needed
    } catch (e, s) {
      Logging.instance.e(
        "Error in $runtimeType handleBalanceChanged($event)",
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> handleRescan(int startTopoheight) async {
    await refreshMutex.protect(() async {
      await mainDB.deleteWalletBlockchainData(walletId);
      await updateTransactions(isRescan: true, topoheight: startTopoheight);
      await updateBalance();
    });
  }

  @override
  Future<void> handleOnline() async {
    await updateChainHeight();
    await updateBalance();
    await updateTransactions();
    GlobalEventBus.instance.fire(
      WalletSyncStatusChangedEvent(
        WalletSyncStatus.synced,
        walletId,
        info.coin,
      ),
    );
    unawaited(refresh());
  }

  @override
  Future<void> handleOffline() async {
    GlobalEventBus.instance.fire(
      WalletSyncStatusChangedEvent(
        WalletSyncStatus.unableToSync,
        walletId,
        info.coin,
      ),
    );
  }

  @override
  Future<void> handleHistorySynced(int topoheight) async {
    await updateChainHeight();
    await updateBalance();
    await updateTransactions();
    GlobalEventBus.instance.fire(
      WalletSyncStatusChangedEvent(
        WalletSyncStatus.synced,
        walletId,
        info.coin,
      ),
    );
  }

  @override
  Future<void> handleNewAsset(xelis_sdk.AssetData asset) async {
    // TODO: Store asset information if needed
    // TODO: Update UI/state for new asset
    Logging.instance.d("New xelis asset detected: $asset");
  }

  @override
  Future<void> refresh({int? topoheight}) async {
    await refreshMutex.protect(() async {
      try {
        final bool online = await libXelisWallet!.isOnline();
        if (online == true) {
          await updateChainHeight(topoheight: topoheight);
          await updateBalance();
          await updateTransactions();
        } else {
          GlobalEventBus.instance.fire(
            WalletSyncStatusChangedEvent(
              WalletSyncStatus.unableToSync,
              walletId,
              info.coin,
            ),
          );
        }
      } catch (e, s) {
        Logging.instance.e(
          "Error in $runtimeType refresh()",
          error: e,
          stackTrace: s,
        );
      }
    });
  }
}
