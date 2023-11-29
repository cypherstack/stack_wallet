import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:isar/isar.dart';
import 'package:stackwallet/db/hive/db.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/address.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/input.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/output.dart';
import 'package:stackwallet/models/isar/models/blockchain_data/transaction.dart';
import 'package:stackwallet/models/isar/models/firo_specific/lelantus_coin.dart';
import 'package:stackwallet/utilities/amount/amount.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/wallets/crypto_currency/coins/firo.dart';
import 'package:stackwallet/wallets/crypto_currency/crypto_currency.dart';
import 'package:stackwallet/wallets/wallet/intermediate/bip39_hd_wallet.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/electrumx_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/lelantus_interface.dart';
import 'package:stackwallet/wallets/wallet/wallet_mixin_interfaces/spark_interface.dart';
import 'package:tuple/tuple.dart';

const sparkStartBlock = 819300; // (approx 18 Jan 2024)

class FiroWallet extends Bip39HDWallet
    with ElectrumXInterface, LelantusInterface, SparkInterface {
  // IMPORTANT: The order of the above mixins matters.
  // SparkInterface MUST come after LelantusInterface.

  FiroWallet(CryptoCurrencyNetwork network) : super(Firo(network));

  @override
  FilterOperation? get changeAddressFilterOperation =>
      FilterGroup.and(standardChangeAddressFilters);

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  // ===========================================================================

  bool _duplicateTxCheck(
      List<Map<String, dynamic>> allTransactions, String txid) {
    for (int i = 0; i < allTransactions.length; i++) {
      if (allTransactions[i]["txid"] == txid) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<void> updateTransactions() async {
    final allAddresses = await fetchAddressesForElectrumXScan();

    Set<String> receivingAddresses = allAddresses
        .where((e) => e.subType == AddressSubType.receiving)
        .map((e) => e.value)
        .toSet();
    Set<String> changeAddresses = allAddresses
        .where((e) => e.subType == AddressSubType.change)
        .map((e) => e.value)
        .toSet();

    final List<Map<String, dynamic>> allTxHashes =
        await fetchHistory(allAddresses.map((e) => e.value).toList());

    List<Map<String, dynamic>> allTransactions = [];

    // some lelantus transactions aren't fetched via wallet addresses so they
    // will never show as confirmed in the gui.
    final unconfirmedTransactions = await mainDB
        .getTransactions(walletId)
        .filter()
        .heightIsNull()
        .findAll();
    for (final tx in unconfirmedTransactions) {
      final txn = await electrumXCachedClient.getTransaction(
        txHash: tx.txid,
        verbose: true,
        coin: info.coin,
      );
      final height = txn["height"] as int?;

      if (height != null) {
        // tx was mined
        // add to allTxHashes
        final info = {
          "tx_hash": tx.txid,
          "height": height,
          "address": tx.address.value?.value,
        };
        allTxHashes.add(info);
      }
    }

    // final currentHeight = await chainHeight;

    for (final txHash in allTxHashes) {
      // final storedTx = await db
      //     .getTransactions(walletId)
      //     .filter()
      //     .txidEqualTo(txHash["tx_hash"] as String)
      //     .findFirst();

      // if (storedTx == null ||
      //     !storedTx.isConfirmed(currentHeight, MINIMUM_CONFIRMATIONS)) {
      final tx = await electrumXCachedClient.getTransaction(
        txHash: txHash["tx_hash"] as String,
        verbose: true,
        coin: info.coin,
      );

      if (!_duplicateTxCheck(allTransactions, tx["txid"] as String)) {
        tx["address"] = await mainDB
            .getAddresses(walletId)
            .filter()
            .valueEqualTo(txHash["address"] as String)
            .findFirst();
        tx["height"] = txHash["height"];
        allTransactions.add(tx);
      }
      // }
    }

    final List<Tuple2<Transaction, Address?>> txnsData = [];

    for (final txObject in allTransactions) {
      final inputList = txObject["vin"] as List;
      final outputList = txObject["vout"] as List;

      bool isMint = false;
      bool isJMint = false;

      // check if tx is Mint or jMint
      for (final output in outputList) {
        if (output["scriptPubKey"]?["type"] == "lelantusmint") {
          final asm = output["scriptPubKey"]?["asm"] as String?;
          if (asm != null) {
            if (asm.startsWith("OP_LELANTUSJMINT")) {
              isJMint = true;
              break;
            } else if (asm.startsWith("OP_LELANTUSMINT")) {
              isMint = true;
              break;
            } else {
              Logging.instance.log(
                "Unknown mint op code found for lelantusmint tx: ${txObject["txid"]}",
                level: LogLevel.Error,
              );
            }
          } else {
            Logging.instance.log(
              "ASM for lelantusmint tx: ${txObject["txid"]} is null!",
              level: LogLevel.Error,
            );
          }
        }
      }

      Set<String> inputAddresses = {};
      Set<String> outputAddresses = {};

      Amount totalInputValue = Amount(
        rawValue: BigInt.zero,
        fractionDigits: cryptoCurrency.fractionDigits,
      );
      Amount totalOutputValue = Amount(
        rawValue: BigInt.zero,
        fractionDigits: cryptoCurrency.fractionDigits,
      );

      Amount amountSentFromWallet = Amount(
        rawValue: BigInt.zero,
        fractionDigits: cryptoCurrency.fractionDigits,
      );
      Amount amountReceivedInWallet = Amount(
        rawValue: BigInt.zero,
        fractionDigits: cryptoCurrency.fractionDigits,
      );
      Amount changeAmount = Amount(
        rawValue: BigInt.zero,
        fractionDigits: cryptoCurrency.fractionDigits,
      );

      // Parse mint transaction ================================================
      // We should be able to assume this belongs to this wallet
      if (isMint) {
        List<Input> ins = [];

        // Parse inputs
        for (final input in inputList) {
          // Both value and address should not be null for a mint
          final address = input["address"] as String?;
          final value = input["valueSat"] as int?;

          // We should not need to check whether the mint belongs to this
          // wallet as any tx we look up will be looked up by one of this
          // wallet's addresses
          if (address != null && value != null) {
            totalInputValue += value.toAmountAsRaw(
              fractionDigits: cryptoCurrency.fractionDigits,
            );
          }

          ins.add(
            Input(
              txid: input['txid'] as String? ?? "",
              vout: input['vout'] as int? ?? -1,
              scriptSig: input['scriptSig']?['hex'] as String?,
              scriptSigAsm: input['scriptSig']?['asm'] as String?,
              isCoinbase: input['is_coinbase'] as bool?,
              sequence: input['sequence'] as int?,
              innerRedeemScriptAsm: input['innerRedeemscriptAsm'] as String?,
            ),
          );
        }

        // Parse outputs
        for (final output in outputList) {
          // get value
          final value = Amount.fromDecimal(
            Decimal.parse(output["value"].toString()),
            fractionDigits: cryptoCurrency.fractionDigits,
          );

          // add value to total
          totalOutputValue += value;
        }

        final fee = totalInputValue - totalOutputValue;
        final tx = Transaction(
          walletId: walletId,
          txid: txObject["txid"] as String,
          timestamp: txObject["blocktime"] as int? ??
              (DateTime.now().millisecondsSinceEpoch ~/ 1000),
          type: TransactionType.sentToSelf,
          subType: TransactionSubType.mint,
          amount: totalOutputValue.raw.toInt(),
          amountString: totalOutputValue.toJsonString(),
          fee: fee.raw.toInt(),
          height: txObject["height"] as int?,
          isCancelled: false,
          isLelantus: true,
          slateId: null,
          otherData: null,
          nonce: null,
          inputs: ins,
          outputs: [],
          numberOfMessages: null,
        );

        txnsData.add(Tuple2(tx, null));

        // Otherwise parse JMint transaction ===================================
      } else if (isJMint) {
        Amount jMintFees = Amount(
          rawValue: BigInt.zero,
          fractionDigits: cryptoCurrency.fractionDigits,
        );

        // Parse inputs
        List<Input> ins = [];
        for (final input in inputList) {
          // JMint fee
          final nFee = Decimal.tryParse(input["nFees"].toString());
          if (nFee != null) {
            final fees = Amount.fromDecimal(
              nFee,
              fractionDigits: cryptoCurrency.fractionDigits,
            );

            jMintFees += fees;
          }

          ins.add(
            Input(
              txid: input['txid'] as String? ?? "",
              vout: input['vout'] as int? ?? -1,
              scriptSig: input['scriptSig']?['hex'] as String?,
              scriptSigAsm: input['scriptSig']?['asm'] as String?,
              isCoinbase: input['is_coinbase'] as bool?,
              sequence: input['sequence'] as int?,
              innerRedeemScriptAsm: input['innerRedeemscriptAsm'] as String?,
            ),
          );
        }

        bool nonWalletAddressFoundInOutputs = false;

        // Parse outputs
        List<Output> outs = [];
        for (final output in outputList) {
          // get value
          final value = Amount.fromDecimal(
            Decimal.parse(output["value"].toString()),
            fractionDigits: cryptoCurrency.fractionDigits,
          );

          // add value to total
          totalOutputValue += value;

          final address = output["scriptPubKey"]?["addresses"]?[0] as String? ??
              output['scriptPubKey']?['address'] as String?;

          if (address != null) {
            outputAddresses.add(address);
            if (receivingAddresses.contains(address) ||
                changeAddresses.contains(address)) {
              amountReceivedInWallet += value;
            } else {
              nonWalletAddressFoundInOutputs = true;
            }
          }

          outs.add(
            Output(
              scriptPubKey: output['scriptPubKey']?['hex'] as String?,
              scriptPubKeyAsm: output['scriptPubKey']?['asm'] as String?,
              scriptPubKeyType: output['scriptPubKey']?['type'] as String?,
              scriptPubKeyAddress: address ?? "jmint",
              value: value.raw.toInt(),
            ),
          );
        }
        final txid = txObject["txid"] as String;

        const subType = TransactionSubType.join;

        final type = nonWalletAddressFoundInOutputs
            ? TransactionType.outgoing
            : (await mainDB.isar.lelantusCoins
                        .where()
                        .walletIdEqualTo(walletId)
                        .filter()
                        .txidEqualTo(txid)
                        .findFirst()) ==
                    null
                ? TransactionType.incoming
                : TransactionType.sentToSelf;

        final amount = nonWalletAddressFoundInOutputs
            ? totalOutputValue
            : amountReceivedInWallet;

        final possibleNonWalletAddresses =
            receivingAddresses.difference(outputAddresses);
        final possibleReceivingAddresses =
            receivingAddresses.intersection(outputAddresses);

        final transactionAddress = nonWalletAddressFoundInOutputs
            ? Address(
                walletId: walletId,
                value: possibleNonWalletAddresses.first,
                derivationIndex: -1,
                derivationPath: null,
                type: AddressType.nonWallet,
                subType: AddressSubType.nonWallet,
                publicKey: [],
              )
            : allAddresses.firstWhere(
                (e) => e.value == possibleReceivingAddresses.first,
              );

        final tx = Transaction(
          walletId: walletId,
          txid: txid,
          timestamp: txObject["blocktime"] as int? ??
              (DateTime.now().millisecondsSinceEpoch ~/ 1000),
          type: type,
          subType: subType,
          amount: amount.raw.toInt(),
          amountString: amount.toJsonString(),
          fee: jMintFees.raw.toInt(),
          height: txObject["height"] as int?,
          isCancelled: false,
          isLelantus: true,
          slateId: null,
          otherData: null,
          nonce: null,
          inputs: ins,
          outputs: outs,
          numberOfMessages: null,
        );

        txnsData.add(Tuple2(tx, transactionAddress));

        // Master node payment =====================================
      } else if (inputList.length == 1 &&
          inputList.first["coinbase"] is String) {
        List<Input> ins = [
          Input(
            txid: inputList.first["coinbase"] as String,
            vout: -1,
            scriptSig: null,
            scriptSigAsm: null,
            isCoinbase: true,
            sequence: inputList.first['sequence'] as int?,
            innerRedeemScriptAsm: null,
          ),
        ];

        // parse outputs
        List<Output> outs = [];
        for (final output in outputList) {
          // get value
          final value = Amount.fromDecimal(
            Decimal.parse(output["value"].toString()),
            fractionDigits: cryptoCurrency.fractionDigits,
          );

          // get output address
          final address = output["scriptPubKey"]?["addresses"]?[0] as String? ??
              output["scriptPubKey"]?["address"] as String?;
          if (address != null) {
            outputAddresses.add(address);

            // if output was to my wallet, add value to amount received
            if (receivingAddresses.contains(address)) {
              amountReceivedInWallet += value;
            }
          }

          outs.add(
            Output(
              scriptPubKey: output['scriptPubKey']?['hex'] as String?,
              scriptPubKeyAsm: output['scriptPubKey']?['asm'] as String?,
              scriptPubKeyType: output['scriptPubKey']?['type'] as String?,
              scriptPubKeyAddress: address ?? "",
              value: value.raw.toInt(),
            ),
          );
        }

        // this is the address initially used to fetch the txid
        Address transactionAddress = txObject["address"] as Address;

        final tx = Transaction(
          walletId: walletId,
          txid: txObject["txid"] as String,
          timestamp: txObject["blocktime"] as int? ??
              (DateTime.now().millisecondsSinceEpoch ~/ 1000),
          type: TransactionType.incoming,
          subType: TransactionSubType.none,
          // amount may overflow. Deprecated. Use amountString
          amount: amountReceivedInWallet.raw.toInt(),
          amountString: amountReceivedInWallet.toJsonString(),
          fee: 0,
          height: txObject["height"] as int?,
          isCancelled: false,
          isLelantus: false,
          slateId: null,
          otherData: null,
          nonce: null,
          inputs: ins,
          outputs: outs,
          numberOfMessages: null,
        );

        txnsData.add(Tuple2(tx, transactionAddress));

        // Assume non lelantus transaction =====================================
      } else {
        // parse inputs
        List<Input> ins = [];
        for (final input in inputList) {
          final valueSat = input["valueSat"] as int?;
          final address = input["address"] as String? ??
              input["scriptPubKey"]?["address"] as String? ??
              input["scriptPubKey"]?["addresses"]?[0] as String?;

          if (address != null && valueSat != null) {
            final value = valueSat.toAmountAsRaw(
              fractionDigits: cryptoCurrency.fractionDigits,
            );

            // add value to total
            totalInputValue += value;
            inputAddresses.add(address);

            // if input was from my wallet, add value to amount sent
            if (receivingAddresses.contains(address) ||
                changeAddresses.contains(address)) {
              amountSentFromWallet += value;
            }
          }

          ins.add(
            Input(
              txid: input['txid'] as String,
              vout: input['vout'] as int? ?? -1,
              scriptSig: input['scriptSig']?['hex'] as String?,
              scriptSigAsm: input['scriptSig']?['asm'] as String?,
              isCoinbase: input['is_coinbase'] as bool?,
              sequence: input['sequence'] as int?,
              innerRedeemScriptAsm: input['innerRedeemscriptAsm'] as String?,
            ),
          );
        }

        // parse outputs
        List<Output> outs = [];
        for (final output in outputList) {
          // get value
          final value = Amount.fromDecimal(
            Decimal.parse(output["value"].toString()),
            fractionDigits: cryptoCurrency.fractionDigits,
          );

          // add value to total
          totalOutputValue += value;

          // get output address
          final address = output["scriptPubKey"]?["addresses"]?[0] as String? ??
              output["scriptPubKey"]?["address"] as String?;
          if (address != null) {
            outputAddresses.add(address);

            // if output was to my wallet, add value to amount received
            if (receivingAddresses.contains(address)) {
              amountReceivedInWallet += value;
            } else if (changeAddresses.contains(address)) {
              changeAmount += value;
            }
          }

          outs.add(
            Output(
              scriptPubKey: output['scriptPubKey']?['hex'] as String?,
              scriptPubKeyAsm: output['scriptPubKey']?['asm'] as String?,
              scriptPubKeyType: output['scriptPubKey']?['type'] as String?,
              scriptPubKeyAddress: address ?? "",
              value: value.raw.toInt(),
            ),
          );
        }

        final mySentFromAddresses = [
          ...receivingAddresses.intersection(inputAddresses),
          ...changeAddresses.intersection(inputAddresses)
        ];
        final myReceivedOnAddresses =
            receivingAddresses.intersection(outputAddresses);
        final myChangeReceivedOnAddresses =
            changeAddresses.intersection(outputAddresses);

        final fee = totalInputValue - totalOutputValue;

        // this is the address initially used to fetch the txid
        Address transactionAddress = txObject["address"] as Address;

        TransactionType type;
        Amount amount;
        if (mySentFromAddresses.isNotEmpty &&
            myReceivedOnAddresses.isNotEmpty) {
          // tx is sent to self
          type = TransactionType.sentToSelf;

          // should be 0
          amount = amountSentFromWallet -
              amountReceivedInWallet -
              fee -
              changeAmount;
        } else if (mySentFromAddresses.isNotEmpty) {
          // outgoing tx
          type = TransactionType.outgoing;
          amount = amountSentFromWallet - changeAmount - fee;

          final possible =
              outputAddresses.difference(myChangeReceivedOnAddresses).first;

          if (transactionAddress.value != possible) {
            transactionAddress = Address(
              walletId: walletId,
              value: possible,
              derivationIndex: -1,
              derivationPath: null,
              subType: AddressSubType.nonWallet,
              type: AddressType.nonWallet,
              publicKey: [],
            );
          }
        } else {
          // incoming tx
          type = TransactionType.incoming;
          amount = amountReceivedInWallet;
        }

        final tx = Transaction(
          walletId: walletId,
          txid: txObject["txid"] as String,
          timestamp: txObject["blocktime"] as int? ??
              (DateTime.now().millisecondsSinceEpoch ~/ 1000),
          type: type,
          subType: TransactionSubType.none,
          // amount may overflow. Deprecated. Use amountString
          amount: amount.raw.toInt(),
          amountString: amount.toJsonString(),
          fee: fee.raw.toInt(),
          height: txObject["height"] as int?,
          isCancelled: false,
          isLelantus: false,
          slateId: null,
          otherData: null,
          nonce: null,
          inputs: ins,
          outputs: outs,
          numberOfMessages: null,
        );

        txnsData.add(Tuple2(tx, transactionAddress));
      }
    }

    await mainDB.addNewTransactionData(txnsData, walletId);
  }

  @override
  ({String? blockedReason, bool blocked}) checkBlockUTXO(
    Map<String, dynamic> jsonUTXO,
    String? scriptPubKeyHex,
    Map<String, dynamic>? jsonTX,
  ) {
    bool blocked = false;
    String? blockedReason;
    //
    // if (jsonTX != null) {
    //   // check for bip47 notification
    //   final outputs = jsonTX["vout"] as List;
    //   for (final output in outputs) {
    //     List<String>? scriptChunks =
    //     (output['scriptPubKey']?['asm'] as String?)?.split(" ");
    //     if (scriptChunks?.length == 2 && scriptChunks?[0] == "OP_RETURN") {
    //       final blindedPaymentCode = scriptChunks![1];
    //       final bytes = blindedPaymentCode.toUint8ListFromHex;
    //
    //       // https://en.bitcoin.it/wiki/BIP_0047#Sending
    //       if (bytes.length == 80 && bytes.first == 1) {
    //         blocked = true;
    //         blockedReason = "Paynym notification output. Incautious "
    //             "handling of outputs from notification transactions "
    //             "may cause unintended loss of privacy.";
    //         break;
    //       }
    //     }
    //   }
    // }
    //
    return (blockedReason: blockedReason, blocked: blocked);
  }

  @override
  Future<void> recover({required bool isRescan}) async {
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
          // clear cache
          await electrumXCachedClient.clearSharedTransactionCache(
              coin: info.coin);
          // clear blockchain info
          await mainDB.deleteWalletBlockchainData(walletId);
        }

        final latestSetId = await electrumXClient.getLelantusLatestCoinId();
        final setDataMapFuture = getSetDataMap(latestSetId);
        final usedSerialNumbersFuture =
            electrumXCachedClient.getUsedCoinSerials(
          coin: info.coin,
        );

        // receiving addresses
        Logging.instance.log(
          "checking receiving addresses...",
          level: LogLevel.Info,
        );

        for (final type in cryptoCurrency.supportedDerivationPathTypes) {
          receiveFutures.add(
            serverCanBatch
                ? checkGapsBatched(
                    txCountBatchSize,
                    root,
                    type,
                    receiveChain,
                  )
                : checkGapsLinearly(
                    root,
                    type,
                    receiveChain,
                  ),
          );
        }

        // change addresses
        Logging.instance.log(
          "checking change addresses...",
          level: LogLevel.Info,
        );
        for (final type in cryptoCurrency.supportedDerivationPathTypes) {
          changeFutures.add(
            serverCanBatch
                ? checkGapsBatched(
                    txCountBatchSize,
                    root,
                    type,
                    changeChain,
                  )
                : checkGapsLinearly(
                    root,
                    type,
                    changeChain,
                  ),
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
            await checkReceivingAddressForTransactions();
          } else {
            highestReceivingIndexWithHistory = max(
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
            highestChangeIndexWithHistory = max(
              tuple.index,
              highestChangeIndexWithHistory,
            );
            addressesToStore.addAll(tuple.addresses);
          }
        }

        // remove extra addresses to help minimize risk of creating a large gap
        addressesToStore.removeWhere((e) =>
            e.subType == AddressSubType.change &&
            e.derivationIndex > highestChangeIndexWithHistory);
        addressesToStore.removeWhere((e) =>
            e.subType == AddressSubType.receiving &&
            e.derivationIndex > highestReceivingIndexWithHistory);

        await mainDB.updateOrPutAddresses(addressesToStore);

        await Future.wait([
          updateTransactions(),
          updateUTXOs(),
        ]);

        final futureResults = await Future.wait([
          usedSerialNumbersFuture,
          setDataMapFuture,
        ]);

        final usedSerialsSet = (futureResults[0] as List<String>).toSet();
        final setDataMap = futureResults[1] as Map<dynamic, dynamic>;

        await recoverLelantusWallet(
          latestSetId: latestSetId,
          usedSerialNumbers: usedSerialsSet,
          setDataMap: setDataMap,
        );
      });

      await refresh();
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from electrumx_mixin recover(): $e\n$s",
          level: LogLevel.Info);

      rethrow;
    }
  }

  @override
  Amount roughFeeEstimate(int inputCount, int outputCount, int feeRatePerKB) {
    return Amount(
      rawValue: BigInt.from(((181 * inputCount) + (34 * outputCount) + 10) *
          (feeRatePerKB / 1000).ceil()),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  int estimateTxFee({required int vSize, required int feeRatePerKB}) {
    return vSize * (feeRatePerKB / 1000).ceil();
  }

  // ===========================================================================

  static const String _lelantusCoinIsarRescanRequired =
      "lelantusCoinIsarRescanRequired";

  Future<void> setLelantusCoinIsarRescanRequiredDone() async {
    await DB.instance.put<dynamic>(
      boxName: walletId,
      key: _lelantusCoinIsarRescanRequired,
      value: false,
    );
  }

  bool get lelantusCoinIsarRescanRequired =>
      DB.instance.get(
        boxName: walletId,
        key: _lelantusCoinIsarRescanRequired,
      ) as bool? ??
      true;

  Future<bool> firoRescanRecovery() async {
    try {
      await recover(isRescan: true);
      await setLelantusCoinIsarRescanRequiredDone();
      return true;
    } catch (_) {
      return false;
    }
  }
}
