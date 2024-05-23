import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter_libsparkmobile/flutter_libsparkmobile.dart';
import 'package:isar/isar.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/util.dart';
import '../../crypto_currency/coins/firo.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../isar/models/spark_coin.dart';
import '../../isar/models/wallet_info.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_hd_wallet.dart';
import '../wallet_mixin_interfaces/electrumx_interface.dart';
import '../wallet_mixin_interfaces/lelantus_interface.dart';
import '../wallet_mixin_interfaces/spark_interface.dart';

const sparkStartBlock = 819300; // (approx 18 Jan 2024)

class FiroWallet<T extends ElectrumXCurrencyInterface> extends Bip39HDWallet<T>
    with ElectrumXInterface<T>, LelantusInterface<T>, SparkInterface<T> {
  // IMPORTANT: The order of the above mixins matters.
  // SparkInterface MUST come after LelantusInterface.

  FiroWallet(CryptoCurrencyNetwork network) : super(Firo(network) as T);

  @override
  int get isarTransactionVersion => 2;

  @override
  FilterOperation? get changeAddressFilterOperation =>
      FilterGroup.and(standardChangeAddressFilters);

  @override
  FilterOperation? get receivingAddressFilterOperation =>
      FilterGroup.and(standardReceivingAddressFilters);

  final Set<String> _unconfirmedTxids = {};

  // ===========================================================================

  @override
  Future<TxData> updateSentCachedTxData({required TxData txData}) async {
    if (txData.tempTx != null) {
      await mainDB.updateOrPutTransactionV2s([txData.tempTx!]);
      _unconfirmedTxids.add(txData.tempTx!.txid);
      Logging.instance.log(
        "Added firo unconfirmed: ${txData.tempTx!.txid}",
        level: LogLevel.Info,
      );
    }
    return txData;
  }

  @override
  Future<void> updateTransactions() async {
    final List<Address> allAddressesOld =
        await fetchAddressesForElectrumXScan();

    final Set<String> receivingAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.receiving)
        .map((e) => convertAddressString(e.value))
        .toSet();

    final Set<String> changeAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.change)
        .map((e) => convertAddressString(e.value))
        .toSet();

    final allAddressesSet = {...receivingAddresses, ...changeAddresses};

    final List<Map<String, dynamic>> allTxHashes =
        await fetchHistory(allAddressesSet);

    final sparkCoins = await mainDB.isar.sparkCoins
        .where()
        .walletIdEqualToAnyLTagHash(walletId)
        .findAll();

    final Set<String> sparkTxids = {};

    for (final coin in sparkCoins) {
      sparkTxids.add(coin.txHash);
      // check for duplicates before adding to list
      if (allTxHashes.indexWhere((e) => e["tx_hash"] == coin.txHash) == -1) {
        final info = {
          "tx_hash": coin.txHash,
          "height": coin.height,
        };
        allTxHashes.add(info);
      }
    }

    final List<Map<String, dynamic>> allTransactions = [];

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
        cryptoCurrency: info.coin,
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

    for (final txHash in allTxHashes) {
      // final storedTx = await db
      //     .getTransactions(walletId)
      //     .filter()
      //     .txidEqualTo(txHash["tx_hash"] as String)
      //     .findFirst();

      // if (storedTx == null ||
      //     !storedTx.isConfirmed(currentHeight, MINIMUM_CONFIRMATIONS)) {

      // firod/electrumx seem to take forever to process spark txns so we'll
      // just ignore null errors and check again on next refresh.
      // This could also be a bug in the custom electrumx rpc code
      final Map<String, dynamic> tx;
      try {
        tx = await electrumXCachedClient.getTransaction(
          txHash: txHash["tx_hash"] as String,
          verbose: true,
          cryptoCurrency: info.coin,
        );
      } catch (_) {
        continue;
      }

      // check for duplicates before adding to list
      if (allTransactions
              .indexWhere((e) => e["txid"] == tx["txid"] as String) ==
          -1) {
        tx["height"] ??= txHash["height"];
        allTransactions.add(tx);
      }
      // }
    }

    final List<TransactionV2> txns = [];

    for (final txData in allTransactions) {
      // set to true if any inputs were detected as owned by this wallet
      bool wasSentFromThisWallet = false;

      // set to true if any outputs were detected as owned by this wallet
      bool wasReceivedInThisWallet = false;
      BigInt amountReceivedInThisWallet = BigInt.zero;
      BigInt changeAmountReceivedInThisWallet = BigInt.zero;

      Amount? anonFees;

      bool isMint = false;
      bool isJMint = false;
      bool isSparkMint = false;
      final bool isMasterNodePayment = false;
      final bool isSparkSpend = txData["type"] == 9 && txData["version"] == 3;
      final bool isMySpark = sparkTxids.contains(txData["txid"] as String);

      final sparkCoinsInvolved =
          sparkCoins.where((e) => e.txHash == txData["txid"]);
      if (isMySpark && sparkCoinsInvolved.isEmpty) {
        Logging.instance.log(
          "sparkCoinsInvolved is empty and should not be! (ignoring tx parsing)",
          level: LogLevel.Error,
        );
        continue;
      }

      // parse outputs
      final List<OutputV2> outputs = [];
      for (final outputJson in txData["vout"] as List) {
        final outMap = Map<String, dynamic>.from(outputJson as Map);
        if (outMap["scriptPubKey"]?["type"] == "lelantusmint") {
          final asm = outMap["scriptPubKey"]?["asm"] as String?;
          if (asm != null) {
            if (asm.startsWith("OP_LELANTUSJMINT")) {
              isJMint = true;
            } else if (asm.startsWith("OP_LELANTUSMINT")) {
              isMint = true;
            } else {
              Logging.instance.log(
                "Unknown mint op code found for lelantusmint tx: ${txData["txid"]}",
                level: LogLevel.Error,
              );
            }
          } else {
            Logging.instance.log(
              "ASM for lelantusmint tx: ${txData["txid"]} is null!",
              level: LogLevel.Error,
            );
          }
        }
        if (outMap["scriptPubKey"]?["type"] == "sparkmint" ||
            outMap["scriptPubKey"]?["type"] == "sparksmint") {
          final asm = outMap["scriptPubKey"]?["asm"] as String?;
          if (asm != null) {
            if (asm.startsWith("OP_SPARKMINT") ||
                asm.startsWith("OP_SPARKSMINT")) {
              isSparkMint = true;
            } else {
              Logging.instance.log(
                "Unknown mint op code found for sparkmint tx: ${txData["txid"]}",
                level: LogLevel.Error,
              );
            }
          } else {
            Logging.instance.log(
              "ASM for sparkmint tx: ${txData["txid"]} is null!",
              level: LogLevel.Error,
            );
          }
        }

        OutputV2 output = OutputV2.fromElectrumXJson(
          outMap,
          decimalPlaces: cryptoCurrency.fractionDigits,
          isFullAmountNotSats: true,
          // don't know yet if wallet owns. Need addresses first
          walletOwns: false,
        );

        // if (isSparkSpend) {
        //   // TODO?
        // } else
        if (isSparkMint) {
          if (isMySpark) {
            if (output.addresses.isEmpty &&
                output.scriptPubKeyHex.length >= 488) {
              // likely spark related
              final opByte = output.scriptPubKeyHex
                  .substring(0, 2)
                  .toUint8ListFromHex
                  .first;
              if (opByte == OP_SPARKMINT || opByte == OP_SPARKSMINT) {
                final serCoin = base64Encode(output.scriptPubKeyHex
                    .substring(2, 488)
                    .toUint8ListFromHex);
                final coin = sparkCoinsInvolved
                    .where((e) => e.serializedCoinB64!.startsWith(serCoin))
                    .firstOrNull;

                if (coin == null) {
                  // not ours
                } else {
                  output = output.copyWith(
                    walletOwns: true,
                    valueStringSats: coin.value.toString(),
                    addresses: [
                      coin.address,
                    ],
                  );
                }
              }
            }
          }
        } else if (isMint || isJMint) {
          // do nothing extra ?
        } else {
          // TODO?
        }

        // if output was to my wallet, add value to amount received
        if (receivingAddresses
            .intersection(output.addresses.toSet())
            .isNotEmpty) {
          wasReceivedInThisWallet = true;
          amountReceivedInThisWallet += output.value;
          output = output.copyWith(walletOwns: true);
        } else if (changeAddresses
            .intersection(output.addresses.toSet())
            .isNotEmpty) {
          wasReceivedInThisWallet = true;
          changeAmountReceivedInThisWallet += output.value;
          output = output.copyWith(walletOwns: true);
        } else if (isSparkMint && isMySpark) {
          wasReceivedInThisWallet = true;
          if (output.addresses.contains(sparkChangeAddress)) {
            changeAmountReceivedInThisWallet += output.value;
          } else {
            amountReceivedInThisWallet += output.value;
          }
        }

        outputs.add(output);
      }

      if (isJMint || isSparkSpend) {
        anonFees = Amount(
          rawValue: BigInt.zero,
          fractionDigits: cryptoCurrency.fractionDigits,
        );
      }

      // parse inputs
      final List<InputV2> inputs = [];
      for (final jsonInput in txData["vin"] as List) {
        final map = Map<String, dynamic>.from(jsonInput as Map);

        final List<String> addresses = [];
        String valueStringSats = "0";
        OutpointV2? outpoint;

        final coinbase = map["coinbase"] as String?;

        final txid = map["txid"] as String?;
        final vout = map["vout"] as int?;
        if (txid != null && vout != null) {
          outpoint = OutpointV2.isarCantDoRequiredInDefaultConstructor(
            txid: txid,
            vout: vout,
          );
        }

        if (isSparkSpend) {
          // anon fees
          final nFee = Decimal.tryParse(map["nFees"].toString());
          if (nFee != null) {
            final fees = Amount.fromDecimal(
              nFee,
              fractionDigits: cryptoCurrency.fractionDigits,
            );

            anonFees = anonFees! + fees;
          }
        } else if (isSparkMint) {
          final address = map["address"] as String?;
          final value = map["valueSat"] as int?;

          if (address != null && value != null) {
            valueStringSats = value.toString();
            addresses.add(address);
          }
        } else if (isMint) {
          // We should be able to assume this belongs to this wallet
          final address = map["address"] as String?;
          final value = map["valueSat"] as int?;

          if (address != null && value != null) {
            valueStringSats = value.toString();
            addresses.add(address);
          }
        } else if (isJMint) {
          // anon fees
          final nFee = Decimal.tryParse(map["nFees"].toString());
          if (nFee != null) {
            final fees = Amount.fromDecimal(
              nFee,
              fractionDigits: cryptoCurrency.fractionDigits,
            );

            anonFees = anonFees! + fees;
          }
        } else if (coinbase == null && txid != null && vout != null) {
          final inputTx = await electrumXCachedClient.getTransaction(
            txHash: txid,
            cryptoCurrency: cryptoCurrency,
          );

          final prevOutJson = Map<String, dynamic>.from(
              (inputTx["vout"] as List).firstWhere((e) => e["n"] == vout)
                  as Map);

          final prevOut = OutputV2.fromElectrumXJson(
            prevOutJson,
            decimalPlaces: cryptoCurrency.fractionDigits,
            isFullAmountNotSats: true,
            walletOwns: false, // doesn't matter here as this is not saved
          );

          valueStringSats = prevOut.valueStringSats;
          addresses.addAll(prevOut.addresses);
        } else if (coinbase == null) {
          Util.printJson(map, "NON TXID INPUT");
        }

        InputV2 input = InputV2.isarCantDoRequiredInDefaultConstructor(
          scriptSigHex: map["scriptSig"]?["hex"] as String?,
          scriptSigAsm: map["scriptSig"]?["asm"] as String?,
          sequence: map["sequence"] as int?,
          outpoint: outpoint,
          valueStringSats: valueStringSats,
          addresses: addresses,
          witness: map["witness"] as String?,
          coinbase: coinbase,
          innerRedeemScriptAsm: map["innerRedeemscriptAsm"] as String?,
          // don't know yet if wallet owns. Need addresses first
          walletOwns: false,
        );

        if (allAddressesSet.intersection(input.addresses.toSet()).isNotEmpty) {
          wasSentFromThisWallet = true;
          input = input.copyWith(walletOwns: true);
        } else if (isMySpark) {
          final lTags = map["lTags"] as List?;

          if (lTags?.isNotEmpty == true) {
            final List<SparkCoin> usedCoins = [];
            for (final tag in lTags!) {
              final components = (tag as String).split(",");
              final x = components[0].substring(1);
              final y = components[1].substring(0, components[1].length - 1);

              final hash = LibSpark.hashTag(x, y);
              usedCoins.addAll(sparkCoins.where((e) => e.lTagHash == hash));
            }

            if (usedCoins.isNotEmpty) {
              input = input.copyWith(
                addresses: usedCoins.map((e) => e.address).toList(),
                valueStringSats: usedCoins
                    .map((e) => e.value)
                    .reduce((value, element) => value += element)
                    .toString(),
                walletOwns: true,
              );
              wasSentFromThisWallet = true;
            }
          }
        }

        inputs.add(input);
      }

      final totalSpentFromWallet = inputs
          .where((e) => e.walletOwns)
          .map((e) => e.value)
          .fold(BigInt.zero, (value, element) => value + element);

      final totalReceivedInWallet = outputs
          .where((e) => e.walletOwns)
          .map((e) => e.value)
          .fold(BigInt.zero, (value, element) => value + element);

      final totalOut = outputs
          .map((e) => e.value)
          .fold(BigInt.zero, (value, element) => value + element);

      TransactionType type;
      TransactionSubType subType = TransactionSubType.none;

      // TODO integrate the following with the next bit (maybe)
      if (isSparkSpend) {
        subType = TransactionSubType.sparkSpend;
      } else if (isSparkMint) {
        subType = TransactionSubType.sparkMint;
      } else if (isMint) {
        subType = TransactionSubType.mint;
      } else if (isJMint) {
        subType = TransactionSubType.join;
      }

      // at least one input was owned by this wallet
      if (wasSentFromThisWallet) {
        type = TransactionType.outgoing;

        if (wasReceivedInThisWallet) {
          if (isSparkSpend) {
            if (totalSpentFromWallet -
                    (totalReceivedInWallet + anonFees!.raw) ==
                BigInt.zero) {
              // definitely sent all to self
              type = TransactionType.sentToSelf;
            }
          } else if (changeAmountReceivedInThisWallet +
                  amountReceivedInThisWallet ==
              totalOut) {
            // definitely sent all to self
            type = TransactionType.sentToSelf;
          } else if (amountReceivedInThisWallet == BigInt.zero) {
            // most likely just a typical send
            // do nothing here yet
          }
        }
      } else if (wasReceivedInThisWallet) {
        // only found outputs owned by this wallet
        type = TransactionType.incoming;
      } else {
        Logging.instance.log(
          "Unexpected tx found (ignoring it): $txData",
          level: LogLevel.Error,
        );
        continue;
      }

      String? otherData;
      if (anonFees != null) {
        otherData = jsonEncode(
          {
            "overrideFee": anonFees.toJsonString(),
          },
        );
      }

      final tx = TransactionV2(
        walletId: walletId,
        blockHash: txData["blockhash"] as String?,
        hash: txData["hash"] as String,
        txid: txData["txid"] as String,
        height: txData["height"] as int?,
        version: txData["version"] as int,
        timestamp: txData["blocktime"] as int? ??
            DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
        inputs: List.unmodifiable(inputs),
        outputs: List.unmodifiable(outputs),
        type: type,
        subType: subType,
        otherData: otherData,
      );

      if (_unconfirmedTxids.contains(tx.txid)) {
        if (tx.isConfirmed(await chainHeight, cryptoCurrency.minConfirms)) {
          txns.add(tx);
          _unconfirmedTxids.removeWhere((e) => e == tx.txid);
        } else {
          // don't update in db until confirmed
        }
      } else {
        txns.add(tx);
      }
    }

    await mainDB.updateOrPutTransactionV2s(txns);
  }

  @override
  Future<
      ({
        String? blockedReason,
        bool blocked,
        String? utxoLabel,
      })> checkBlockUTXO(
    Map<String, dynamic> jsonUTXO,
    String? scriptPubKeyHex,
    Map<String, dynamic>? jsonTX,
    String? utxoOwnerAddress,
  ) async {
    bool blocked = false;
    String? blockedReason;
    String? label;

    if (jsonUTXO["value"] is int) {
      // TODO: [prio=med] use special electrumx call to verify the 1000 Firo output is masternode
      blocked = Amount.fromDecimal(
            Decimal.fromInt(
              1000, // 1000 firo output is a possible master node
            ),
            fractionDigits: cryptoCurrency.fractionDigits,
          ).raw ==
          BigInt.from(jsonUTXO["value"] as int);

      if (blocked) {
        blockedReason = "Possible masternode output. "
            "Unlock and spend at your own risk.";
        label = "Possible masternode";
      }
    }

    return (blockedReason: blockedReason, blocked: blocked, utxoLabel: label);
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
              cryptoCurrency: info.coin);
          // clear blockchain info
          await mainDB.deleteWalletBlockchainData(walletId);
        }

        // lelantus
        final latestSetId = await electrumXClient.getLelantusLatestCoinId();
        final setDataMapFuture = getSetDataMap(latestSetId);
        final usedSerialNumbersFuture =
            electrumXCachedClient.getUsedCoinSerials(
          cryptoCurrency: info.coin,
        );

        // spark
        final latestSparkCoinId = await electrumXClient.getSparkLatestCoinId();
        final sparkAnonSetFuture = electrumXCachedClient.getSparkAnonymitySet(
          groupId: latestSparkCoinId.toString(),
          cryptoCurrency: info.coin,
          useOnlyCacheIfNotEmpty: false,
        );
        final sparkUsedCoinTagsFuture =
            electrumXCachedClient.getSparkUsedCoinsTags(
          cryptoCurrency: info.coin,
        );

        // receiving addresses
        Logging.instance.log(
          "checking receiving addresses...",
          level: LogLevel.Info,
        );

        final canBatch = await serverCanBatch;

        for (final type in cryptoCurrency.supportedDerivationPathTypes) {
          receiveFutures.add(
            canBatch
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
            canBatch
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
          sparkAnonSetFuture,
          sparkUsedCoinTagsFuture,
        ]);

        // lelantus
        final usedSerialsSet = (futureResults[0] as List<String>).toSet();
        final setDataMap = futureResults[1] as Map<dynamic, dynamic>;

        // spark
        final sparkAnonymitySet = futureResults[2] as Map<String, dynamic>;
        final sparkSpentCoinTags = futureResults[3] as Set<String>;

        if (Util.isDesktop) {
          await Future.wait([
            recoverLelantusWallet(
              latestSetId: latestSetId,
              usedSerialNumbers: usedSerialsSet,
              setDataMap: setDataMap,
            ),
            recoverSparkWallet(
              anonymitySet: sparkAnonymitySet,
              spentCoinTags: sparkSpentCoinTags,
            ),
          ]);
        } else {
          await recoverLelantusWallet(
            latestSetId: latestSetId,
            usedSerialNumbers: usedSerialsSet,
            setDataMap: setDataMap,
          );
          await recoverSparkWallet(
            anonymitySet: sparkAnonymitySet,
            spentCoinTags: sparkSpentCoinTags,
          );
        }
      });

      unawaited(refresh());
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

  bool get lelantusCoinIsarRescanRequired =>
      info.otherData[WalletInfoKeys.lelantusCoinIsarRescanRequired] as bool? ??
      true;

  Future<bool> firoRescanRecovery() async {
    try {
      await recover(isRescan: true);
      await info.updateOtherData(
        newEntries: {WalletInfoKeys.lelantusCoinIsarRescanRequired: false},
        isar: mainDB.isar,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
