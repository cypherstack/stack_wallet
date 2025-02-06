import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:xelis_flutter/src/api/network.dart' as x_network;
import 'package:xelis_flutter/src/api/wallet.dart' as x_wallet;
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;

import '../../../models/isar/models/blockchain_data/address.dart';
import '../../../models/isar/models/blockchain_data/transaction.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';

import '../../../models/node_model.dart';
import '../../../models/balance.dart';
import '../../../utilities/amount/amount.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../models/tx_data.dart';
import '../wallet.dart';

import 'package:isar/isar.dart';
import 'package:mutex/mutex.dart';
import 'package:stack_wallet_backup/generate_password.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../intermediate/bip39_wallet.dart';

extension XelisNetworkConversion on CryptoCurrencyNetwork {
  x_network.Network get xelisNetwork {
    switch (this) {
      case CryptoCurrencyNetwork.main:
        return x_network.Network.mainnet;
      case CryptoCurrencyNetwork.test:
        return x_network.Network.testnet;
      default:
        throw ArgumentError('Unsupported network type for Xelis: $this');
    }
  }
}

extension CryptoCurrencyNetworkConversion on x_network.Network {
  CryptoCurrencyNetwork get cryptoCurrencyNetwork {
    switch (this) {
      case x_network.Network.mainnet:
        return CryptoCurrencyNetwork.main;
      case x_network.Network.testnet:
        return CryptoCurrencyNetwork.test;
      default:
        throw ArgumentError('Unsupported Xelis network type: $this');
    }
  }
}

class XelisWallet extends Wallet<Xelis> {
  x_wallet.XelisWallet? _wallet;

  x_wallet.XelisWallet? get wallet => _wallet;
  set wallet(x_wallet.XelisWallet newWallet) {
    _wallet = newWallet;
  }

  void _checkInitialized() {
    if (_wallet == null) {
      throw StateError('XelisWallet not initialized');
    }
  }

  XelisWallet(CryptoCurrencyNetwork network) : super(Xelis(network));

  final syncMutex = Mutex();
  NodeModel? _xelisNode;
  Timer? timer;

  // ==================== Overrides ============================================

  @override
  int get isarTransactionVersion => 2;

  @override
  Future<void> init({bool? isRestore}) async {
    if (isRestore != true) {
      x_wallet.PrecomputedTablesShared? encodedTables =
        await secureStorageInterface.read(key: "xelis_precomputed_tables");

      String? encodedWallet =
        await secureStorageInterface.read(key: "${walletId}_wallet");

      // check if should create a new wallet
      if (encodedWallet == null) {
        final String password = generatePassword();

        await secureStorageInterface.write(
          key: '${walletId}_password',
          value: password,
        );

        final String name = walletId;

        final wallet = await x_wallet.createXelisWallet(
          name: name,
          password: password,
          network: cryptoCurrency.network.xelisNetwork,
          seed: null, // Xelis lib will autogenerate this
          privateKey: null, // Xelis lib will autogenerate this
          precomputedTables: encodedTables,
        );

        await secureStorageInterface.write(
          key: '${walletId}_wallet',
          value: wallet,
        );

        _wallet = wallet;
      } else {
        try {

          final String name = walletId;
          final password =
              await secureStorageInterface.read(key: '${walletId}_password');

          final wallet = await x_wallet.openXelisWallet(
            name: name,
            password: password,
            network: cryptoCurrency.network.xelisNetwork,
            precomputedTables: encodedTables,
          );

          await secureStorageInterface.write(
            key: '${walletId}_wallet',
            value: wallet,
          );

          _wallet = wallet;
        } catch (e, s) {
          // do nothing, still allow user into wallet
        }
      }

      // Creation or Opening of Xelis wallets will generate tables if required
      // Make sure to store said shared tables if we make it this far, to save
      // time in the future
      if (encodedTables == null) {
        await secureStorageInterface.write(
          key: 'xelis_precomputed_tables',
          value: x_wallet.getCachedTable(),
        );
      }
    }

    return await super.init();
  }

