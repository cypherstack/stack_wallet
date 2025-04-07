import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:isar/isar.dart';

import '../../../db/sqlite/firo_cache.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/logger.dart';
import '../../../utilities/util.dart';
import '../../crypto_currency/crypto_currency.dart';
import '../../crypto_currency/interfaces/electrumx_currency_interface.dart';
import '../../isar/models/spark_coin.dart';
import '../../isar/models/wallet_info.dart';
import '../../models/tx_data.dart';
import '../intermediate/bip39_hd_wallet.dart';
import '../wallet_mixin_interfaces/coin_control_interface.dart';
import '../wallet_mixin_interfaces/electrumx_interface.dart';
import '../wallet_mixin_interfaces/extended_keys_interface.dart';
import '../wallet_mixin_interfaces/lelantus_interface.dart';
import '../wallet_mixin_interfaces/spark_interface.dart';

const sparkStartBlock = 819300; // (approx 18 Jan 2024)

class FiroWallet<T extends ElectrumXCurrencyInterface> extends Bip39HDWallet<T>
    with
        ElectrumXInterface<T>,
        ExtendedKeysInterface<T>,
        LelantusInterface<T>,
        SparkInterface<T>,
        CoinControlInterface<T> {
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
      Logging.instance.d("Added firo unconfirmed: ${txData.tempTx!.txid}");
    }
    return txData;
  }

  @override
  Future<void> updateTransactions() async {
    final List<Address> allAddressesOld =
        await fetchAddressesForElectrumXScan();

    final Set<String> receivingAddresses =
        allAddressesOld
            .where((e) => e.subType == AddressSubType.receiving)
            .map((e) => convertAddressString(e.value))
            .toSet();

    final Set<String> changeAddresses =
        allAddressesOld
            .where((e) => e.subType == AddressSubType.change)
            .map((e) => convertAddressString(e.value))
            .toSet();

    final allAddressesSet = {...receivingAddresses, ...changeAddresses};

    final List<Map<String, dynamic>> allTxHashes = await fetchHistory(
      allAddressesSet,
    );

    final sparkCoins =
        await mainDB.isar.sparkCoins
            .where()
            .walletIdEqualToAnyLTagHash(walletId)
            .findAll();

    final List<Map<String, dynamic>> allTransactions = [];

    // some lelantus transactions aren't fetched via wallet addresses so they
    // will never show as confirmed in the gui.
    final unconfirmedTransactions =
        await mainDB.isar.transactionV2s
            .where()
            .walletIdEqualTo(walletId)
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
        final info = {"tx_hash": tx.txid, "height": height};
        allTxHashes.add(info);
      }
    }

    final Set<String> sparkTxids = {};
    for (final coin in sparkCoins) {
      sparkTxids.add(coin.txHash);
      // check for duplicates before adding to list
      if (allTxHashes.indexWhere((e) => e["tx_hash"] == coin.txHash) == -1) {
        final info = {"tx_hash": coin.txHash, "height": coin.height};
        allTxHashes.add(info);
      }
    }

    final missing = await getSparkSpendTransactionIds();
    for (final txid in missing.map((e) => e.txid).toSet()) {
      // check for duplicates before adding to list
      if (allTxHashes.indexWhere((e) => e["tx_hash"] == txid) == -1) {
        final info = {"tx_hash": txid};
        allTxHashes.add(info);
      }
    }

    final currentHeight = await chainHeight;

    for (final txHash in allTxHashes) {
      final storedTx =
          await mainDB.isar.transactionV2s
              .where()
              .walletIdEqualTo(walletId)
              .filter()
              .txidEqualTo(txHash["tx_hash"] as String)
              .findFirst();

      if (storedTx?.isConfirmed(
            currentHeight,
            cryptoCurrency.minConfirms,
            cryptoCurrency.minCoinbaseConfirms,
          ) ==
          true) {
        // tx already confirmed, no need to process it again
        continue;
      }

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
      if (allTransactions.indexWhere(
            (e) => e["txid"] == tx["txid"] as String,
          ) ==
          -1) {
        tx["height"] ??= txHash["height"];
        allTransactions.add(tx);
      }
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
      final bool isSparkSpend = txData["type"] == 9 && txData["version"] == 3;
      final bool isMySpark = sparkTxids.contains(txData["txid"] as String);
      final bool isMySpentSpark =
          missing.where((e) => e.txid == txData["txid"]).isNotEmpty;

      final sparkCoinsInvolvedReceived = sparkCoins.where(
        (e) =>
            e.txHash == txData["txid"] ||
            missing.where((f) => e.lTagHash == f.tag).isNotEmpty,
      );

      final sparkCoinsInvolvedSpent = sparkCoins.where(
        (e) => missing.where((f) => e.lTagHash == f.tag).isNotEmpty,
      );

      if (isMySpark && sparkCoinsInvolvedReceived.isEmpty && !isMySpentSpark) {
        Logging.instance.e(
          "sparkCoinsInvolvedReceived is empty and should not be! (ignoring tx parsing)",
        );
        continue;
      }

      if (isMySpentSpark && sparkCoinsInvolvedSpent.isEmpty && !isMySpark) {
        Logging.instance.e(
          "sparkCoinsInvolvedSpent is empty and should not be! (ignoring tx parsing)",
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
              Logging.instance.d(
                "Unknown mint op code found for lelantusmint tx: ${txData["txid"]}",
              );
            }
          } else {
            Logging.instance.d(
              "ASM for lelantusmint tx: ${txData["txid"]} is null!",
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
              Logging.instance.d(
                "Unknown mint op code found for sparkmint tx: ${txData["txid"]}",
              );
            }
          } else {
            Logging.instance.d(
              "ASM for sparkmint tx: ${txData["txid"]} is null!",
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
              final opByte =
                  output.scriptPubKeyHex
                      .substring(0, 2)
                      .toUint8ListFromHex
                      .first;
              if (opByte == OP_SPARKMINT || opByte == OP_SPARKSMINT) {
                final serCoin = base64Encode(
                  output.scriptPubKeyHex.substring(2, 488).toUint8ListFromHex,
                );
                final coin =
                    sparkCoinsInvolvedReceived
                        .where((e) => e.serializedCoinB64!.startsWith(serCoin))
                        .firstOrNull;

                if (coin == null) {
                  // not ours
                } else {
                  output = output.copyWith(
                    walletOwns: true,
                    valueStringSats: coin.value.toString(),
                    addresses: [coin.address],
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

        void parseAnonFees() {
          // anon fees
          final nFee = Decimal.tryParse(map["nFees"].toString());
          if (nFee != null) {
            final fees = Amount.fromDecimal(
              nFee,
              fractionDigits: cryptoCurrency.fractionDigits,
            );

            anonFees = anonFees! + fees;
          }
        }

        List<SparkCoin>? spentSparkCoins;

        if (isMySpentSpark) {
          parseAnonFees();
          final tags = await FiroCacheCoordinator.getUsedCoinTagsFor(
            txid: txData["txid"] as String,
            network: cryptoCurrency.network,
          );
          spentSparkCoins =
              sparkCoinsInvolvedSpent
                  .where((e) => tags.contains(e.lTagHash))
                  .toList();
        } else if (isSparkSpend) {
          parseAnonFees();
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
            (inputTx["vout"] as List).firstWhere((e) => e["n"] == vout) as Map,
          );

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
              final hash = await hashTag(tag as String);
              usedCoins.addAll(sparkCoins.where((e) => e.lTagHash == hash));
            }

            if (usedCoins.isNotEmpty) {
              input = input.copyWith(
                addresses: usedCoins.map((e) => e.address).toList(),
                valueStringSats:
                    usedCoins
                        .map((e) => e.value)
                        .reduce((value, element) => value += element)
                        .toString(),
                walletOwns: true,
              );
              wasSentFromThisWallet = true;
            }
          }
        } else if (isMySpentSpark &&
            spentSparkCoins != null &&
            spentSparkCoins.isNotEmpty) {
          input = input.copyWith(
            addresses: spentSparkCoins.map((e) => e.address).toList(),
            valueStringSats:
                spentSparkCoins
                    .map((e) => e.value)
                    .fold(BigInt.zero, (p, e) => p + e)
                    .toString(),
            walletOwns: true,
          );
          wasSentFromThisWallet = true;
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
        Logging.instance.e("Unexpected tx found (ignoring it)");
        Logging.instance.d("Unexpected tx found (ignoring it): $txData");
        continue;
      }

      String? otherData;
      if (anonFees != null) {
        otherData = jsonEncode({"overrideFee": anonFees!.toJsonString()});
      }

      final tx = TransactionV2(
        walletId: walletId,
        blockHash: txData["blockhash"] as String?,
        hash: txData["hash"] as String,
        txid: txData["txid"] as String,
        height: txData["height"] as int?,
        version: txData["version"] as int,
        timestamp:
            txData["blocktime"] as int? ??
            DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
        inputs: List.unmodifiable(inputs),
        outputs: List.unmodifiable(outputs),
        type: type,
        subType: subType,
        otherData: otherData,
      );

      if (_unconfirmedTxids.contains(tx.txid)) {
        if (tx.isConfirmed(
          await chainHeight,
          cryptoCurrency.minConfirms,
          cryptoCurrency.minCoinbaseConfirms,
        )) {
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
  Future<({String? blockedReason, bool blocked, String? utxoLabel})>
  checkBlockUTXO(
    Map<String, dynamic> jsonUTXO,
    String? scriptPubKeyHex,
    Map<String, dynamic>? jsonTX,
    String? utxoOwnerAddress,
  ) async {
    bool blocked = false;
    String? blockedReason;
    String? label;

    if (jsonUTXO["value"] is int) {
      // TODO: [prio=high] use special electrumx call to verify the 1000 Firo output is masternode
      // electrumx call should exist now. Unsure if it works though
      blocked =
          Amount.fromDecimal(
            Decimal.fromInt(
              1000, // 1000 firo output is a possible master node
            ),
            fractionDigits: cryptoCurrency.fractionDigits,
          ).raw ==
          BigInt.from(jsonUTXO["value"] as int);

      if (blocked) {
        try {
          blocked = await electrumXClient.isMasterNodeCollateral(
            txid: jsonTX!["txid"] as String,
            index: jsonUTXO["tx_pos"] as int,
          );
        } catch (_) {
          // call failed, lock utxo just in case
          // it should logically already be blocked
          // but just in case
          blocked = true;
        }
      }

      if (blocked) {
        blockedReason =
            "Possible masternode collateral. "
            "Unlock and spend at your own risk.";
        label = "Possible masternode collateral";
      }
    }

    return (blockedReason: blockedReason, blocked: blocked, utxoLabel: label);
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    if (isViewOnly) {
      await recoverViewOnly(isRescan: isRescan);
      return;
    }

    // reset last checked values
    await info.updateOtherData(
      newEntries: {
        WalletInfoKeys.firoSparkCacheSetBlockHashCache: <String, String>{},
      },
      isar: mainDB.isar,
    );

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
          // clear cache
          await electrumXCachedClient.clearSharedTransactionCache(
            cryptoCurrency: info.coin,
          );
          // clear blockchain info
          await mainDB.deleteWalletBlockchainData(walletId);
        }

        // lelantus
        int? latestSetId;
        final List<Future<dynamic>> lelantusFutures = [];
        final enableLelantusScanning =
            info.otherData[WalletInfoKeys.enableLelantusScanning] as bool? ??
            false;
        if (enableLelantusScanning) {
          latestSetId = await electrumXClient.getLelantusLatestCoinId();
          lelantusFutures.add(
            electrumXCachedClient.getUsedCoinSerials(cryptoCurrency: info.coin),
          );
          lelantusFutures.add(getSetDataMap(latestSetId));
        }

        // spark
        final latestSparkCoinId = await electrumXClient.getSparkLatestCoinId();
        final List<Future<void>> sparkAnonSetFutures = [];
        for (int i = 1; i <= latestSparkCoinId; i++) {
          sparkAnonSetFutures.add(
            FiroCacheCoordinator.runFetchAndUpdateSparkAnonSetCacheForGroupId(
              i,
              electrumXClient,
              cryptoCurrency.network,
              null,
            ),
          );
        }
        final sparkUsedCoinTagsFuture =
            FiroCacheCoordinator.runFetchAndUpdateSparkUsedCoinTags(
              electrumXClient,
              cryptoCurrency.network,
            );

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

        await Future.wait([updateTransactions(), updateUTXOs()]);

        final List<Future<dynamic>> futures = [];
        if (enableLelantusScanning) {
          futures.add(lelantusFutures[0]);
          futures.add(lelantusFutures[1]);
        }
        futures.add(sparkUsedCoinTagsFuture);
        futures.addAll(sparkAnonSetFutures);

        final futureResults = await Future.wait(futures);

        // lelantus
        Set<String>? usedSerialsSet;
        Map<dynamic, dynamic>? setDataMap;
        if (enableLelantusScanning) {
          usedSerialsSet = (futureResults[0] as List<String>).toSet();
          setDataMap = futureResults[1] as Map<dynamic, dynamic>;
        }

        if (Util.isDesktop) {
          await Future.wait([
            if (enableLelantusScanning)
              recoverLelantusWallet(
                latestSetId: latestSetId!,
                usedSerialNumbers: usedSerialsSet!,
                setDataMap: setDataMap!,
              ),
            recoverSparkWallet(latestSparkCoinId: latestSparkCoinId),
          ]);
        } else {
          if (enableLelantusScanning) {
            await recoverLelantusWallet(
              latestSetId: latestSetId!,
              usedSerialNumbers: usedSerialsSet!,
              setDataMap: setDataMap!,
            );
          }
          await recoverSparkWallet(latestSparkCoinId: latestSparkCoinId);
        }
      });

      unawaited(refresh());
      Logging.instance.i(
        "Firo recover for "
        "${info.name}: ${DateTime.now().difference(start)}",
      );
    } catch (e, s) {
      Logging.instance.e(
        "Exception rethrown from electrumx_mixin recover(): ",
        error: e,
        stackTrace: s,
      );

      rethrow;
    }
  }

  @override
  Amount roughFeeEstimate(
    int inputCount,
    int outputCount,
    BigInt feeRatePerKB,
  ) {
    return Amount(
      rawValue: BigInt.from(
        ((181 * inputCount) + (34 * outputCount) + 10) *
            (feeRatePerKB.toInt() / 1000).ceil(),
      ),
      fractionDigits: cryptoCurrency.fractionDigits,
    );
  }

  @override
  int estimateTxFee({required int vSize, required BigInt feeRatePerKB}) {
    return vSize * (feeRatePerKB.toInt() / 1000).ceil();
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
