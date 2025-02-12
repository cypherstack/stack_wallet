import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:xelis_flutter/src/api/network.dart' as x_network;
import 'package:xelis_flutter/src/api/wallet.dart' as x_wallet;
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../intermediate/lib_xelis_wallet.dart';

import '../../../utilities/stack_file_system.dart';
import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';

import '../../../services/event_bus/events/global/blocks_remaining_event.dart';
import '../../../services/event_bus/events/global/refresh_percent_changed_event.dart';
import '../../../services/event_bus/events/global/tor_connection_status_changed_event.dart';
import '../../../services/event_bus/events/global/tor_status_changed_event.dart';
import '../../../services/event_bus/events/global/updated_in_background_event.dart';
import '../../../services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import '../../../services/event_bus/global_event_bus.dart';

import '../../../models/node_model.dart';
import '../../../models/paymint/fee_object_model.dart';
import '../../../models/balance.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/logger.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../wallet.dart';

import '../../../providers/providers.dart';

import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stack_wallet_backup/generate_password.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../intermediate/lib_xelis_wallet.dart';

class XelisWallet extends LibXelisWallet {
  XelisWallet(CryptoCurrencyNetwork network) : super(Xelis(network));
  // ==================== Overrides ============================================

  @override
  int get isarTransactionVersion => 2;

  @override
  Future<void> init({bool? isRestore}) async {
    debugPrint("Xelis: init");
    
    if (isRestore == true) {
      await _restoreWallet();
      return await super.init();
    }

    String? walletExists =
        await secureStorageInterface.read(key: "${walletId}_wallet");

    if (walletExists == null) {
      await _createNewWallet();
    }

    await open();

    return await super.init();
  }

  Future<void> _createNewWallet() async {
    final String password = generatePassword();
    
    debugPrint("Xelis: storing password");
    await secureStorageInterface.write(
      key: Wallet.mnemonicPassphraseKey(walletId: info.walletId),
      value: password,
    );

    await secureStorageInterface.write(
      key: '${walletId}_wallet',
      value: 'true',
    );

    await secureStorageInterface.write(
      key: '_${walletId}_needs_creation',
      value: 'true',
    );
  }