  @override
  Future<bool> pingCheck() async {
    _checkInitialized();
    try {
      await _wallet!.getDaemonInfo();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> updateBalance() async {
    try {
      final BigInt xelBalance = await _wallet!.getXelisBalanceRaw(); // in the future, use getAssetBalances and handle each
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
    } catch (e, s) {
    }
  }

  @override
  Future<void> updateChainHeight() async {
    try {
      final infoString = await _wallet!.getDaemonInfo();
      
      final Map<String, dynamic> nodeInfo = json.decode(infoString);
      
      final int topoheight = nodeInfo['topoheight'] as int;

      await info.updateCachedChainHeight(
        newHeight: topoheight,
        isar: mainDB.isar,
      );
    } catch (e, s) {
      print('Error updating chain height: $e');
      print('Stack trace: $s');
    }
  }

  @override
  Future<void> updateNode() async {
    // do nothing
  }

  @override
  Future<List<String>> updateTransactions({bool isRescan = false}) async {
    _checkInitialized();

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
    }

    await _wallet!.rescan(topoheight: firstBlock as BigInt);
    final txListJson = await _wallet!.allHistory();

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
        TransactionType txType;
        TransactionSubType txSubType = TransactionSubType.none;
        int? nonce;
        Amount? fee;
        Map<String, dynamic> otherData = {};

        final entryData = transactionEntry.txEntryType;

        if (entryData is xelis_sdk.CoinbaseEntry) {
            final coinbase = entryData;
            txType = TransactionType.incoming;
            outputs.add(OutputV2.isarCantDoRequiredInDefaultConstructor(
                scriptPubKeyHex: "00",
                valueStringSats: coinbase.reward.toString(),
                addresses: [thisAddress],
                walletOwns: true,
            ));
        } else if (entryData is xelis_sdk.BurnEntry) {
            final burn = entryData;
            txType = TransactionType.outgoing;
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
        } else if (entryData is xelis_sdk.IncomingEntry) {
            final incoming = entryData;
            txType = incoming.from == thisAddress 
                ? TransactionType.sentToSelf 
                : TransactionType.incoming;
            
            for (final transfer in incoming.transfers) {
                final int decimals = await _wallet!.getAssetDecimals(
                    asset: transfer.asset
                );

                outputs.add(OutputV2.isarCantDoRequiredInDefaultConstructor(
                    scriptPubKeyHex: "00",
                    valueStringSats: transfer.amount.toString(),
                    addresses: [thisAddress],
                    walletOwns: true,
                ));
                otherData['asset_${transfer.asset}'] = transfer.amount.toString();
                if (transfer.extraData != null) {
                    otherData['extraData_${transfer.asset}'] = transfer.extraData!.toJson();
                }
            }
        } else if (entryData is xelis_sdk.OutgoingEntry) {
            final outgoing = entryData;
            txType = TransactionType.outgoing;
            nonce = outgoing.nonce;
            fee = Amount(
                rawValue: BigInt.from(outgoing.fee), 
                fractionDigits: decimals
            );

            for (final transfer in outgoing.transfers) {
                final int decimals = await _wallet!.getAssetDecimals(
                    asset: transfer.asset
                );

                outputs.add(OutputV2.isarCantDoRequiredInDefaultConstructor(
                    scriptPubKeyHex: "00",
                    valueStringSats: transfer.amount.toString(),
                    addresses: [transfer.destination],
                    walletOwns: transfer.destination == thisAddress,
                ));
                otherData['asset_${transfer.asset}'] = transfer.amount.toString();
                if (transfer.extraData != null) {
                    otherData['extraData_${transfer.asset}'] = transfer.extraData!.toJson();
                }
            }
        } else {
            // Skip unknown entry types
            return;
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
          type: txType,
          subType: txSubType,
          otherData: jsonEncode({
            ...otherData,
            if (nonce != null) 'nonce': nonce,
            if (fee != null) 'overrideFee': fee.toJsonString(),
          }),
        );

        txns.add(txn);
      } catch (e, s) {
      }
    }

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
  Future<TxData> prepareSend({required TxData txData}) async {
    try {
      _checkInitialized();

      // Validate recipients
      if (txData.recipients == null || txData.recipients!.length != 1) {
        throw Exception("$runtimeType prepareSend requires 1 recipient");
      }

      final recipient = txData.recipients!.first;
      final Amount sendAmount = recipient.amount;
      final asset = cryptoCurrency.assetId ?? xelis_sdk.xelisAsset;

      final sendAmountStr = await _wallet!.formatCoin(
        atomicAmount: sendAmount.rawValue, 
        assetHash: asset
      );

      // Check balance using raw method
      final xelBalance = await _wallet!.getXelisBalanceRaw();
      final balance = Amount(
        rawValue: xelBalance,
        fractionDigits: cryptoCurrency.fractionDigits, // needs to become tied to asset
      );

      // Create transfers for fee estimation
      final transfers = [
        x_wallet.Transfer(
          floatAmount: sendAmountStr as double,
          strAddress: recipient.address,
          assetHash: asset,
        )
      ];

      // Estimate fees
      final estimatedFeeString = await _wallet!.estimateFees(transfers: transfers);
      final feeAmount = Amount(
        rawValue: BigInt.parse(estimatedFeeString),
        fractionDigits: cryptoCurrency.fractionDigits,
      );

      // Apply fee multiplier
      final feeMultiplier = txData.feeRateAmount ?? 1.0;
      final boostedFee = Amount(
        rawValue: (BigInt.from((feeAmount.raw * 
                  BigInt.from((feeMultiplier * 100).toInt())) / 
                  BigInt.from(100))),
        fractionDigits: cryptoCurrency.fractionDigits,
      );

      // Check if we have enough for both transfer and fee
      if (sendAmount + boostedFee > balance) {
        final requiredAmt = await _wallet!.formatCoin(
          atomicAmount: (sendAmount + boostedFee).rawValue, 
          assetHash: asset
        );

        final availableAmt = await _wallet!.formatCoin(
          atomicAmount: xelBalance, 
          assetHash: asset
        );

        throw Exception(
          "Insufficient balance to cover transfer and fees. "
          "Required: $requiredAmt, Available: $availableAmt"
        );
      }

      return txData.copyWith(
        fee: boostedFee,
        otherData: {
          'asset': asset,
        },
      );
    } catch (e, s) {
      rethrow;
    }
  }

