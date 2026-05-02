import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:coinlib_flutter/coinlib_flutter.dart'
    show MessageSignature, base58Decode, P2PKH;
import 'package:crypto/crypto.dart' as crypto;
import 'package:decimal/decimal.dart';
import 'package:isar_community/isar.dart';

import '../../../db/sqlite/firo_cache.dart';
import '../../../models/input.dart';
import '../../../models/isar/models/blockchain_data/v2/input_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/output_v2.dart';
import '../../../models/isar/models/blockchain_data/v2/transaction_v2.dart';
import '../../../models/isar/models/isar_models.dart';
import '../../../models/keys/view_only_wallet_data.dart';
import '../../../utilities/amount/amount.dart';
import '../../../utilities/extensions/extensions.dart';
import '../../../utilities/firo_pro_reg_signed_message_prefix.dart';
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
import '../wallet_mixin_interfaces/spark_interface.dart';

class MasternodeInfo {
  final String proTxHash;
  final String collateralHash;
  final int collateralIndex;
  final String collateralAddress;
  final double operatorReward;
  final String serviceAddr;
  final int servicePort;
  final int registeredHeight;
  final int lastPaidHeight;
  final int posePenalty;
  final int poseRevivedHeight;
  final int poseBanHeight;
  final int revocationReason;
  final String ownerAddress;
  final String votingAddress;
  final String payoutAddress;
  final String pubKeyOperator;

  MasternodeInfo({
    required this.proTxHash,
    required this.collateralHash,
    required this.collateralIndex,
    required this.collateralAddress,
    required this.operatorReward,
    required this.serviceAddr,
    required this.servicePort,
    required this.registeredHeight,
    required this.lastPaidHeight,
    required this.posePenalty,
    required this.poseRevivedHeight,
    required this.poseBanHeight,
    required this.revocationReason,
    required this.ownerAddress,
    required this.votingAddress,
    required this.payoutAddress,
    required this.pubKeyOperator,
  });

  Map<String, String> pretty() {
    return {
      "ProTx Hash": proTxHash,
      "IP:Port": "$serviceAddr:$servicePort",
      "Status": revocationReason == 0 ? "Active" : "Revoked",
      "Registered Height": registeredHeight.toString(),
      "Last Paid Height": lastPaidHeight.toString(),
      "Payout Address": payoutAddress,
      "Owner Address": ownerAddress,
      "Voting Address": votingAddress,
      "Operator Public Key": pubKeyOperator,
      "Operator Reward": "$operatorReward %",
      "Collateral Hash": collateralHash,
      "Collateral Index": collateralIndex.toString(),
      "Collateral Address": collateralAddress,
      "Pose Penalty": posePenalty.toString(),
      "Pose Revived Height": poseRevivedHeight.toString(),
      "Pose Ban Height": poseBanHeight.toString(),
      "Revocation Reason": revocationReason.toString(),
    };
  }
}

final kMasterNodeValue = Decimal.fromInt(1000); // full value (not sats)