  Future<void> _restoreWallet() async {
    final String password = generatePassword();

    await secureStorageInterface.write(
      key: Wallet.mnemonicPassphraseKey(walletId: info.walletId),
      value: password,
    );

    await secureStorageInterface.write(
      key: '${walletId}_wallet',
      value: 'true',
    );

    await secureStorageInterface.write(
      key: '_${walletId}_needs_restoration',
      value: 'true',
    );

    if (libXelisWallet != null) {
      await super.exit();
    }
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
      Logging.instance.log(
        "Exception rethrown from recoverFromMnemonic(): $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }


  @override
  Future<bool> pingCheck() async {
    checkInitialized();
    try {
      final nodeInfo = await libXelisWallet!.getDaemonInfo();
      await handleOnline();
      return true;
    } catch (_) {
      return false;
      await handleOffline();
    }
  }

  final _balanceUpdateMutex = Mutex();

  @override
  Future<void> updateBalance({int? newBalance}) async {
    await _balanceUpdateMutex.protect(() async {
      try {
        if (await libXelisWallet!.hasXelisBalance()) {
          final BigInt xelBalance = newBalance != null 
            ? BigInt.from(newBalance) 
            : await libXelisWallet!.getXelisBalanceRaw(); // in the future, use getAssetBalances and handle each
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
          await info.updateBalance(
            newBalance: balance,
            isar: mainDB.isar,
          ); 
        }
      } catch (e, s) {
        Logging.instance.log(
          "Error in updateBalance(): $e\n$s",
          level: LogLevel.Warning,
        );
      }
    });
  }

  Future<int> _fetchChainHeight() async {
    final infoString = await libXelisWallet!.getDaemonInfo();
    final Map<String, dynamic> nodeInfo = json.decode(infoString);
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
      Logging.instance.log(
        "Error in updateChainHeight(): $e\n$s",
        level: LogLevel.Warning,
      );
    }
  }

  @override
  Future<void> updateNode() async {
    try {
      final node = getCurrentNode();
      await libXelisWallet?.offlineMode();
      await libXelisWallet!.onlineMode(
        daemonAddress: node.host
      );
    } catch (e, s) {
      Logging.instance.log(
        "Error updating node: $e\n$s",
        level: LogLevel.Error,
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

    final newReceivingAddress = await getCurrentReceivingAddress() ??
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
      firstBlock = await mainDB.isar.transactionV2s
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
      await libXelisWallet!.rescan(topoheight: BigInt.from(topoheight!));
    }

    final txListJson = rawTransactions ?? await libXelisWallet!.allHistory();

    final List<TransactionV2> txns = [];

    for (final jsonString in txListJson) {
      try {
        final transactionEntry = xelis_sdk.TransactionEntry.fromJson(json.decode(jsonString));

        // Check for duplicates
        final storedTx = await mainDB.isar.transactionV2s
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
        TransactionSubType txSubType = TransactionSubType.none;
        int? nonce;
        Amount fee = Amount(
            rawValue: BigInt.zero, 
            fractionDigits: cryptoCurrency.fractionDigits
        );
        Map<String, dynamic> otherData = {};

        final entryType = transactionEntry.txEntryType;

        if (entryType is xelis_sdk.CoinbaseEntry) {
            final coinbase = entryType;
            txType = TransactionType.incoming;

            final int decimals = await libXelisWallet!.getAssetDecimals(
                asset: xelis_sdk.xelisAsset
            );

            fee = Amount(
                rawValue: BigInt.zero, 
                fractionDigits: decimals
            );

            outputs.add(OutputV2.isarCantDoRequiredInDefaultConstructor(
                scriptPubKeyHex: "",
                valueStringSats: coinbase.reward.toString(),
                addresses: [thisAddress],
                walletOwns: true,
            ));
        } else if (entryType is xelis_sdk.BurnEntry) {
            final burn = entryType;
            txType = TransactionType.outgoing;

            final int decimals = await libXelisWallet!.getAssetDecimals(
                asset: burn.asset
            );

            fee = Amount(
                rawValue: BigInt.from(burn.fee), 
                fractionDigits: decimals
            );

            inputs.add(InputV2.isarCantDoRequiredInDefaultConstructor(
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
            ));
            otherData['burnAsset'] = burn.asset;
        } else if (entryType is xelis_sdk.IncomingEntry) {
            final incoming = entryType;
            txType = incoming.from == thisAddress 
                ? TransactionType.sentToSelf 
                : TransactionType.incoming;
            
            for (final transfer in incoming.transfers) {
                final int decimals = await libXelisWallet!.getAssetDecimals(
                    asset: transfer.asset
                );

                fee = Amount(
                    rawValue: BigInt.zero, 
                    fractionDigits: decimals
                );

                outputs.add(OutputV2.isarCantDoRequiredInDefaultConstructor(
                    scriptPubKeyHex: "",
                    valueStringSats: transfer.amount.toString(),
                    addresses: [incoming.from],
                    walletOwns: true,
                ));
                otherData['asset_${transfer.asset}'] = transfer.amount.toString();
                if (transfer.extraData != null) {
                    otherData['extraData_${transfer.asset}'] = transfer.extraData!.toJson();
                }
            }
        } else if (entryType is xelis_sdk.OutgoingEntry) {
            final outgoing = entryType;
            txType = TransactionType.outgoing;
            nonce = outgoing.nonce;

            for (final transfer in outgoing.transfers) {
                final int decimals = await libXelisWallet!.getAssetDecimals(
                    asset: transfer.asset
                );

                fee = Amount(
                    rawValue: BigInt.from(outgoing.fee), 
                    fractionDigits: decimals
                );

                inputs.add(InputV2.isarCantDoRequiredInDefaultConstructor(
                    scriptSigHex: null,
                    scriptSigAsm: null,
                    sequence: null,
                    outpoint: null,
                    addresses: [transfer.destination],
                    valueStringSats: (transfer.amount + outgoing.fee).toString(),
                    witness: null,
                    innerRedeemScriptAsm: null,
                    coinbase: null,
                    walletOwns: true,
                ));
                otherData['asset_${transfer.asset}_amount'] = transfer.amount.toString();
                otherData['asset_${transfer.asset}_fee'] = fee.toString();
                if (transfer.extraData != null) {
                    otherData['extraData_${transfer.asset}'] = transfer.extraData!.toJson();
                }
            }
        } else {
            // Skip unknown entry types
        }

        final txn = TransactionV2(
          walletId: walletId,
          blockHash: "", // Not provided in Xelis data
          hash: transactionEntry.hash,
          txid: transactionEntry.hash,
          timestamp: (transactionEntry.timestamp?.millisecondsSinceEpoch ?? 0) ~/ 1000,
          height: transactionEntry?.topoheight,
          inputs: List.unmodifiable(inputs),
          outputs: List.unmodifiable(outputs),
          version: -1, // Version not provided
          type: txType!,
          subType: txSubType,
          otherData: jsonEncode({
            ...otherData,
            if (nonce != null) 'nonce': nonce,
            if (fee != null) 'overrideFee': fee.toJsonString(),
          }),
        );

        Logging.instance.log(
          "Entry done ${entryType.toString()}",
          level: LogLevel.Debug,
        );


        txns.add(txn);
      } catch (e, s) {
        Logging.instance.log(
          "Error handling tx $jsonString: $e\n$s",
          level: LogLevel.Warning,
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

      // Use default address if recipients list is empty
      final recipients = txData.recipients?.isNotEmpty == true 
          ? txData.recipients!
          : [(
              address: 'xel:xz9574c80c4xegnvurazpmxhw5dlg2n0g9qm60uwgt75uqyx3pcsqzzra9m', 
              amount: Amount.zeroWith(
                fractionDigits: cryptoCurrency.fractionDigits,
              ),
              isChange: false
            )];

      final asset = assetId ?? xelis_sdk.xelisAsset;

      // Calculate total send amount
      final totalSendAmount = recipients.fold<Amount>(
        Amount(rawValue: BigInt.zero, fractionDigits: cryptoCurrency.fractionDigits),
        (sum, recipient) => sum + recipient.amount
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
          assetHash: asset
        );

        final availableAmt = await libXelisWallet!.formatCoin(
          atomicAmount: xelBalance, 
          assetHash: asset
        );

        throw Exception(
          "Insufficient balance to cover transfers and fees. "
          "Required: $requiredAmt, Available: $availableAmt"
        );
      }

      return txData.copyWith(
        fee: boostedFee,
        otherData: jsonEncode({
          'asset': asset,
        }),
      );
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from prepareSend(): $e\n$s",
        level: LogLevel.Error,
      );
      rethrow;
    }
  }

  @override
  Future<Amount> estimateFeeFor(
    Amount amount, 
    int feeRate,
    {
      double? feeMultiplier,
      List<TxRecipient> recipients = const [],
      String? assetId
    }
  ) async {
    try {
      checkInitialized();
      final asset = assetId ?? xelis_sdk.xelisAsset;

      // // Use default address if recipients list is empty
      // final effectiveRecipients = recipients.isNotEmpty 
      //     ? recipients
      //     : [(
      //         address: 'xel:xz9574c80c4xegnvurazpmxhw5dlg2n0g9qm60uwgt75uqyx3pcsqzzra9m', 
      //         amount: amount, 
      //         isChange: false
      //       )];

      // final transfers = await Future.wait(
      //   effectiveRecipients.map((recipient) async {
      //     final amountStr = await libXelisWallet!.formatCoin(
      //       atomicAmount: recipient.amount.raw, 
      //       assetHash: asset
      //     );
      //     return x_wallet.Transfer(
      //       floatAmount: amountStr as double,
      //       strAddress: recipient.address,
      //       assetHash: asset,
      //     );
      //   })
      // );

      // // Estimate fees
      // final estimatedFeeString = await libXelisWallet!.estimateFees(transfers: transfers);
      // final feeAmount = Amount(
      //   rawValue: BigInt.parse(estimatedFeeString),
      //   fractionDigits: cryptoCurrency.fractionDigits,
      // );

      // // Apply fee multiplier
      // final multiplier = feeMultiplier ?? 1.0;
      return Amount(
        // rawValue: (BigInt.from((feeAmount.raw * 
        //           BigInt.from((multiplier * 100).toInt())) / 
        //           BigInt.from(100))),
        rawValue: BigInt.zero,
        fractionDigits: cryptoCurrency.fractionDigits,
      );
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from estimateFeeFor(): $e\n$s",
        level: LogLevel.Error,
      );
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

      final asset = (txData.getOtherData != null ? jsonDecode(txData.getOtherData!) : null)?['asset'] ?? xelis_sdk.xelisAsset;

      final amt = double.parse(await libXelisWallet!.formatCoin(
        atomicAmount: sendAmount.raw, 
        assetHash: asset
      ));

      // Create a transfer transaction
      final txJson = await libXelisWallet!.createTransfersTransaction(
        transfers: [
          x_wallet.Transfer(
            floatAmount: amt,
            strAddress: recipient.address,
            assetHash: asset,
            extraData: null, // Add extra data if needed
          )
        ]
      );

      final txMap = jsonDecode(txJson);
      final txHash = txMap['hash'] as String;

      // Broadcast the transaction
      await libXelisWallet!.broadcastTransaction(txHash: txHash);

      return await updateSentCachedTxData(txData: txData.copyWith(
        txid: txHash,
      ));
    } catch (e, s) {
      Logging.instance.log(
        "Exception rethrown from confirmSend(): $e\n$s",
        level: LogLevel.Error,
      );
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
      Logging.instance.log(
        "Error handling wallet event: $e\n$s",
        level: LogLevel.Error,
      );
    }
  }

  @override
  Future<void> handleNewTopoHeight(int height) async {
    await info.updateCachedChainHeight(
      newHeight: height,
      isar: mainDB.isar,
    );
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
      
      Logging.instance.log(
        "New transaction processed: ${newTxIds.first}",
        level: LogLevel.Info,
      );
    } catch (e, s) {
      Logging.instance.log(
        "Error handling new transaction: $e\n$s",
        level: LogLevel.Warning,
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
      Logging.instance.log(
        "Error handling balance change: $e\n$s",
        level: LogLevel.Warning,
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
    Logging.instance.log(
      "New asset detected: ${asset}",
      level: LogLevel.Info,
    );
  }

  @override
  Future<void> refresh({int? topoheight}) async {
    await refreshMutex.protect(() async {
      try {
        await updateChainHeight(topoheight: topoheight);
        await updateBalance();
        await updateTransactions();
      } catch (e, s) {
        Logging.instance.log(
          "Error in refresh(): $e\n$s",
          level: LogLevel.Warning,
        );
      }
    });
  }
}