  @override
  Future<TxData> confirmSend({required TxData txData}) async {
    try {
      _checkInitialized();

      // Validate recipients
      if (txData.recipients == null || txData.recipients!.length != 1) {
        throw Exception("$runtimeType confirmSend requires 1 recipient");
      }

      final recipient = txData.recipients!.first;
      final Amount sendAmount = recipient.amount;
      final asset = txData.otherData?['asset'] ?? xelis_sdk.xelisAsset;

      String txHash;

      final amt = await _wallet!.formatCoin(
        atomicAmount: recipient.amount as BigInt, 
        assetHash: asset
      ) as double;

      // Create a transfer transaction
      final txJson = await _wallet!.createTransfersTransaction(
        transfers: [
          x_wallet.Transfer(
            floatAmount: amt,
            strAddress: recipient.address,
            assetHash: asset,
            extraData: null, // Add extra data if needed
          )
        ]
      );

      final tx = x_wallet.TransactionSummary.fromJson(txJson);

      // Broadcast the transaction
      await _wallet!.broadcastTransaction(txHash: tx.hash);

      return await updateSentCachedTxData(txData: txData.copyWith(
        txid: tx.hash,
      ));
    } catch (e, s) {
      rethrow;
    }
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    await refreshMutex.protect(() async {
      if (isRescan) {
        await mainDB.deleteWalletBlockchainData(walletId);
        await checkSaveInitialReceivingAddress();
        await updateBalance();
        await updateTransactions(isRescan: true);
      } else {
        await checkSaveInitialReceivingAddress();
        unawaited(updateBalance());
        unawaited(updateTransactions());
      }
    });
  }

  @override
  Future<void> exit() async {
    timer?.cancel();
    timer = null;
    await super.exit();
  }
}