class FiroWallet<T extends ElectrumXCurrencyInterface> extends Bip39HDWallet<T>
    with
        ElectrumXInterface<T>,
        ExtendedKeysInterface<T>,
        SparkInterface<T>,
        CoinControlInterface<T> {
  // IMPORTANT: The order of the above mixins matters.

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
      final otherDataString = txData.tempTx!.otherData;
      final Map<dynamic, dynamic> map;
      if (otherDataString == null) {
        map = {};
      } else {
        map = jsonDecode(otherDataString) as Map? ?? {};
      }

      map[TxV2OdKeys.isInstantLock] = true;

      txData = txData.copyWith(
        tempTx: txData.tempTx!.copyWith(otherData: jsonEncode(map)),
      );

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

    final Set<String> receivingAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.receiving)
        .map((e) => convertAddressString(e.value))
        .toSet();

    final Set<String> changeAddresses = allAddressesOld
        .where((e) => e.subType == AddressSubType.change)
        .map((e) => convertAddressString(e.value))
        .toSet();

    final allAddressesSet = {...receivingAddresses, ...changeAddresses};

    Logging.instance.d(
      "firo_wallet.dart updateTransactions() allAddressesSet.length: "
      "${allAddressesSet.length}",
    );

    final List<Map<String, dynamic>> allTxHashes1 = await fetchHistory(
      allAddressesSet,
    );

    Logging.instance.d(
      "firo_wallet.dart updateTransactions() allTxHashes.length: "
      "${allTxHashes1.length}",
    );

    final Map<String, Map<String, dynamic>> allHistory = {};

    for (final item in allTxHashes1) {
      final txid = item["tx_hash"] as String;
      allHistory[txid] ??= {};
      allHistory[txid]!["height"] ??= item["height"] as int?;
    }

    final sparkCoins = await mainDB.isar.sparkCoins
        .where()
        .walletIdEqualToAnyLTagHash(walletId)
        .findAll();

    final List<Map<String, dynamic>> allTransactions = [];

    // some lelantus transactions aren't fetched via wallet addresses so they
    // will never show as confirmed in the gui.
    final unconfirmedTransactions = await mainDB.isar.transactionV2s
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .heightIsNull()
        .txidProperty()
        .findAll();
    for (final txid in unconfirmedTransactions) {
      if (allHistory[txid] == null) {
        allHistory[txid] = {};
      }
    }

    final Set<String> sparkTxids = {};
    for (final coin in sparkCoins) {
      sparkTxids.add(coin.txHash);
      if (allHistory[coin.txHash] == null) {
        allHistory[coin.txHash] = {"height": coin.height};
      }
    }

    final missing = await getSparkSpendTransactionIds();
    for (final txid in missing.map((e) => e.txid).toSet()) {
      if (allHistory[txid] == null) {
        allHistory[txid] = {};
      }
    }

    final confirmedTxidsInIsar = await mainDB.isar.transactionV2s
        .where()
        .walletIdEqualTo(walletId)
        .filter()
        .heightIsNotNull()
        .and()
        .heightGreaterThan(1)
        .txidProperty()
        .findAll();

    Logging.instance.d(
      "firo_wallet.dart updateTransactions() confirmedTxidsInIsar.length: "
      "${confirmedTxidsInIsar.length}",
    );

    // assume every tx that has a height is confirmed and remove them from the
    // list of transactions to fetch and check. This should be fine in firo.
    confirmedTxidsInIsar.forEach(allHistory.remove);

    final allTxids = allHistory.keys.toList(growable: false);

    const batchSize = 100;
    final remainder = allTxids.length % batchSize;
    final batchCount = allTxids.length ~/ batchSize;

    for (int i = 0; i < batchCount; i++) {
      final start = i * batchSize;
      final end = start + batchSize;
      Logging.instance.i("[allTxids]: Fetching batch #$i");
      final txns = await electrumXCachedClient.getBatchTransactions(
        txHashes: allTxids.sublist(start, end),
        cryptoCurrency: cryptoCurrency,
      );
      for (final tx in txns) {
        tx["height"] ??= allHistory[tx["txid"]]!["height"];
        allTransactions.add(tx);
      }
    }
    // handle remainder
    if (remainder > 0) {
      final txns = await electrumXCachedClient.getBatchTransactions(
        txHashes: allTxids.sublist(allTxids.length - remainder),
        cryptoCurrency: cryptoCurrency,
      );
      for (final tx in txns) {
        tx["height"] ??= allHistory[tx["txid"]]!["height"];
        allTransactions.add(tx);
      }
    }

    final Set<String> txInputTxidsSet = {};
    for (final txData in allTransactions) {
      for (final jsonInput in txData["vin"] as List) {
        final map = Map<String, dynamic>.from(jsonInput as Map);
        final coinbase = map["coinbase"] as String?;

        final txid = map["txid"] as String?;
        final vout = map["vout"] as int?;
        if (coinbase == null && txid != null && vout != null) {
          txInputTxidsSet.add(txid);
        }
      }
    }
    final txInputTxids = txInputTxidsSet.toList(growable: false);

    final Map<String, Map<String, dynamic>> someInputTxns = {};
    final remainder2 = txInputTxids.length % batchSize;
    for (int i = 0; i < txInputTxids.length ~/ batchSize; i++) {
      final start = i * batchSize;
      final end = start + batchSize;
      Logging.instance.i("[txInputTxids]: Fetching batch #$i");
      final txns = await electrumXCachedClient.getBatchTransactions(
        txHashes: txInputTxids.sublist(start, end),
        cryptoCurrency: cryptoCurrency,
      );
      for (final tx in txns) {
        someInputTxns[tx["txid"] as String] = tx;
      }
    }
    // handle remainder
    if (remainder2 > 0) {
      final txns = await electrumXCachedClient.getBatchTransactions(
        txHashes: txInputTxids.sublist(txInputTxids.length - remainder2),
        cryptoCurrency: cryptoCurrency,
      );
      for (final tx in txns) {
        someInputTxns[tx["txid"] as String] = tx;
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
      final bool isMySpentSpark = missing
          .where((e) => e.txid == txData["txid"])
          .isNotEmpty;

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
          "sparkCoinsInvolvedReceived is empty and should not be!"
          " (ignoring tx parsing)",
        );
        continue;
      }

      if (isMySpentSpark && sparkCoinsInvolvedSpent.isEmpty && !isMySpark) {
        Logging.instance.e(
          "sparkCoinsInvolvedSpent is empty and should not be!"
          " (ignoring tx parsing)",
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
                "Unknown mint op code found for lelantusmint tx: "
                "${txData["txid"]}",
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
                "Unknown mint op code found for sparkmint tx: "
                "${txData["txid"]}",
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
              final opByte = output.scriptPubKeyHex
                  .substring(0, 2)
                  .toUint8ListFromHex
                  .first;
              if (opByte == OP_SPARKMINT || opByte == OP_SPARKSMINT) {
                final serCoin = base64Encode(
                  output.scriptPubKeyHex.substring(2, 488).toUint8ListFromHex,
                );
                final coin = sparkCoinsInvolvedReceived
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
          spentSparkCoins = sparkCoinsInvolvedSpent
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
          // fetched earlier so ! unwrap should be ok
          final inputTx = someInputTxns[txid]!;

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
                valueStringSats: usedCoins
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
            valueStringSats: spentSparkCoins
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

      final isInstantLock = txData["instantlock"] as bool? ?? false;

      final otherData = <String, dynamic>{
        TxV2OdKeys.isInstantLock: isInstantLock,
      };

      if (anonFees != null) {
        otherData[TxV2OdKeys.overrideFee] = anonFees!.toJsonString();
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
        otherData: jsonEncode(otherData),
      );

      if (_unconfirmedTxids.contains(tx.txid)) {
        if (tx.isConfirmed(
          await chainHeight,
          cryptoCurrency.minConfirms,
          cryptoCurrency.minCoinbaseConfirms,
        )) {
          _unconfirmedTxids.removeWhere((e) => e == tx.txid);
        }
      }
      txns.add(tx);
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
      // verify the 1000 Firo output is masternode
      // Fall back to locked in case network call fails
      blocked =
          Amount.fromDecimal(
            kMasterNodeValue,
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
  Future<List<Address>> fetchAddressesForElectrumXScan() async {
    return await mainDB
        .getAddresses(walletId)
        .filter()
        .not()
        .group(
          (q) => q
              .typeEqualTo(AddressType.spark)
              .or()
              .typeEqualTo(AddressType.nonWallet)
              .or()
              .subTypeEqualTo(AddressSubType.nonWallet),
        )
        .findAll();
  }

  @override
  Future<void> recover({required bool isRescan}) async {
    if (isViewOnly && viewOnlyType != ViewOnlyWalletType.spark) {
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

        if (!isViewOnly || viewOnlyType != ViewOnlyWalletType.spark) {
          final root = await getRootHDNode();

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
        }

        // io limitations may require running these linearly instead
        final futuresResult = await Future.wait([
          Future.wait(receiveFutures),
          Future.wait(changeFutures),
        ]);

        final List<Address> addressesToStore = processGapCheckResults([
          ...futuresResult[0],
          ...futuresResult[1],
        ]);

        await mainDB.updateOrPutAddresses(addressesToStore);

        await Future.wait([updateTransactions(), updateUTXOs()]);

        await Future.wait([sparkUsedCoinTagsFuture, ...sparkAnonSetFutures]);

        await recoverSparkWallet(latestSparkCoinId: latestSparkCoinId);
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
    return (feeRatePerKB * BigInt.from(vSize) ~/ BigInt.from(1000)).toInt();
  }

  Future<String> registerMasternode(
    String ip,
    int port,
    String operatorPubKey,
    String votingAddress,
    int operatorReward,
    String payoutAddress, {
    required String collateralTxid,
    required int collateralVout,
    required String collateralAddress,
  }) async {
    final collateralAddr =
        await mainDB
            .getAddresses(walletId)
            .filter()
            .valueEqualTo(collateralAddress)
            .findFirst();
    if (collateralAddr == null || collateralAddr.derivationPath == null) {
      throw Exception(
        'Collateral address $collateralAddress not found in wallet '
        'or has no derivation path.',
      );
    }
    final collateralUtxo =
        await mainDB
            .getUTXOs(walletId)
            .filter()
            .txidEqualTo(collateralTxid)
            .and()
            .voutEqualTo(collateralVout)
            .findFirst();
    final currentChainHeight = await chainHeight;
    if (collateralUtxo == null ||
        collateralUtxo.address != collateralAddress ||
        collateralUtxo.isBlocked ||
        collateralUtxo.used == true ||
        !collateralUtxo.isConfirmed(
          currentChainHeight,
          cryptoCurrency.minConfirms,
          cryptoCurrency.minCoinbaseConfirms,
        )) {
      throw Exception(
        "Collateral outpoint is not yet confirmed/spendable. "
        "Wait for confirmations and try again.",
      );
    }
    final expectedCollateralRaw = Amount.fromDecimal(
      kMasterNodeValue,
      fractionDigits: cryptoCurrency.fractionDigits,
    ).raw.toInt();
    if (collateralUtxo.value != expectedCollateralRaw) {
      throw Exception(
        "Collateral outpoint must be exactly ${kMasterNodeValue.toString()} FIRO.",
      );
    }

    Address? ownerAddress = await getCurrentReceivingAddress();
    const maxOwnerAttempts = 32;
    for (var i = 0;
        i < maxOwnerAttempts &&
            (ownerAddress == null || ownerAddress.value == collateralAddress);
        i++) {
      await generateNewReceivingAddress();
      ownerAddress = await getCurrentReceivingAddress();
    }
    if (ownerAddress == null || ownerAddress.value == collateralAddress) {
      throw Exception(
        "Could not derive owner address distinct from collateral address.",
      );
    }

    final registrationTx = BytesBuilder();

    // nVersion (16 bit)
    registrationTx.add(
      (ByteData(2)..setInt16(0, 1, Endian.little)).buffer.asUint8List(),
    );

    // nType (16 bit)
    registrationTx.add(
      (ByteData(2)..setInt16(0, 0, Endian.little)).buffer.asUint8List(),
    );

    // nMode (16 bit)
    registrationTx.add(
      (ByteData(2)..setInt16(0, 0, Endian.little)).buffer.asUint8List(),
    );

    // collateralOutpoint.hash (256 bit) — real txid, byte-reversed
    final collateralTxidBytes =
        collateralTxid.toUint8ListFromHex.reversed.toList();
    if (collateralTxidBytes.length != 32) {
      throw Exception("Invalid collateral txid: $collateralTxid");
    }
    registrationTx.add(collateralTxidBytes);

    // collateralOutpoint.index (uint32)
    registrationTx.add(
      (ByteData(4)..setUint32(0, collateralVout, Endian.little))
          .buffer
          .asUint8List(),
    );

    // addr — IPv4-mapped IPv6 (16 bytes) + port (2 bytes big-endian)
    final ipParts = ip.split('.').map((e) => int.parse(e)).toList();
    if (ipParts.length != 4) {
      throw Exception("Invalid IP address: $ip");
    }
    for (final part in ipParts) {
      if (part < 0 || part > 255) {
        throw Exception("Invalid IP part: $part");
      }
    }
    registrationTx.add(ByteData(10).buffer.asUint8List());
    registrationTx.add([0xff, 0xff]);
    registrationTx.add(ipParts);
    if (port < 1 || port > 65535) {
      throw Exception("Invalid port: $port");
    }
    registrationTx.add(
      (ByteData(2)..setUint16(0, port, Endian.big)).buffer.asUint8List(),
    );

    // keyIDOwner (20 bytes)
    if (!cryptoCurrency.validateAddress(ownerAddress.value)) {
      throw Exception("Invalid owner address: ${ownerAddress.value}");
    }
    final ownerAddressBytes = base58Decode(ownerAddress.value);
    assert(ownerAddressBytes.length == 21);
    registrationTx.add(ownerAddressBytes.sublist(1));

    // pubKeyOperator (48 bytes)
    final operatorPubKeyBytes = operatorPubKey.toUint8ListFromHex;
    if (operatorPubKeyBytes.length != 48) {
      throw Exception("Invalid operator public key: $operatorPubKey");
    }
    registrationTx.add(operatorPubKeyBytes);

    // keyIDVoting (20 bytes)
    final String effectiveVotingAddress;
    if (votingAddress == payoutAddress) {
      throw Exception("Voting address and payout address cannot be the same.");
    } else if (votingAddress == collateralAddress) {
      throw Exception(
        "Voting address cannot be the same as the collateral address.",
      );
    } else if (votingAddress.isNotEmpty) {
      final votingType = cryptoCurrency.getAddressType(votingAddress);
      if (votingType != AddressType.p2pkh) {
        throw Exception(
          "Voting address must be a transparent P2PKH address, "
          "not a Spark or other address type.",
        );
      }
      final votingAddressBytes = base58Decode(votingAddress);
      assert(votingAddressBytes.length == 21);
      registrationTx.add(votingAddressBytes.sublist(1));
      effectiveVotingAddress = votingAddress;
    } else {
      registrationTx.add(ownerAddressBytes.sublist(1));
      effectiveVotingAddress = ownerAddress.value;
    }

    // nOperatorReward (16 bit)
    if (operatorReward < 0 || operatorReward > 10000) {
      throw Exception("Invalid operator reward: $operatorReward");
    }
    registrationTx.add(
      (ByteData(2)..setInt16(0, operatorReward, Endian.little))
          .buffer
          .asUint8List(),
    );

    // scriptPayout (variable) — must be P2PKH or P2SH per Firo consensus
    final payoutType = cryptoCurrency.getAddressType(payoutAddress);
    final Uint8List payoutScriptBytes;
    if (payoutType == AddressType.p2pkh) {
      final payoutHash = base58Decode(payoutAddress).sublist(1);
      payoutScriptBytes = P2PKH.fromHash(payoutHash).script.compiled;
    } else if (payoutType == AddressType.p2sh) {
      final payoutHash = base58Decode(payoutAddress).sublist(1);
      payoutScriptBytes = Uint8List.fromList([
        0xa9, // OP_HASH160
        0x14, // push 20 bytes
        ...payoutHash,
        0x87, // OP_EQUAL
      ]);
    } else {
      throw Exception(
        "Payout address must be a transparent P2PKH or P2SH address, "
        "not a Spark or other address type.",
      );
    }
    assert(payoutScriptBytes.length < 253);
    registrationTx.addByte(payoutScriptBytes.length);
    registrationTx.add(payoutScriptBytes);

    // --- coin selection for fee inputs only (exclude collateral UTXO) ---
    final allUtxos = await mainDB.getUTXOs(walletId).findAll();
    final feeUtxos =
        allUtxos
            .where(
              (u) =>
                  !(u.txid == collateralTxid && u.vout == collateralVout) &&
                  !u.isBlocked &&
                  u.used != true &&
                  u.isConfirmed(
                    currentChainHeight,
                    cryptoCurrency.minConfirms,
                    cryptoCurrency.minCoinbaseConfirms,
                  ),
            )
            .map((e) => StandardInput(e) as BaseInput)
            .toList();

    final partialTxData = TxData(
      overrideVersion: 3 + (1 << 16),
      feeRateAmount: cryptoCurrency.defaultFeeRate * BigInt.from(10),
      recipients: [
        TxRecipient(
          address: ownerAddress.value,
          addressType: AddressType.p2pkh,
          amount: cryptoCurrency.dustLimit,
          isChange: true,
        ),
      ],
    );

    final partialTx = await coinSelection(
      txData: partialTxData,
      // Use non-coin-control mode so unavailable UTXOs are filtered out
      // instead of causing a hard failure when any candidate is blocked
      // or not yet spendable.
      coinControl: false,
      isSendAll: false,
      isSendAllCoinControlUtxos: false,
      utxos: feeUtxos,
    );

    // inputsHash (SHA256d of serialized inputs)
    final inputsHashInput = BytesBuilder();
    for (final input in partialTx.usedUTXOs!) {
      final standardInput = input as StandardInput;
      final reversedTxidBytes =
          standardInput.utxo.txid.toUint8ListFromHex.reversed.toList();
      inputsHashInput.add(reversedTxidBytes);
      inputsHashInput.add(
        (ByteData(4)..setInt32(0, standardInput.utxo.vout, Endian.little))
            .buffer
            .asUint8List(),
      );
    }
    final inputsHash = crypto.sha256.convert(inputsHashInput.toBytes()).bytes;
    final inputsHashHash = crypto.sha256.convert(inputsHash).bytes;
    registrationTx.add(inputsHashHash);

    // --- payload hash & signature for external collateral ---
    // SerializeHash(proRegTx) with SER_GETHASH excludes vchSig.
    // The bytes built so far ARE the payload without vchSig.
    final payloadForHash = registrationTx.toBytes();
    final payloadHash =
        crypto.sha256.convert(
          crypto.sha256.convert(payloadForHash).bytes,
        ).bytes;
    // uint256::ToString() outputs bytes in reversed order
    final payloadHashHex =
        payloadHash.reversed
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();

    // MakeSignString format from Firo's providertx.cpp
    final signString =
        '$payoutAddress|$operatorReward|${ownerAddress.value}'
        '|$effectiveVotingAddress|$payloadHashHex';

    // Sign with the collateral private key
    final root = await getRootHDNode();
    final collateralKeyPair = root.derivePath(
      collateralAddr.derivationPath!.value,
    );
    final signed = MessageSignature.sign(
      key: collateralKeyPair.privateKey,
      message: signString,
      prefix: firoMessagePrefixForCoinlibSign(
        cryptoCurrency.networkParams.messagePrefix,
      ),
    );

    // vchSig — compact-size length + 65-byte compact signature
    final vchSig = signed.signature.compact;
    assert(vchSig.length == 65);
    registrationTx.addByte(vchSig.length);
    registrationTx.add(vchSig);

    // --- build, sign, and broadcast ---
    final finalTxData = partialTx.copyWith(
      vExtraData: registrationTx.toBytes(),
    );
    final finalTx = await buildTransaction(
      txData: finalTxData,
      inputsWithKeys: partialTx.usedUTXOs!,
    );

    final finalTransactionHex = finalTx.raw!;
    assert(
      finalTransactionHex.toLowerCase().contains(
        registrationTx.toBytes().toHex.toLowerCase(),
      ),
      'ProReg payload missing from signed transaction hex',
    );

    final broadcastedTxHash = await electrumXClient.broadcastTransaction(
      rawTx: finalTransactionHex,
    );
    if (broadcastedTxHash.toUint8ListFromHex.length != 32) {
      throw Exception("Failed to broadcast transaction: $broadcastedTxHash");
    }
    Logging.instance.i(
      "Successfully broadcasted masternode registration transaction: "
      "$finalTransactionHex (txid $broadcastedTxHash)",
    );

    await updateSentCachedTxData(txData: finalTx);

    return broadcastedTxHash;
  }

  Future<List<MasternodeInfo>> getMyMasternodes() async {
    final proTxHashes = await getMyMasternodeProTxHashes();

    return (await Future.wait(
      proTxHashes.map(
        (e) => Future(() async {
          try {
            final info = await electrumXClient.request(
              command: 'protx.info',
              args: [e],
            );
            return MasternodeInfo(
              proTxHash: info["proTxHash"] as String,
              collateralHash: info["collateralHash"] as String,
              collateralIndex: info["collateralIndex"] as int,
              collateralAddress: info["collateralAddress"] as String,
              operatorReward: double.parse(info["operatorReward"].toString()),
              serviceAddr: (info["state"]["service"] as String).substring(
                0,
                (info["state"]["service"] as String).lastIndexOf(":"),
              ),
              servicePort: int.parse(
                (info["state"]["service"] as String).substring(
                  (info["state"]["service"] as String).lastIndexOf(":") + 1,
                ),
              ),
              registeredHeight: info["state"]["registeredHeight"] as int,
              lastPaidHeight: info["state"]["lastPaidHeight"] as int,
              posePenalty: info["state"]["PoSePenalty"] as int,
              poseRevivedHeight: info["state"]["PoSeRevivedHeight"] as int,
              poseBanHeight: info["state"]["PoSeBanHeight"] as int,
              revocationReason: info["state"]["revocationReason"] as int,
              ownerAddress: info["state"]["ownerAddress"] as String,
              votingAddress: info["state"]["votingAddress"] as String,
              payoutAddress: info["state"]["payoutAddress"] as String,
              pubKeyOperator: info["state"]["pubKeyOperator"] as String,
            );
          } catch (err) {
            // getMyMasternodeProTxHashes() may give non-masternode txids, so
            // only log as info.
            Logging.instance.i("Error getting masternode info for $e: $err");
            return null;
          }
        }),
      ),
    )).where((e) => e != null).map((e) => e!).toList();
  }

  Future<List<String>> getMyMasternodeProTxHashes() async {
    final List<String> r = [];
    final Set<String> collateralTxids = {};
    final Set<String> resolvedCollateralTxids = {};

    final utxos = await mainDB.getUTXOs(walletId).sortByBlockHeight().findAll();
    final rawMasterNodeAmount = Amount.fromDecimal(
      kMasterNodeValue,
      fractionDigits: cryptoCurrency.fractionDigits,
    ).raw.toInt();

    for (final utxo in utxos) {
      if (utxo.value == rawMasterNodeAmount) {
        collateralTxids.add(utxo.txid);
      }
    }

    if (collateralTxids.isNotEmpty) {
      try {
        final walletTxids =
            await mainDB.isar.transactionV2s
                .where()
                .walletIdEqualTo(walletId)
                .txidProperty()
                .findAll();

        if (walletTxids.isNotEmpty) {
          final txs = await electrumXCachedClient.getBatchTransactions(
            txHashes: walletTxids.toSet().toList(growable: false),
            cryptoCurrency: cryptoCurrency,
          );

          for (final tx in txs) {
            final txid = tx["txid"]?.toString();
            final version = tx["version"];
            final type = tx["type"];
            final proReg = tx["proReg"];
            if (txid == null ||
                version != 3 ||
                type != 1 ||
                proReg is! Map) {
              continue;
            }

            final proRegMap = Map<String, dynamic>.from(proReg);
            final collateralHash = proRegMap["collateralHash"]?.toString();
            if (collateralHash != null &&
                collateralTxids.contains(collateralHash) &&
                !r.contains(txid)) {
              r.add(txid);
              resolvedCollateralTxids.add(collateralHash);
            }
          }
        }
      } catch (e) {
        Logging.instance.i(
          "Failed to resolve proTx hashes from wallet tx history: $e",
        );
      }
    }

    for (final txid in collateralTxids) {
      if (!resolvedCollateralTxids.contains(txid)) {
        r.add(txid);
      }
    }

    return r;
  }
}
