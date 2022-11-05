import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoindart/bitcoindart.dart';
import 'package:decimal/decimal.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:lelantus/lelantus.dart';
import 'package:stackwallet/electrumx_rpc/cached_electrumx.dart';
import 'package:stackwallet/electrumx_rpc/electrumx.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/lelantus_coin.dart';
import 'package:stackwallet/models/lelantus_fee_data.dart';
import 'package:stackwallet/models/models.dart' as models;
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/paymint/utxo_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/notifications_api.dart';
import 'package:stackwallet/services/price.dart';
import 'package:stackwallet/services/transaction_notification_tracker.dart';
import 'package:stackwallet/utilities/address_utils.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/fee_rate_type_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

const DUST_LIMIT = 1000;
const MINIMUM_CONFIRMATIONS = 1;
const MINT_LIMIT = 100100000000;
const int LELANTUS_VALUE_SPEND_LIMIT_PER_TRANSACTION = 5001 * 100000000;

const JMINT_INDEX = 5;
const MINT_INDEX = 2;
const TRANSACTION_LELANTUS = 8;
const ANONYMITY_SET_EMPTY_ID = 0;

const String GENESIS_HASH_MAINNET =
    "4381deb85b1b2c9843c222944b616d997516dcbd6a964e1eaf0def0830695233";
const String GENESIS_HASH_TESTNET =
    "aa22adcc12becaf436027ffe62a8fb21b234c58c23865291e5dc52cf53f64fca";

final firoNetwork = NetworkType(
    messagePrefix: '\x18Zcoin Signed Message:\n',
    bech32: 'bc',
    bip32: Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
    pubKeyHash: 0x52,
    scriptHash: 0x07,
    wif: 0xd2);

final firoTestNetwork = NetworkType(
    messagePrefix: '\x18Zcoin Signed Message:\n',
    bech32: 'bc',
    bip32: Bip32Type(public: 0x043587cf, private: 0x04358394),
    pubKeyHash: 0x41,
    scriptHash: 0xb2,
    wif: 0xb9);

// isolate

Map<ReceivePort, Isolate> isolates = {};

Future<ReceivePort> getIsolate(Map<String, dynamic> arguments) async {
  ReceivePort receivePort =
      ReceivePort(); //port for isolate to receive messages.
  arguments['sendPort'] = receivePort.sendPort;
  Logging.instance
      .log("starting isolate ${arguments['function']}", level: LogLevel.Info);
  Isolate isolate = await Isolate.spawn(executeNative, arguments);
  Logging.instance.log("isolate spawned!", level: LogLevel.Info);
  isolates[receivePort] = isolate;
  return receivePort;
}

Future<void> executeNative(Map<String, dynamic> arguments) async {
  await Logging.instance.initInIsolate();
  final sendPort = arguments['sendPort'] as SendPort;
  final function = arguments['function'] as String;
  try {
    if (function == "createJoinSplit") {
      final spendAmount = arguments['spendAmount'] as int;
      final address = arguments['address'] as String;
      final subtractFeeFromAmount = arguments['subtractFeeFromAmount'] as bool;
      final mnemonic = arguments['mnemonic'] as String;
      final index = arguments['index'] as int;
      final price = arguments['price'] as Decimal;
      final lelantusEntries =
          arguments['lelantusEntries'] as List<DartLelantusEntry>;
      final coin = arguments['coin'] as Coin;
      final network = arguments['network'] as NetworkType?;
      final locktime = arguments['locktime'] as int;
      final anonymitySets = arguments['_anonymity_sets'] as List<Map>?;
      final locale = arguments["locale"] as String;
      if (!(network == null || anonymitySets == null)) {
        var joinSplit = await isolateCreateJoinSplitTransaction(
            spendAmount,
            address,
            subtractFeeFromAmount,
            mnemonic,
            index,
            price,
            lelantusEntries,
            locktime,
            coin,
            network,
            anonymitySets,
            locale);
        sendPort.send(joinSplit);
        return;
      }
    } else if (function == "estimateJoinSplit") {
      final spendAmount = arguments['spendAmount'] as int;
      final subtractFeeFromAmount = arguments['subtractFeeFromAmount'] as bool?;
      final lelantusEntries =
          arguments['lelantusEntries'] as List<DartLelantusEntry>;
      final coin = arguments['coin'] as Coin;

      if (!(subtractFeeFromAmount == null)) {
        var feeData = await isolateEstimateJoinSplitFee(
            spendAmount, subtractFeeFromAmount, lelantusEntries, coin);
        sendPort.send(feeData);
        return;
      }
    } else if (function == "restore") {
      final latestSetId = arguments['latestSetId'] as int;
      final setDataMap = arguments['setDataMap'] as Map;
      final usedSerialNumbers = arguments['usedSerialNumbers'] as List?;
      final mnemonic = arguments['mnemonic'] as String;
      final coin = arguments['coin'] as Coin;
      final network = arguments['network'] as NetworkType?;
      if (!(usedSerialNumbers == null || network == null)) {
        var restoreData = await isolateRestore(
          mnemonic,
          coin,
          latestSetId,
          setDataMap,
          usedSerialNumbers,
          network,
        );
        sendPort.send(restoreData);
        return;
      }
    } else if (function == "isolateDerive") {
      final mnemonic = arguments['mnemonic'] as String;
      final from = arguments['from'] as int;
      final to = arguments['to'] as int;
      final network = arguments['network'] as NetworkType?;
      if (!(network == null)) {
        var derived = await isolateDerive(mnemonic, from, to, network);
        sendPort.send(derived);
        return;
      }
    }
    Logging.instance.log(
        "Error Arguments for $function not formatted correctly",
        level: LogLevel.Fatal);
    sendPort.send("Error");
  } catch (e, s) {
    Logging.instance.log(
        "An error was thrown in this isolate $function: $e\n$s",
        level: LogLevel.Error);
    sendPort.send("Error");
  } finally {
    await Logging.instance.isar?.close();
  }
}

void stop(ReceivePort port) {
  Isolate? isolate = isolates.remove(port);
  if (isolate != null) {
    Logging.instance.log('Stopping Isolate...', level: LogLevel.Info);
    isolate.kill(priority: Isolate.immediate);
    isolate = null;
  }
}

Future<Map<String, dynamic>> isolateDerive(
    String mnemonic, int from, int to, NetworkType _network) async {
  Map<String, dynamic> result = {};
  Map<String, dynamic> allReceive = {};
  Map<String, dynamic> allChange = {};
  final root = getBip32Root(mnemonic, _network);
  for (int i = from; i < to; i++) {
    var currentNode = getBip32NodeFromRoot(0, i, root);
    var address = P2PKH(
            network: _network, data: PaymentData(pubkey: currentNode.publicKey))
        .data
        .address!;
    allReceive["$i"] = {
      "publicKey": Format.uint8listToString(currentNode.publicKey),
      "wif": currentNode.toWIF(),
      "address": address,
    };

    currentNode = getBip32NodeFromRoot(1, i, root);
    address = P2PKH(
            network: _network, data: PaymentData(pubkey: currentNode.publicKey))
        .data
        .address!;
    allChange["$i"] = {
      "publicKey": Format.uint8listToString(currentNode.publicKey),
      "wif": currentNode.toWIF(),
      "address": address,
    };
    if (i % 50 == 0) {
      Logging.instance.log("thread at $i", level: LogLevel.Info);
    }
  }
  result['receive'] = allReceive;
  result['change'] = allChange;
  return result;
}

Future<Map<String, dynamic>> isolateRestore(
  String mnemonic,
  Coin coin,
  int _latestSetId,
  Map<dynamic, dynamic> _setDataMap,
  List<dynamic> _usedSerialNumbers,
  NetworkType network,
) async {
  List<int> jindexes = [];
  List<Map<dynamic, LelantusCoin>> lelantusCoins = [];

  final List<String> spendTxIds = [];
  var lastFoundIndex = 0;
  var currentIndex = 0;

  try {
    final usedSerialNumbers = _usedSerialNumbers;
    Set<dynamic> usedSerialNumbersSet = {};
    for (int ind = 0; ind < usedSerialNumbers.length; ind++) {
      usedSerialNumbersSet.add(usedSerialNumbers[ind]);
    }

    final root = getBip32Root(mnemonic, network);
    while (currentIndex < lastFoundIndex + 50) {
      final mintKeyPair = getBip32NodeFromRoot(MINT_INDEX, currentIndex, root);
      final mintTag = CreateTag(
          Format.uint8listToString(mintKeyPair.privateKey!),
          currentIndex,
          Format.uint8listToString(mintKeyPair.identifier),
          isTestnet: coin == Coin.firoTestNet);

      for (var setId = 1; setId <= _latestSetId; setId++) {
        final setData = _setDataMap[setId];
        final foundCoin = setData["coins"].firstWhere(
            (dynamic e) => e[1] == mintTag,
            orElse: () => <Object>[]);

        if (foundCoin.length == 4) {
          lastFoundIndex = currentIndex;
          if (foundCoin[2] is int) {
            final amount = foundCoin[2] as int;
            final serialNumber = GetSerialNumber(amount,
                Format.uint8listToString(mintKeyPair.privateKey!), currentIndex,
                isTestnet: coin == Coin.firoTestNet);
            String publicCoin = foundCoin[0] as String;
            String txId = foundCoin[3] as String;
            bool isUsed = usedSerialNumbersSet.contains(serialNumber);
            final duplicateCoin = lelantusCoins.firstWhere((element) {
              final coin = element.values.first;
              return coin.txId == txId &&
                  coin.index == currentIndex &&
                  coin.anonymitySetId != setId;
            }, orElse: () => {});
            if (duplicateCoin.isNotEmpty) {
              debugPrint("removing duplicate: $duplicateCoin");
              lelantusCoins.remove(duplicateCoin);
            }
            lelantusCoins.add({
              publicCoin: LelantusCoin(
                currentIndex,
                amount,
                publicCoin,
                txId,
                setId,
                isUsed,
              )
            });
            Logging.instance
                .log("amount $amount used $isUsed", level: LogLevel.Info);
          } else {
            final keyPath = GetAesKeyPath(foundCoin[0] as String);
            final aesKeyPair = getBip32NodeFromRoot(JMINT_INDEX, keyPath, root);
            if (aesKeyPair.privateKey != null) {
              final aesPrivateKey =
                  Format.uint8listToString(aesKeyPair.privateKey!);
              final amount = decryptMintAmount(
                aesPrivateKey,
                foundCoin[2] as String,
              );

              final serialNumber = GetSerialNumber(
                  amount,
                  Format.uint8listToString(mintKeyPair.privateKey!),
                  currentIndex,
                  isTestnet: coin == Coin.firoTestNet);
              String publicCoin = foundCoin[0] as String;
              String txId = foundCoin[3] as String;
              bool isUsed = usedSerialNumbersSet.contains(serialNumber);
              final duplicateCoin = lelantusCoins.firstWhere((element) {
                final coin = element.values.first;
                return coin.txId == txId &&
                    coin.index == currentIndex &&
                    coin.anonymitySetId != setId;
              }, orElse: () => {});
              if (duplicateCoin.isNotEmpty) {
                debugPrint("removing duplicate: $duplicateCoin");
                lelantusCoins.remove(duplicateCoin);
              }
              lelantusCoins.add({
                '${foundCoin[3]!}': LelantusCoin(
                  currentIndex,
                  amount,
                  publicCoin,
                  txId,
                  setId,
                  isUsed,
                )
              });
              jindexes.add(currentIndex);

              spendTxIds.add(foundCoin[3] as String);
            }
          }
        }
      }

      currentIndex++;
    }
  } catch (e, s) {
    Logging.instance.log("Exception rethrown from isolateRestore(): $e\n$s",
        level: LogLevel.Info);
    rethrow;
  }

  Map<String, dynamic> result = {};
  // Logging.instance.log("mints $lelantusCoins", addToDebugMessagesDB: false);
  // Logging.instance.log("jmints $spendTxIds", addToDebugMessagesDB: false);

  result['_lelantus_coins'] = lelantusCoins;
  result['mintIndex'] = lastFoundIndex + 1;
  result['jindex'] = jindexes;
  result['spendTxIds'] = spendTxIds;

  return result;
}

Future<Map<dynamic, dynamic>> staticProcessRestore(
  models.TransactionData data,
  Map<dynamic, dynamic> result,
) async {
  List<dynamic>? _l = result['_lelantus_coins'] as List?;
  final List<Map<dynamic, LelantusCoin>> lelantusCoins = [];
  for (var el in _l ?? []) {
    lelantusCoins.add({el.keys.first: el.values.first as LelantusCoin});
  }

  // Edit the receive transactions with the mint fees.
  Map<String, models.Transaction> editedTransactions =
      <String, models.Transaction>{};
  for (var item in lelantusCoins) {
    item.forEach((key, value) {
      String txid = value.txId;
      var tx = data.findTransaction(txid);
      if (tx == null) {
        // This is a jmint.
        return;
      }
      List<models.Transaction> inputs = [];
      for (var element in tx.inputs) {
        var input = data.findTransaction(element.txid);
        if (input != null) {
          inputs.add(input);
        }
      }
      if (inputs.isEmpty) {
        //some error.
        return;
      }

      int mintfee = tx.fees;
      int sharedfee = mintfee ~/ inputs.length;
      for (var element in inputs) {
        editedTransactions[element.txid] = models.Transaction(
          txid: element.txid,
          confirmedStatus: element.confirmedStatus,
          timestamp: element.timestamp,
          txType: element.txType,
          amount: element.amount,
          aliens: element.aliens,
          worthNow: element.worthNow,
          worthAtBlockTimestamp: element.worthAtBlockTimestamp,
          fees: sharedfee,
          inputSize: element.inputSize,
          outputSize: element.outputSize,
          inputs: element.inputs,
          outputs: element.outputs,
          address: element.address,
          height: element.height,
          confirmations: element.confirmations,
          subType: "mint",
          otherData: txid,
        );
      }
    });
  }
  // Logging.instance.log(editedTransactions, addToDebugMessagesDB: false);

  Map<String, models.Transaction> transactionMap = data.getAllTransactions();
  // Logging.instance.log(transactionMap, addToDebugMessagesDB: false);

  editedTransactions.forEach((key, value) {
    transactionMap.update(key, (_value) => value);
  });

  transactionMap.removeWhere((key, value) =>
      lelantusCoins.any((element) => element.containsKey(key)) ||
      (value.height == -1 && !value.confirmedStatus));

  result['newTxMap'] = transactionMap;
  return result;
}

Future<LelantusFeeData> isolateEstimateJoinSplitFee(
    int spendAmount,
    bool subtractFeeFromAmount,
    List<DartLelantusEntry> lelantusEntries,
    Coin coin) async {
  Logging.instance.log("estimateJoinsplit fee", level: LogLevel.Info);
  // for (int i = 0; i < lelantusEntries.length; i++) {
  //   Logging.instance.log(lelantusEntries[i], addToDebugMessagesDB: false);
  // }
  Logging.instance
      .log("$spendAmount $subtractFeeFromAmount", level: LogLevel.Info);

  List<int> changeToMint = List.empty(growable: true);
  List<int> spendCoinIndexes = List.empty(growable: true);
  // Logging.instance.log(lelantusEntries, addToDebugMessagesDB: false);
  final fee = estimateFee(
    spendAmount,
    subtractFeeFromAmount,
    lelantusEntries,
    changeToMint,
    spendCoinIndexes,
    isTestnet: coin == Coin.firoTestNet,
  );

  final estimateFeeData =
      LelantusFeeData(changeToMint[0], fee, spendCoinIndexes);
  Logging.instance.log(
      "estimateFeeData ${estimateFeeData.changeToMint} ${estimateFeeData.fee} ${estimateFeeData.spendCoinIndexes}",
      level: LogLevel.Info);
  return estimateFeeData;
}

Future<dynamic> isolateCreateJoinSplitTransaction(
  int spendAmount,
  String address,
  bool subtractFeeFromAmount,
  String mnemonic,
  int index,
  Decimal price,
  List<DartLelantusEntry> lelantusEntries,
  int locktime,
  Coin coin,
  NetworkType _network,
  List<Map<dynamic, dynamic>> anonymitySetsArg,
  String locale,
) async {
  final estimateJoinSplitFee = await isolateEstimateJoinSplitFee(
      spendAmount, subtractFeeFromAmount, lelantusEntries, coin);
  var changeToMint = estimateJoinSplitFee.changeToMint;
  var fee = estimateJoinSplitFee.fee;
  var spendCoinIndexes = estimateJoinSplitFee.spendCoinIndexes;
  Logging.instance
      .log("$changeToMint $fee $spendCoinIndexes", level: LogLevel.Info);
  if (spendCoinIndexes.isEmpty) {
    Logging.instance.log("Error, Not enough funds.", level: LogLevel.Error);
    return 1;
  }

  final tx = TransactionBuilder(network: _network);
  tx.setLockTime(locktime);

  tx.setVersion(3 | (TRANSACTION_LELANTUS << 16));

  tx.addInput(
    '0000000000000000000000000000000000000000000000000000000000000000',
    4294967295,
    4294967295,
    Uint8List(0),
  );

  final jmintKeyPair = getBip32Node(MINT_INDEX, index, mnemonic, _network);

  final String jmintprivatekey =
      Format.uint8listToString(jmintKeyPair.privateKey!);

  final keyPath = getMintKeyPath(changeToMint, jmintprivatekey, index,
      isTestnet: coin == Coin.firoTestNet);

  final aesKeyPair = getBip32Node(JMINT_INDEX, keyPath, mnemonic, _network);
  final aesPrivateKey = Format.uint8listToString(aesKeyPair.privateKey!);

  final jmintData = createJMintScript(
    changeToMint,
    Format.uint8listToString(jmintKeyPair.privateKey!),
    index,
    Format.uint8listToString(jmintKeyPair.identifier),
    aesPrivateKey,
    isTestnet: coin == Coin.firoTestNet,
  );

  tx.addOutput(
    Format.stringToUint8List(jmintData),
    0,
  );

  int amount = spendAmount;
  if (subtractFeeFromAmount) {
    amount -= fee;
  }
  tx.addOutput(
    address,
    amount,
  );

  final extractedTx = tx.buildIncomplete();
  extractedTx.setPayload(Uint8List(0));
  final txHash = extractedTx.getId();

  final List<int> setIds = [];
  final List<List<String>> anonymitySets = [];
  final List<String> anonymitySetHashes = [];
  final List<String> groupBlockHashes = [];
  for (var i = 0; i < lelantusEntries.length; i++) {
    final anonymitySetId = lelantusEntries[i].anonymitySetId;
    if (!setIds.contains(anonymitySetId)) {
      setIds.add(anonymitySetId);
      final anonymitySet = anonymitySetsArg.firstWhere(
          (element) => element["setId"] == anonymitySetId,
          orElse: () => <String, dynamic>{});
      if (anonymitySet.isNotEmpty) {
        anonymitySetHashes.add(anonymitySet['setHash'] as String);
        groupBlockHashes.add(anonymitySet['blockHash'] as String);
        List<String> list = [];
        for (int i = 0; i < (anonymitySet['coins'] as List).length; i++) {
          list.add(anonymitySet['coins'][i][0] as String);
        }
        anonymitySets.add(list);
      }
    }
  }

  final String spendScript = createJoinSplitScript(
      txHash,
      spendAmount,
      subtractFeeFromAmount,
      Format.uint8listToString(jmintKeyPair.privateKey!),
      index,
      lelantusEntries,
      setIds,
      anonymitySets,
      anonymitySetHashes,
      groupBlockHashes,
      isTestnet: coin == Coin.firoTestNet);

  final finalTx = TransactionBuilder(network: _network);
  finalTx.setLockTime(locktime);

  finalTx.setVersion(3 | (TRANSACTION_LELANTUS << 16));

  finalTx.addOutput(
    Format.stringToUint8List(jmintData),
    0,
  );

  finalTx.addOutput(
    address,
    amount,
  );

  final extTx = finalTx.buildIncomplete();
  extTx.addInput(
    Format.stringToUint8List(
        '0000000000000000000000000000000000000000000000000000000000000000'),
    4294967295,
    4294967295,
    Format.stringToUint8List("c9"),
  );
  debugPrint("spendscript: $spendScript");
  extTx.setPayload(Format.stringToUint8List(spendScript));

  final txHex = extTx.toHex();
  final txId = extTx.getId();
  Logging.instance.log("txid  $txId", level: LogLevel.Info);
  Logging.instance.log("txHex: $txHex", level: LogLevel.Info);
  return {
    "txid": txId,
    "txHex": txHex,
    "value": amount,
    "fees": Format.satoshisToAmount(fee).toDouble(),
    "fee": fee,
    "vSize": extTx.virtualSize(),
    "jmintValue": changeToMint,
    "publicCoin": "jmintData.publicCoin",
    "spendCoinIndexes": spendCoinIndexes,
    "height": locktime,
    "txType": "Sent",
    "confirmed_status": false,
    "amount": Format.satoshisToAmount(amount).toDouble(),
    "recipientAmt": amount,
    "worthNow": Format.localizedStringAsFixed(
        value: ((Decimal.fromInt(amount) * price) /
                Decimal.fromInt(Constants.satsPerCoin))
            .toDecimal(scaleOnInfinitePrecision: 2),
        decimalPlaces: 2,
        locale: locale),
    "address": address,
    "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
    "subType": "join",
  };
}

Future<int> getBlockHead(ElectrumX client) async {
  try {
    final tip = await client.getBlockHeadTip();
    return tip["height"] as int;
  } catch (e) {
    Logging.instance
        .log("Exception rethrown in getBlockHead(): $e", level: LogLevel.Error);
    rethrow;
  }
}
// end of isolates

bip32.BIP32 getBip32Node(
    int chain, int index, String mnemonic, NetworkType network) {
  final root = getBip32Root(mnemonic, network);

  final node = getBip32NodeFromRoot(chain, index, root);
  return node;
}

/// wrapper for compute()
bip32.BIP32 getBip32NodeWrapper(
  Tuple4<int, int, String, NetworkType> args,
) {
  return getBip32Node(
    args.item1,
    args.item2,
    args.item3,
    args.item4,
  );
}

bip32.BIP32 getBip32NodeFromRoot(int chain, int index, bip32.BIP32 root) {
  String coinType;
  switch (root.network.wif) {
    case 0xd2: // firo mainnet wif
      coinType = "136"; // firo mainnet
      break;
    case 0xb9: // firo testnet wif
      coinType = "1"; // firo testnet
      break;
    default:
      throw Exception("Invalid Bitcoin network type used!");
  }

  final node = root.derivePath("m/44'/$coinType'/0'/$chain/$index");
  return node;
}

/// wrapper for compute()
bip32.BIP32 getBip32NodeFromRootWrapper(
  Tuple3<int, int, bip32.BIP32> args,
) {
  return getBip32NodeFromRoot(
    args.item1,
    args.item2,
    args.item3,
  );
}

bip32.BIP32 getBip32Root(String mnemonic, NetworkType network) {
  final seed = bip39.mnemonicToSeed(mnemonic);
  final firoNetworkType = bip32.NetworkType(
    wif: network.wif,
    bip32: bip32.Bip32Type(
      public: network.bip32.public,
      private: network.bip32.private,
    ),
  );

  final root = bip32.BIP32.fromSeed(seed, firoNetworkType);
  return root;
}

/// wrapper for compute()
bip32.BIP32 getBip32RootWrapper(Tuple2<String, NetworkType> args) {
  return getBip32Root(args.item1, args.item2);
}

Future<String> _getMintScriptWrapper(
    Tuple5<int, String, int, String, bool> data) async {
  String mintHex = getMintScript(data.item1, data.item2, data.item3, data.item4,
      isTestnet: data.item5);
  return mintHex;
}

Future<void> _setTestnetWrapper(bool isTestnet) async {
  // setTestnet(isTestnet);
}

Future<Map<String, dynamic>?> getInitialAnonymitySetCache(
  String groupID,
) async {
  Logging.instance.log("getInitialAnonymitySetCache", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse("$kStackCommunityNodesEndpoint/getAnonymity");

    final anonSetResult = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": "0",
        'aset': groupID,
      }),
    );

    final response = jsonDecode(anonSetResult.body.toString());
    Logging.instance.log(response, level: LogLevel.Info);
    if (response['status'] == 'success') {
      final anonResponse = jsonDecode(response['result'] as String);

      final setData = Map<String, dynamic>.from(anonResponse as Map);
      return setData;
    } else {
      return null;
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return null;
  }
}

/// Handles a single instance of a firo wallet
class FiroWallet extends CoinServiceAPI {
  static const integrationTestFlag =
      bool.fromEnvironment("IS_INTEGRATION_TEST");

  final _prefs = Prefs.instance;

  Timer? timer;
  late Coin _coin;

  bool _shouldAutoSync = false;

  @override
  bool get shouldAutoSync => _shouldAutoSync;

  @override
  set shouldAutoSync(bool shouldAutoSync) {
    if (_shouldAutoSync != shouldAutoSync) {
      _shouldAutoSync = shouldAutoSync;
      if (!shouldAutoSync) {
        timer?.cancel();
        timer = null;
        stopNetworkAlivePinging();
      } else {
        startNetworkAlivePinging();
        refresh();
      }
    }
  }

  NetworkType get _network {
    switch (coin) {
      case Coin.firo:
        return firoNetwork;
      case Coin.firoTestNet:
        return firoTestNetwork;
      default:
        throw Exception("Invalid network type!");
    }
  }

  @override
  set isFavorite(bool markFavorite) {
    DB.instance.put<dynamic>(
        boxName: walletId, key: "isFavorite", value: markFavorite);
  }

  @override
  bool get isFavorite {
    try {
      return DB.instance.get<dynamic>(boxName: walletId, key: "isFavorite")
          as bool;
    } catch (e, s) {
      Logging.instance.log(
          "isFavorite fetch failed (returning false by default): $e\n$s",
          level: LogLevel.Error);
      return false;
    }
  }

  @override
  Coin get coin => _coin;

  // @override
  // String get coinName =>
  //     networkType == BasicNetworkType.main ? "Firo" : "tFiro";
  //
  // @override
  // String get coinTicker =>
  //     networkType == BasicNetworkType.main ? "FIRO" : "tFIRO";

  @override
  Future<List<String>> get mnemonic => _getMnemonicList();

  // index 0 and 1 for the funds available to spend.
  // index 2 and 3 for all the funds in the wallet (including the undependable ones)
  @override
  Future<Decimal> get availableBalance async {
    final balances = await this.balances;
    return balances[0];
  }

  // index 0 and 1 for the funds available to spend.
  // index 2 and 3 for all the funds in the wallet (including the undependable ones)
  @override
  Future<Decimal> get pendingBalance async {
    final balances = await this.balances;
    return balances[2] - balances[0];
  }

  // index 0 and 1 for the funds available to spend.
  // index 2 and 3 for all the funds in the wallet (including the undependable ones)
  @override
  Future<Decimal> get totalBalance async {
    if (!isActive) {
      final totalBalance = DB.instance
          .get<dynamic>(boxName: walletId, key: 'totalBalance') as String?;
      if (totalBalance == null) {
        final balances = await this.balances;
        return balances[2];
      } else {
        return Decimal.parse(totalBalance);
        // the following caused a crash as it seems totalBalance here
        // is a string. Gotta love dynamics
        // return Format.satoshisToAmount(totalBalance);
      }
    }
    final balances = await this.balances;
    return balances[2];
  }

  /// return spendable balance minus the maximum tx fee
  @override
  Future<Decimal> get balanceMinusMaxFee async {
    final balances = await this.balances;
    final maxFee = await this.maxFee;
    return balances[0] - Format.satoshisToAmount(maxFee);
  }

  @override
  Future<models.TransactionData> get transactionData => lelantusTransactionData;

  @override
  bool validateAddress(String address) {
    return Address.validateAddress(address, _network);
  }

  /// Holds final balances, all utxos under control
  Future<UtxoData>? _utxoData;
  Future<UtxoData> get utxoData => _utxoData ??= _fetchUtxoData();

  @override
  Future<List<UtxoObject>> get unspentOutputs async =>
      (await utxoData).unspentOutputArray;

  /// Holds wallet transaction data
  Future<models.TransactionData>? _transactionData;
  Future<models.TransactionData> get _txnData =>
      _transactionData ??= _fetchTransactionData();

  /// Holds wallet lelantus transaction data
  Future<models.TransactionData>? _lelantusTransactionData;
  Future<models.TransactionData> get lelantusTransactionData =>
      _lelantusTransactionData ??= _getLelantusTransactionData();

  /// Holds the max fee that can be sent
  Future<int>? _maxFee;
  @override
  Future<int> get maxFee => _maxFee ??= _fetchMaxFee();

  /// Holds the current balance data
  Future<List<Decimal>>? _balances;
  Future<List<Decimal>> get balances => _balances ??= _getFullBalance();

  /// Holds all outputs for wallet, used for displaying utxos in app security view
  List<UtxoObject> _outputsList = [];

  Future<Decimal> get firoPrice async {
    final data =
        await _priceAPI.getPricesAnd24hChange(baseCurrency: _prefs.currency);
    if (coin == Coin.firoTestNet) {
      return data[Coin.firo]!.item1;
    }
    return data[coin]!.item1;
  }

  // currently isn't used but required due to abstract parent class
  Future<FeeObject>? _feeObject;
  @override
  Future<FeeObject> get fees => _feeObject ??= _getFees();

  /// Holds updated receiving address
  Future<String>? _currentReceivingAddress;
  @override
  Future<String> get currentReceivingAddress =>
      _currentReceivingAddress ??= _getCurrentAddressForChain(0);

  // @override
  // Future<String> get currentLegacyReceivingAddress => null;

  late String _walletName;
  @override
  String get walletName => _walletName;

  // setter for updating on rename
  @override
  set walletName(String newName) => _walletName = newName;

  /// unique wallet id
  late String _walletId;
  @override
  String get walletId => _walletId;

  Future<List<String>>? _allOwnAddresses;
  @override
  Future<List<String>> get allOwnAddresses =>
      _allOwnAddresses ??= _fetchAllOwnAddresses();

  @override
  Future<bool> testNetworkConnection() async {
    try {
      final result = await _electrumXClient.ping();
      return result;
    } catch (_) {
      return false;
    }
  }

  Timer? _networkAliveTimer;

  void startNetworkAlivePinging() {
    // call once on start right away
    _periodicPingCheck();

    // then periodically check
    _networkAliveTimer = Timer.periodic(
      Constants.networkAliveTimerDuration,
      (_) async {
        _periodicPingCheck();
      },
    );
  }

  void _periodicPingCheck() async {
    bool hasNetwork = await testNetworkConnection();
    _isConnected = hasNetwork;
    if (_isConnected != hasNetwork) {
      NodeConnectionStatus status = hasNetwork
          ? NodeConnectionStatus.connected
          : NodeConnectionStatus.disconnected;
      GlobalEventBus.instance
          .fire(NodeConnectionStatusChangedEvent(status, walletId, coin));
    }
  }

  void stopNetworkAlivePinging() {
    _networkAliveTimer?.cancel();
    _networkAliveTimer = null;
  }

  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected;

  Future<Map<String, dynamic>> prepareSendPublic({
    required String address,
    required int satoshiAmount,
    Map<String, dynamic>? args,
  }) async {
    try {
      final feeRateType = args?["feeRate"];
      final feeRateAmount = args?["feeRateAmount"];
      if (feeRateType is FeeRateType || feeRateAmount is int) {
        late final int rate;
        if (feeRateType is FeeRateType) {
          int fee = 0;
          final feeObject = await fees;
          switch (feeRateType) {
            case FeeRateType.fast:
              fee = feeObject.fast;
              break;
            case FeeRateType.average:
              fee = feeObject.medium;
              break;
            case FeeRateType.slow:
              fee = feeObject.slow;
              break;
          }
          rate = fee;
        } else {
          rate = feeRateAmount as int;
        }

        // check for send all
        bool isSendAll = false;
        final balance =
            Format.decimalAmountToSatoshis(await availablePublicBalance());
        if (satoshiAmount == balance) {
          isSendAll = true;
        }

        final txData =
            await coinSelection(satoshiAmount, rate, address, isSendAll);

        Logging.instance.log("prepare send: $txData", level: LogLevel.Info);
        try {
          if (txData is int) {
            switch (txData) {
              case 1:
                throw Exception("Insufficient balance!");
              case 2:
                throw Exception(
                    "Insufficient funds to pay for transaction fee!");
              default:
                throw Exception("Transaction failed with error code $txData");
            }
          } else {
            final hex = txData["hex"];

            if (hex is String) {
              final fee = txData["fee"] as int;
              final vSize = txData["vSize"] as int;

              Logging.instance
                  .log("prepared txHex: $hex", level: LogLevel.Info);
              Logging.instance.log("prepared fee: $fee", level: LogLevel.Info);
              Logging.instance
                  .log("prepared vSize: $vSize", level: LogLevel.Info);

              // fee should never be less than vSize sanity check
              if (fee < vSize) {
                throw Exception(
                    "Error in fee calculation: Transaction fee cannot be less than vSize");
              }

              return txData as Map<String, dynamic>;
            } else {
              throw Exception("prepared hex is not a String!!!");
            }
          }
        } catch (e, s) {
          Logging.instance.log("Exception rethrown from prepareSend(): $e\n$s",
              level: LogLevel.Error);
          rethrow;
        }
      } else {
        throw ArgumentError("Invalid fee rate argument provided!");
      }
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from prepareSend(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<String> confirmSendPublic({dynamic txData}) async {
    try {
      Logging.instance.log("confirmSend txData: $txData", level: LogLevel.Info);
      final txHash = await _electrumXClient.broadcastTransaction(
          rawTx: txData["hex"] as String);
      Logging.instance.log("Sent txHash: $txHash", level: LogLevel.Info);
      return txHash;
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from confirmSend(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> prepareSend({
    required String address,
    required int satoshiAmount,
    Map<String, dynamic>? args,
  }) async {
    try {
      // check for send all
      bool isSendAll = false;
      final balance =
          Format.decimalAmountToSatoshis(await availablePrivateBalance());
      if (satoshiAmount == balance) {
        // print("is send all");
        isSendAll = true;
      }
      dynamic txHexOrError =
          await _createJoinSplitTransaction(satoshiAmount, address, isSendAll);
      Logging.instance.log("txHexOrError $txHexOrError", level: LogLevel.Error);
      if (txHexOrError is int) {
        // Here, we assume that transaction crafting returned an error
        switch (txHexOrError) {
          case 1:
            throw Exception("Insufficient balance!");
          default:
            throw Exception("Error Creating Transaction!");
        }
      } else {
        final fee = txHexOrError["fee"] as int;
        final vSize = txHexOrError["vSize"] as int;

        Logging.instance.log("prepared fee: $fee", level: LogLevel.Info);
        Logging.instance.log("prepared vSize: $vSize", level: LogLevel.Info);

        // fee should never be less than vSize sanity check
        if (fee < vSize) {
          throw Exception(
              "Error in fee calculation: Transaction fee cannot be less than vSize");
        }
        return txHexOrError as Map<String, dynamic>;
      }
    } catch (e, s) {
      Logging.instance.log("Exception rethrown in firo prepareSend(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    if (await _submitLelantusToNetwork(txData)) {
      try {
        final txid = txData["txid"] as String;

        // temporarily update apdate available balance until a full refresh is done

        // TODO: something here causes an exception to be thrown giving user false info that the tx failed
        Decimal sendTotal = Format.satoshisToAmount(txData["value"] as int);
        sendTotal += Decimal.parse(txData["fees"].toString());
        final bals = await balances;
        bals[0] -= sendTotal;
        _balances = Future(() => bals);

        return txid;
      } catch (e, s) {
        debugPrint("$e $s");
        return txData["txid"] as String;
        // don't throw anything here or it will tell the user that th tx
        // failed even though it was successfully broadcast to network
        // throw Exception("Transaction failed.");
      }
    } else {
      //TODO provide more info
      throw Exception("Transaction failed.");
    }
  }

  /// returns txid on successful send
  ///
  /// can throw
  @override
  Future<String> send({
    required String toAddress,
    required int amount,
    Map<String, String> args = const {},
  }) async {
    try {
      dynamic txHexOrError =
          await _createJoinSplitTransaction(amount, toAddress, false);
      Logging.instance.log("txHexOrError $txHexOrError", level: LogLevel.Error);
      if (txHexOrError is int) {
        // Here, we assume that transaction crafting returned an error
        switch (txHexOrError) {
          case 1:
            throw Exception("Insufficient balance!");
          default:
            throw Exception("Error Creating Transaction!");
        }
      } else {
        if (await _submitLelantusToNetwork(
            txHexOrError as Map<String, dynamic>)) {
          final txid = txHexOrError["txid"] as String;

          // temporarily update apdate available balance until a full refresh is done
          Decimal sendTotal =
              Format.satoshisToAmount(txHexOrError["value"] as int);
          sendTotal += Decimal.parse(txHexOrError["fees"].toString());
          final bals = await balances;
          bals[0] -= sendTotal;
          _balances = Future(() => bals);

          return txid;
        } else {
          //TODO provide more info
          throw Exception("Transaction failed.");
        }
      }
    } catch (e, s) {
      Logging.instance.log("Exception rethrown in firo send(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<List<String>> _getMnemonicList() async {
    final mnemonicString =
        await _secureStore.read(key: '${_walletId}_mnemonic');
    if (mnemonicString == null) {
      return [];
    }
    final List<String> data = mnemonicString.split(' ');
    return data;
  }

  late ElectrumX _electrumXClient;
  ElectrumX get electrumXClient => _electrumXClient;

  late CachedElectrumX _cachedElectrumXClient;
  CachedElectrumX get cachedElectrumXClient => _cachedElectrumXClient;

  late FlutterSecureStorageInterface _secureStore;

  late PriceAPI _priceAPI;

  late TransactionNotificationTracker txTracker;

  // Constructor
  FiroWallet({
    required String walletId,
    required String walletName,
    required Coin coin,
    required ElectrumX client,
    required CachedElectrumX cachedClient,
    required TransactionNotificationTracker tracker,
    PriceAPI? priceAPI,
    FlutterSecureStorageInterface? secureStore,
  }) {
    txTracker = tracker;
    _walletId = walletId;
    _walletName = walletName;
    _coin = coin;
    _electrumXClient = client;
    _cachedElectrumXClient = cachedClient;

    _priceAPI = priceAPI ?? PriceAPI(Client());
    _secureStore =
        secureStore ?? const SecureStorageWrapper(FlutterSecureStorage());

    Logging.instance.log("$walletName isolates length: ${isolates.length}",
        level: LogLevel.Info);
    // investigate possible issues killing shared isolates between multiple firo instances
    for (final isolate in isolates.values) {
      isolate.kill(priority: Isolate.immediate);
    }
    isolates.clear();
  }

  int estimateTxFee({required int vSize, required int feeRatePerKB}) {
    return vSize * (feeRatePerKB / 1000).ceil();
  }

  /// The coinselection algorithm decides whether or not the user is eligible to make the transaction
  /// with [satoshiAmountToSend] and [selectedTxFeeRate]. If so, it will call buildTrasaction() and return
  /// a map containing the tx hex along with other important information. If not, then it will return
  /// an integer (1 or 2)
  dynamic coinSelection(
    int satoshiAmountToSend,
    int selectedTxFeeRate,
    String _recipientAddress,
    bool isSendAll, {
    int additionalOutputs = 0,
    List<UtxoObject>? utxos,
  }) async {
    Logging.instance
        .log("Starting coinSelection ----------", level: LogLevel.Info);
    final List<UtxoObject> availableOutputs = utxos ?? _outputsList;
    final List<UtxoObject> spendableOutputs = [];
    int spendableSatoshiValue = 0;

    // Build list of spendable outputs and totaling their satoshi amount
    for (var i = 0; i < availableOutputs.length; i++) {
      if (availableOutputs[i].blocked == false &&
          availableOutputs[i].status.confirmed == true) {
        spendableOutputs.add(availableOutputs[i]);
        spendableSatoshiValue += availableOutputs[i].value;
      }
    }

    // sort spendable by age (oldest first)
    spendableOutputs.sort(
        (a, b) => b.status.confirmations.compareTo(a.status.confirmations));

    Logging.instance.log("spendableOutputs.length: ${spendableOutputs.length}",
        level: LogLevel.Info);
    Logging.instance
        .log("spendableOutputs: $spendableOutputs", level: LogLevel.Info);
    Logging.instance.log("spendableSatoshiValue: $spendableSatoshiValue",
        level: LogLevel.Info);
    Logging.instance
        .log("satoshiAmountToSend: $satoshiAmountToSend", level: LogLevel.Info);
    // If the amount the user is trying to send is smaller than the amount that they have spendable,
    // then return 1, which indicates that they have an insufficient balance.
    if (spendableSatoshiValue < satoshiAmountToSend) {
      return 1;
      // If the amount the user wants to send is exactly equal to the amount they can spend, then return
      // 2, which indicates that they are not leaving enough over to pay the transaction fee
    } else if (spendableSatoshiValue == satoshiAmountToSend && !isSendAll) {
      return 2;
    }
    // If neither of these statements pass, we assume that the user has a spendable balance greater
    // than the amount they're attempting to send. Note that this value still does not account for
    // the added transaction fee, which may require an extra input and will need to be checked for
    // later on.

    // Possible situation right here
    int satoshisBeingUsed = 0;
    int inputsBeingConsumed = 0;
    List<UtxoObject> utxoObjectsToUse = [];

    for (var i = 0;
        satoshisBeingUsed <= satoshiAmountToSend && i < spendableOutputs.length;
        i++) {
      utxoObjectsToUse.add(spendableOutputs[i]);
      satoshisBeingUsed += spendableOutputs[i].value;
      inputsBeingConsumed += 1;
    }
    for (int i = 0;
        i < additionalOutputs && inputsBeingConsumed < spendableOutputs.length;
        i++) {
      utxoObjectsToUse.add(spendableOutputs[inputsBeingConsumed]);
      satoshisBeingUsed += spendableOutputs[inputsBeingConsumed].value;
      inputsBeingConsumed += 1;
    }

    Logging.instance
        .log("satoshisBeingUsed: $satoshisBeingUsed", level: LogLevel.Info);
    Logging.instance
        .log("inputsBeingConsumed: $inputsBeingConsumed", level: LogLevel.Info);
    Logging.instance
        .log('utxoObjectsToUse: $utxoObjectsToUse', level: LogLevel.Info);

    // numberOfOutputs' length must always be equal to that of recipientsArray and recipientsAmtArray
    List<String> recipientsArray = [_recipientAddress];
    List<int> recipientsAmtArray = [satoshiAmountToSend];

    // gather required signing data
    final utxoSigningData = await fetchBuildTxData(utxoObjectsToUse);

    if (isSendAll) {
      Logging.instance
          .log("Attempting to send all $coin", level: LogLevel.Info);

      final int vSizeForOneOutput = (await buildTransaction(
        utxosToUse: utxoObjectsToUse,
        utxoSigningData: utxoSigningData,
        recipients: [_recipientAddress],
        satoshiAmounts: [satoshisBeingUsed - 1],
      ))["vSize"] as int;
      int feeForOneOutput = estimateTxFee(
        vSize: vSizeForOneOutput,
        feeRatePerKB: selectedTxFeeRate,
      );

      if (feeForOneOutput < vSizeForOneOutput + 1) {
        feeForOneOutput = vSizeForOneOutput + 1;
      }

      final int amount = satoshiAmountToSend - feeForOneOutput;
      dynamic txn = await buildTransaction(
        utxosToUse: utxoObjectsToUse,
        utxoSigningData: utxoSigningData,
        recipients: recipientsArray,
        satoshiAmounts: [amount],
      );
      Map<String, dynamic> transactionObject = {
        "hex": txn["hex"],
        "recipient": recipientsArray[0],
        "recipientAmt": amount,
        "fee": feeForOneOutput,
        "vSize": txn["vSize"],
      };
      return transactionObject;
    }

    final int vSizeForOneOutput = (await buildTransaction(
      utxosToUse: utxoObjectsToUse,
      utxoSigningData: utxoSigningData,
      recipients: [_recipientAddress],
      satoshiAmounts: [satoshisBeingUsed - 1],
    ))["vSize"] as int;
    final int vSizeForTwoOutPuts = (await buildTransaction(
      utxosToUse: utxoObjectsToUse,
      utxoSigningData: utxoSigningData,
      recipients: [
        _recipientAddress,
        await _getCurrentAddressForChain(1),
      ],
      satoshiAmounts: [
        satoshiAmountToSend,
        satoshisBeingUsed - satoshiAmountToSend - 1,
      ], // dust limit is the minimum amount a change output should be
    ))["vSize"] as int;
    debugPrint("vSizeForOneOutput $vSizeForOneOutput");
    debugPrint("vSizeForTwoOutPuts $vSizeForTwoOutPuts");

    // Assume 1 output, only for recipient and no change
    var feeForOneOutput = estimateTxFee(
      vSize: vSizeForOneOutput,
      feeRatePerKB: selectedTxFeeRate,
    );
    // Assume 2 outputs, one for recipient and one for change
    var feeForTwoOutputs = estimateTxFee(
      vSize: vSizeForTwoOutPuts,
      feeRatePerKB: selectedTxFeeRate,
    );

    Logging.instance
        .log("feeForTwoOutputs: $feeForTwoOutputs", level: LogLevel.Info);
    Logging.instance
        .log("feeForOneOutput: $feeForOneOutput", level: LogLevel.Info);
    if (feeForOneOutput < (vSizeForOneOutput + 1)) {
      feeForOneOutput = (vSizeForOneOutput + 1);
    }
    if (feeForTwoOutputs < ((vSizeForTwoOutPuts + 1))) {
      feeForTwoOutputs = ((vSizeForTwoOutPuts + 1));
    }

    Logging.instance
        .log("feeForTwoOutputs: $feeForTwoOutputs", level: LogLevel.Info);
    Logging.instance
        .log("feeForOneOutput: $feeForOneOutput", level: LogLevel.Info);

    if (satoshisBeingUsed - satoshiAmountToSend > feeForOneOutput) {
      if (satoshisBeingUsed - satoshiAmountToSend >
          feeForOneOutput + DUST_LIMIT) {
        // Here, we know that theoretically, we may be able to include another output(change) but we first need to
        // factor in the value of this output in satoshis.
        int changeOutputSize =
            satoshisBeingUsed - satoshiAmountToSend - feeForTwoOutputs;
        // We check to see if the user can pay for the new transaction with 2 outputs instead of one. If they can and
        // the second output's size > DUST_LIMIT satoshis, we perform the mechanics required to properly generate and use a new
        // change address.
        if (changeOutputSize > DUST_LIMIT &&
            satoshisBeingUsed - satoshiAmountToSend - changeOutputSize ==
                feeForTwoOutputs) {
          // generate new change address if current change address has been used
          await checkChangeAddressForTransactions();
          final String newChangeAddress = await _getCurrentAddressForChain(1);

          int feeBeingPaid =
              satoshisBeingUsed - satoshiAmountToSend - changeOutputSize;

          recipientsArray.add(newChangeAddress);
          recipientsAmtArray.add(changeOutputSize);
          // At this point, we have the outputs we're going to use, the amounts to send along with which addresses
          // we intend to send these amounts to. We have enough to send instructions to build the transaction.
          Logging.instance.log('2 outputs in tx', level: LogLevel.Info);
          Logging.instance
              .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
          Logging.instance.log('Recipient output size: $satoshiAmountToSend',
              level: LogLevel.Info);
          Logging.instance.log('Change Output Size: $changeOutputSize',
              level: LogLevel.Info);
          Logging.instance.log(
              'Difference (fee being paid): $feeBeingPaid sats',
              level: LogLevel.Info);
          Logging.instance
              .log('Estimated fee: $feeForTwoOutputs', level: LogLevel.Info);
          dynamic txn = await buildTransaction(
            utxosToUse: utxoObjectsToUse,
            utxoSigningData: utxoSigningData,
            recipients: recipientsArray,
            satoshiAmounts: recipientsAmtArray,
          );

          // make sure minimum fee is accurate if that is being used
          if (txn["vSize"] - feeBeingPaid == 1) {
            int changeOutputSize =
                satoshisBeingUsed - satoshiAmountToSend - (txn["vSize"] as int);
            feeBeingPaid =
                satoshisBeingUsed - satoshiAmountToSend - changeOutputSize;
            recipientsAmtArray.removeLast();
            recipientsAmtArray.add(changeOutputSize);
            Logging.instance.log('Adjusted Input size: $satoshisBeingUsed',
                level: LogLevel.Info);
            Logging.instance.log(
                'Adjusted Recipient output size: $satoshiAmountToSend',
                level: LogLevel.Info);
            Logging.instance.log(
                'Adjusted Change Output Size: $changeOutputSize',
                level: LogLevel.Info);
            Logging.instance.log(
                'Adjusted Difference (fee being paid): $feeBeingPaid sats',
                level: LogLevel.Info);
            Logging.instance.log('Adjusted Estimated fee: $feeForTwoOutputs',
                level: LogLevel.Info);
            txn = await buildTransaction(
              utxosToUse: utxoObjectsToUse,
              utxoSigningData: utxoSigningData,
              recipients: recipientsArray,
              satoshiAmounts: recipientsAmtArray,
            );
          }

          Map<String, dynamic> transactionObject = {
            "hex": txn["hex"],
            "recipient": recipientsArray[0],
            "recipientAmt": recipientsAmtArray[0],
            "fee": feeBeingPaid,
            "vSize": txn["vSize"],
          };
          return transactionObject;
        } else {
          // Something went wrong here. It either overshot or undershot the estimated fee amount or the changeOutputSize
          // is smaller than or equal to [DUST_LIMIT]. Revert to single output transaction.
          Logging.instance.log('1 output in tx', level: LogLevel.Info);
          Logging.instance
              .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
          Logging.instance.log('Recipient output size: $satoshiAmountToSend',
              level: LogLevel.Info);
          Logging.instance.log(
              'Difference (fee being paid): ${satoshisBeingUsed - satoshiAmountToSend} sats',
              level: LogLevel.Info);
          Logging.instance
              .log('Estimated fee: $feeForOneOutput', level: LogLevel.Info);
          dynamic txn = await buildTransaction(
            utxosToUse: utxoObjectsToUse,
            utxoSigningData: utxoSigningData,
            recipients: recipientsArray,
            satoshiAmounts: recipientsAmtArray,
          );
          Map<String, dynamic> transactionObject = {
            "hex": txn["hex"],
            "recipient": recipientsArray[0],
            "recipientAmt": recipientsAmtArray[0],
            "fee": satoshisBeingUsed - satoshiAmountToSend,
            "vSize": txn["vSize"],
          };
          return transactionObject;
        }
      } else {
        // No additional outputs needed since adding one would mean that it'd be smaller than 546 sats
        // which makes it uneconomical to add to the transaction. Here, we pass data directly to instruct
        // the wallet to begin crafting the transaction that the user requested.
        Logging.instance.log('1 output in tx', level: LogLevel.Info);
        Logging.instance
            .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
        Logging.instance.log('Recipient output size: $satoshiAmountToSend',
            level: LogLevel.Info);
        Logging.instance.log(
            'Difference (fee being paid): ${satoshisBeingUsed - satoshiAmountToSend} sats',
            level: LogLevel.Info);
        Logging.instance
            .log('Estimated fee: $feeForOneOutput', level: LogLevel.Info);
        dynamic txn = await buildTransaction(
          utxosToUse: utxoObjectsToUse,
          utxoSigningData: utxoSigningData,
          recipients: recipientsArray,
          satoshiAmounts: recipientsAmtArray,
        );
        Map<String, dynamic> transactionObject = {
          "hex": txn["hex"],
          "recipient": recipientsArray[0],
          "recipientAmt": recipientsAmtArray[0],
          "fee": satoshisBeingUsed - satoshiAmountToSend,
          "vSize": txn["vSize"],
        };
        return transactionObject;
      }
    } else if (satoshisBeingUsed - satoshiAmountToSend == feeForOneOutput) {
      // In this scenario, no additional change output is needed since inputs - outputs equal exactly
      // what we need to pay for fees. Here, we pass data directly to instruct the wallet to begin
      // crafting the transaction that the user requested.
      Logging.instance.log('1 output in tx', level: LogLevel.Info);
      Logging.instance
          .log('Input size: $satoshisBeingUsed', level: LogLevel.Info);
      Logging.instance.log('Recipient output size: $satoshiAmountToSend',
          level: LogLevel.Info);
      Logging.instance.log(
          'Fee being paid: ${satoshisBeingUsed - satoshiAmountToSend} sats',
          level: LogLevel.Info);
      Logging.instance
          .log('Estimated fee: $feeForOneOutput', level: LogLevel.Info);
      dynamic txn = await buildTransaction(
        utxosToUse: utxoObjectsToUse,
        utxoSigningData: utxoSigningData,
        recipients: recipientsArray,
        satoshiAmounts: recipientsAmtArray,
      );
      Map<String, dynamic> transactionObject = {
        "hex": txn["hex"],
        "recipient": recipientsArray[0],
        "recipientAmt": recipientsAmtArray[0],
        "fee": feeForOneOutput,
        "vSize": txn["vSize"],
      };
      return transactionObject;
    } else {
      // Remember that returning 2 indicates that the user does not have a sufficient balance to
      // pay for the transaction fee. Ideally, at this stage, we should check if the user has any
      // additional outputs they're able to spend and then recalculate fees.
      Logging.instance.log(
          'Cannot pay tx fee - checking for more outputs and trying again',
          level: LogLevel.Warning);
      // try adding more outputs
      if (spendableOutputs.length > inputsBeingConsumed) {
        return coinSelection(satoshiAmountToSend, selectedTxFeeRate,
            _recipientAddress, isSendAll,
            additionalOutputs: additionalOutputs + 1, utxos: utxos);
      }
      return 2;
    }
  }

  Future<Map<String, dynamic>> fetchBuildTxData(
    List<UtxoObject> utxosToUse,
  ) async {
    // return data
    Map<String, dynamic> results = {};
    Map<String, List<String>> addressTxid = {};

    // addresses to check
    List<String> addresses = [];

    try {
      // Populating the addresses to check
      for (var i = 0; i < utxosToUse.length; i++) {
        final txid = utxosToUse[i].txid;
        final tx = await _cachedElectrumXClient.getTransaction(
          txHash: txid,
          coin: coin,
        );

        for (final output in tx["vout"] as List) {
          final n = output["n"];
          if (n != null && n == utxosToUse[i].vout) {
            final address = output["scriptPubKey"]["addresses"][0] as String;

            if (!addressTxid.containsKey(address)) {
              addressTxid[address] = <String>[];
            }
            (addressTxid[address] as List).add(txid);

            addresses.add(address);
          }
        }
      }

      // p2pkh / bip44
      final addressesLength = addresses.length;
      if (addressesLength > 0) {
        final receiveDerivationsString =
            await _secureStore.read(key: "${walletId}_receiveDerivations");
        final receiveDerivations = Map<String, dynamic>.from(
            jsonDecode(receiveDerivationsString ?? "{}") as Map);

        final changeDerivationsString =
            await _secureStore.read(key: "${walletId}_changeDerivations");
        final changeDerivations = Map<String, dynamic>.from(
            jsonDecode(changeDerivationsString ?? "{}") as Map);

        for (int i = 0; i < addressesLength; i++) {
          // receives

          dynamic receiveDerivation;

          for (int j = 0; j < receiveDerivations.length; j++) {
            if (receiveDerivations["$j"]["address"] == addresses[i]) {
              receiveDerivation = receiveDerivations["$j"];
            }
          }

          // receiveDerivation = receiveDerivations[addresses[i]];
          // if a match exists it will not be null
          if (receiveDerivation != null) {
            final data = P2PKH(
              data: PaymentData(
                  pubkey: Format.stringToUint8List(
                      receiveDerivation["publicKey"] as String)),
              network: _network,
            ).data;

            for (String tx in addressTxid[addresses[i]]!) {
              results[tx] = {
                "output": data.output,
                "keyPair": ECPair.fromWIF(
                  receiveDerivation["wif"] as String,
                  network: _network,
                ),
              };
            }
          } else {
            // if its not a receive, check change

            dynamic changeDerivation;

            for (int j = 0; j < changeDerivations.length; j++) {
              if (changeDerivations["$j"]["address"] == addresses[i]) {
                changeDerivation = changeDerivations["$j"];
              }
            }

            // final changeDerivation = changeDerivations[addresses[i]];
            // if a match exists it will not be null
            if (changeDerivation != null) {
              final data = P2PKH(
                data: PaymentData(
                    pubkey: Format.stringToUint8List(
                        changeDerivation["publicKey"] as String)),
                network: _network,
              ).data;

              for (String tx in addressTxid[addresses[i]]!) {
                results[tx] = {
                  "output": data.output,
                  "keyPair": ECPair.fromWIF(
                    changeDerivation["wif"] as String,
                    network: _network,
                  ),
                };
              }
            }
          }
        }
      }

      return results;
    } catch (e, s) {
      Logging.instance
          .log("fetchBuildTxData() threw: $e,\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  /// Builds and signs a transaction
  Future<Map<String, dynamic>> buildTransaction({
    required List<UtxoObject> utxosToUse,
    required Map<String, dynamic> utxoSigningData,
    required List<String> recipients,
    required List<int> satoshiAmounts,
  }) async {
    Logging.instance
        .log("Starting buildTransaction ----------", level: LogLevel.Info);

    final txb = TransactionBuilder(network: _network);
    txb.setVersion(1);

    // Add transaction inputs
    for (var i = 0; i < utxosToUse.length; i++) {
      final txid = utxosToUse[i].txid;
      txb.addInput(txid, utxosToUse[i].vout, null,
          utxoSigningData[txid]["output"] as Uint8List);
    }

    // Add transaction output
    for (var i = 0; i < recipients.length; i++) {
      txb.addOutput(recipients[i], satoshiAmounts[i]);
    }

    try {
      // Sign the transaction accordingly
      for (var i = 0; i < utxosToUse.length; i++) {
        final txid = utxosToUse[i].txid;
        txb.sign(
          vin: i,
          keyPair: utxoSigningData[txid]["keyPair"] as ECPair,
          witnessValue: utxosToUse[i].value,
          redeemScript: utxoSigningData[txid]["redeemScript"] as Uint8List?,
        );
      }
    } catch (e, s) {
      Logging.instance.log("Caught exception while signing transaction: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }

    final builtTx = txb.build();
    final vSize = builtTx.virtualSize();

    return {"hex": builtTx.toHex(), "vSize": vSize};
  }

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    final failovers = NodeService()
        .failoverNodesFor(coin: coin)
        .map(
          (e) => ElectrumXNode(
            address: e.host,
            port: e.port,
            name: e.name,
            id: e.id,
            useSSL: e.useSSL,
          ),
        )
        .toList();
    final newNode = await _getCurrentNode();
    _cachedElectrumXClient = CachedElectrumX.from(
      node: newNode,
      prefs: _prefs,
      failovers: failovers,
    );
    _electrumXClient = ElectrumX.from(
      node: newNode,
      prefs: _prefs,
      failovers: failovers,
    );

    if (shouldRefresh) {
      unawaited(refresh());
    }
  }

  @override
  Future<void> initializeNew() async {
    Logging.instance
        .log("Generating new ${coin.prettyName} wallet.", level: LogLevel.Info);

    if (DB.instance.get<dynamic>(boxName: walletId, key: "id") != null) {
      throw Exception(
          "Attempted to initialize a new wallet using an existing wallet ID!");
    }

    await _prefs.init();
    try {
      await _generateNewWallet();
    } catch (e, s) {
      Logging.instance.log("Exception rethrown from initializeNew(): $e\n$s",
          level: LogLevel.Fatal);
      rethrow;
    }

    await Future.wait([
      DB.instance.put<dynamic>(boxName: walletId, key: "id", value: _walletId),
      _getLelantusTransactionData().then((lelantusTxData) =>
          _lelantusTransactionData = Future(() => lelantusTxData)),
      DB.instance
          .put<dynamic>(boxName: walletId, key: "isFavorite", value: false),
    ]);
  }

  @override
  Future<void> initializeExisting() async {
    Logging.instance.log(
        "Opening existing $_walletId ${coin.prettyName} wallet.",
        level: LogLevel.Info);

    if ((DB.instance.get<dynamic>(boxName: walletId, key: "id") as String?) ==
        null) {
      throw Exception(
          "Attempted to initialize an existing wallet using an unknown wallet ID!");
    }
    await _prefs.init();
    final data =
        DB.instance.get<dynamic>(boxName: walletId, key: "latest_tx_model")
            as models.TransactionData?;
    if (data != null) {
      _transactionData = Future(() => data);
    }
  }

  Future<bool> refreshIfThereIsNewData() async {
    if (longMutex) return false;
    if (_hasCalledExit) return false;
    Logging.instance
        .log("$walletName refreshIfThereIsNewData", level: LogLevel.Info);

    try {
      bool needsRefresh = false;
      Set<String> txnsToCheck = {};

      for (final String txid in txTracker.pendings) {
        if (!txTracker.wasNotifiedConfirmed(txid)) {
          txnsToCheck.add(txid);
        }
      }

      for (String txid in txnsToCheck) {
        final txn = await electrumXClient.getTransaction(txHash: txid);
        int confirmations = txn["confirmations"] as int? ?? 0;
        bool isUnconfirmed = confirmations < MINIMUM_CONFIRMATIONS;
        if (!isUnconfirmed) {
          needsRefresh = true;
          break;
        }
      }
      if (!needsRefresh) {
        var allOwnAddresses = await this.allOwnAddresses;
        List<Map<String, dynamic>> allTxs =
            await _fetchHistory(allOwnAddresses);
        models.TransactionData txData = await _txnData;
        for (Map<String, dynamic> transaction in allTxs) {
          if (txData.findTransaction(transaction['tx_hash'] as String) ==
              null) {
            Logging.instance.log(
                " txid not found in address history already ${transaction['tx_hash']}",
                level: LogLevel.Info);
            needsRefresh = true;
            break;
          }
        }
      }
      return needsRefresh;
    } catch (e, s) {
      Logging.instance.log(
          "Exception caught in refreshIfThereIsNewData: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> getAllTxsToWatch(
    models.TransactionData txData,
    models.TransactionData lTxData,
  ) async {
    if (_hasCalledExit) return;
    Logging.instance.log("$walletName periodic", level: LogLevel.Info);
    List<models.Transaction> unconfirmedTxnsToNotifyPending = [];
    List<models.Transaction> unconfirmedTxnsToNotifyConfirmed = [];

    for (models.TransactionChunk chunk in txData.txChunks) {
      for (models.Transaction tx in chunk.transactions) {
        models.Transaction? lTx = lTxData.findTransaction(tx.txid);

        if (tx.confirmedStatus) {
          if (txTracker.wasNotifiedPending(tx.txid) &&
              !txTracker.wasNotifiedConfirmed(tx.txid)) {
            // get all transactions that were notified as pending but not as confirmed
            unconfirmedTxnsToNotifyConfirmed.add(tx);
          }
          if (lTx != null &&
              (lTx.inputs.isEmpty || lTx.inputs[0].txid.isEmpty) &&
              lTx.confirmedStatus == false &&
              tx.txType == "Received") {
            // If this is a received that is past 1 or more confirmations and has not been minted,
            if (!txTracker.wasNotifiedPending(tx.txid)) {
              unconfirmedTxnsToNotifyPending.add(tx);
            }
          }
        } else {
          if (!txTracker.wasNotifiedPending(tx.txid)) {
            // get all transactions that were not notified as pending yet
            unconfirmedTxnsToNotifyPending.add(tx);
          }
        }
      }
    }

    for (models.TransactionChunk chunk in txData.txChunks) {
      for (models.Transaction tx in chunk.transactions) {
        if (!tx.confirmedStatus && tx.inputs[0].txid.isNotEmpty) {
          // Get all normal txs that are at 0 confirmations
          unconfirmedTxnsToNotifyPending
              .removeWhere((e) => e.txid == tx.inputs[0].txid);
          Logging.instance.log("removed tx: ${tx.txid}", level: LogLevel.Info);
        }
      }
    }
    for (models.TransactionChunk chunk in lTxData.txChunks) {
      for (models.Transaction lTX in chunk.transactions) {
        models.Transaction? tx = txData.findTransaction(lTX.txid);
        if (tx == null) {
          // if this is a ltx transaction that is unconfirmed and not represented in the normal transaction set.
          if (!lTX.confirmedStatus) {
            if (!txTracker.wasNotifiedPending(lTX.txid)) {
              unconfirmedTxnsToNotifyPending.add(lTX);
            }
          } else {
            if (txTracker.wasNotifiedPending(lTX.txid) &&
                !txTracker.wasNotifiedConfirmed(lTX.txid)) {
              unconfirmedTxnsToNotifyConfirmed.add(lTX);
            }
          }
        }
      }
    }
    Logging.instance.log(
        "unconfirmedTxnsToNotifyPending $unconfirmedTxnsToNotifyPending",
        level: LogLevel.Info);
    Logging.instance.log(
        "unconfirmedTxnsToNotifyConfirmed $unconfirmedTxnsToNotifyConfirmed",
        level: LogLevel.Info);

    for (final tx in unconfirmedTxnsToNotifyPending) {
      switch (tx.txType) {
        case "Received":
          unawaited(
            NotificationApi.showNotification(
              title: "Incoming transaction",
              body: walletName,
              walletId: walletId,
              iconAssetName: Assets.svg.iconFor(coin: coin),
              date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
              shouldWatchForUpdates: tx.confirmations < MINIMUM_CONFIRMATIONS,
              coinName: coin.name,
              txid: tx.txid,
              confirmations: tx.confirmations,
              requiredConfirmations: MINIMUM_CONFIRMATIONS,
            ),
          );
          await txTracker.addNotifiedPending(tx.txid);
          break;
        case "Sent":
          unawaited(
            NotificationApi.showNotification(
              title:
                  tx.subType == "mint" ? "Anonymizing" : "Outgoing transaction",
              body: walletName,
              walletId: walletId,
              iconAssetName: Assets.svg.iconFor(coin: coin),
              date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
              shouldWatchForUpdates: tx.confirmations < MINIMUM_CONFIRMATIONS,
              coinName: coin.name,
              txid: tx.txid,
              confirmations: tx.confirmations,
              requiredConfirmations: MINIMUM_CONFIRMATIONS,
            ),
          );
          await txTracker.addNotifiedPending(tx.txid);
          break;
        default:
          break;
      }
    }

    for (final tx in unconfirmedTxnsToNotifyConfirmed) {
      if (tx.txType == "Received") {
        unawaited(
          NotificationApi.showNotification(
            title: "Incoming transaction confirmed",
            body: walletName,
            walletId: walletId,
            iconAssetName: Assets.svg.iconFor(coin: coin),
            date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
            shouldWatchForUpdates: false,
            coinName: coin.name,
          ),
        );
        await txTracker.addNotifiedConfirmed(tx.txid);
      } else if (tx.txType == "Sent" && tx.subType == "join") {
        unawaited(
          NotificationApi.showNotification(
            title: tx.subType == "mint"
                ? "Anonymized"
                : "Outgoing transaction confirmed",
            body: walletName,
            walletId: walletId,
            iconAssetName: Assets.svg.iconFor(coin: coin),
            date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
            shouldWatchForUpdates: false,
            coinName: coin.name,
          ),
        );
        await txTracker.addNotifiedConfirmed(tx.txid);
      }
    }
  }

  /// Generates initial wallet values such as mnemonic, chain (receive/change) arrays and indexes.
  Future<void> _generateNewWallet() async {
    Logging.instance
        .log("IS_INTEGRATION_TEST: $integrationTestFlag", level: LogLevel.Info);
    if (!integrationTestFlag) {
      final features = await electrumXClient.getServerFeatures();
      Logging.instance.log("features: $features", level: LogLevel.Info);
      switch (coin) {
        case Coin.firo:
          if (features['genesis_hash'] != GENESIS_HASH_MAINNET) {
            throw Exception("genesis hash does not match main net!");
          }
          break;
        case Coin.firoTestNet:
          if (features['genesis_hash'] != GENESIS_HASH_TESTNET) {
            throw Exception("genesis hash does not match test net!");
          }
          break;
        default:
          throw Exception(
              "Attempted to generate a FiroWallet using a non firo coin type: ${coin.name}");
      }
      // if (_networkType == BasicNetworkType.main) {
      //   if (features['genesis_hash'] != GENESIS_HASH_MAINNET) {
      //     throw Exception("genesis hash does not match!");
      //   }
      // } else if (_networkType == BasicNetworkType.test) {
      //   if (features['genesis_hash'] != GENESIS_HASH_TESTNET) {
      //     throw Exception("genesis hash does not match!");
      //   }
      // }
    }

    // this should never fail as overwriting a mnemonic is big bad
    assert((await _secureStore.read(key: '${_walletId}_mnemonic')) == null);
    await _secureStore.write(
        key: '${_walletId}_mnemonic',
        value: bip39.generateMnemonic(strength: 256));

    // Set relevant indexes
    await DB.instance
        .put<dynamic>(boxName: walletId, key: 'receivingIndex', value: 0);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: 'changeIndex', value: 0);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: 'mintIndex', value: 0);
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'blocked_tx_hashes',
        value: [
          "0xdefault"
        ]); // A list of transaction hashes to represent frozen utxos in wallet
    // initialize address book entries
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'addressBookEntries',
        value: <String, String>{});

    await DB.instance
        .put<dynamic>(boxName: walletId, key: 'jindex', value: <dynamic>[]);
    // Generate and add addresses to relevant arrays
    final initialReceivingAddress = await _generateAddressForChain(0, 0);
    final initialChangeAddress = await _generateAddressForChain(1, 0);
    await addToAddressesArrayForChain(initialReceivingAddress, 0);
    await addToAddressesArrayForChain(initialChangeAddress, 1);
    _currentReceivingAddress = Future(() => initialReceivingAddress);
  }

  bool refreshMutex = false;
  @override
  bool get isRefreshing => refreshMutex;

  /// Refreshes display data for the wallet
  @override
  Future<void> refresh() async {
    if (refreshMutex) {
      Logging.instance.log("$walletId $walletName refreshMutex denied",
          level: LogLevel.Info);
      return;
    } else {
      refreshMutex = true;
    }
    Logging.instance
        .log("PROCESSORS ${Platform.numberOfProcessors}", level: LogLevel.Info);
    try {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          coin,
        ),
      );

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.0, walletId));

      final receiveDerivationsString =
          await _secureStore.read(key: "${walletId}_receiveDerivations");
      if (receiveDerivationsString == null ||
          receiveDerivationsString == "{}") {
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.05, walletId));
        final mnemonic = await _secureStore.read(key: '${_walletId}_mnemonic');
        await fillAddresses(mnemonic!,
            numberOfThreads: Platform.numberOfProcessors - isolates.length - 1);
      }

      await checkReceivingAddressForTransactions();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.1, walletId));

      final newUtxoData = _fetchUtxoData();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.2, walletId));

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.25, walletId));

      final newTxData = _fetchTransactionData();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.35, walletId));

      final feeObj = _getFees();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.50, walletId));

      _utxoData = Future(() => newUtxoData);
      _transactionData = Future(() => newTxData);
      _feeObject = Future(() => feeObj);
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.60, walletId));

      final lelantusCoins = getLelantusCoinMap();
      Logging.instance.log("_lelantus_coins at refresh: $lelantusCoins",
          level: LogLevel.Warning, printFullLength: true);
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.70, walletId));

      await _refreshLelantusData();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.80, walletId));

      // await autoMint();
      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.90, walletId));

      var balance = await _getFullBalance();
      _balances = Future(() => balance);

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.95, walletId));

      var txData = (await _txnData);
      var lTxData = (await lelantusTransactionData);
      await getAllTxsToWatch(txData, lTxData);

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(1.0, walletId));

      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );
      refreshMutex = false;

      if (isActive || shouldAutoSync) {
        timer ??= Timer.periodic(const Duration(seconds: 30), (timer) async {
          bool shouldNotify = await refreshIfThereIsNewData();
          if (shouldNotify) {
            await refresh();
            GlobalEventBus.instance.fire(UpdatedInBackgroundEvent(
                "New data found in $walletId $walletName in background!",
                walletId));
          }
        });
      }
    } catch (error, strace) {
      refreshMutex = false;
      GlobalEventBus.instance.fire(
        NodeConnectionStatusChangedEvent(
          NodeConnectionStatus.disconnected,
          walletId,
          coin,
        ),
      );
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.unableToSync,
          walletId,
          coin,
        ),
      );
      Logging.instance.log(
          "Caught exception in refreshWalletData(): $error\n$strace",
          level: LogLevel.Warning);
    }
  }

  Future<int> _fetchMaxFee() async {
    final balance = await availableBalance;
    int spendAmount =
        (balance * Decimal.fromInt(Constants.satsPerCoin)).toBigInt().toInt();
    int fee = await estimateJoinSplitFee(spendAmount);
    return fee;
  }

  Future<List<DartLelantusEntry>> _getLelantusEntry() async {
    final mnemonic = await _secureStore.read(key: '${_walletId}_mnemonic');
    final List<LelantusCoin> lelantusCoins = await _getUnspentCoins();
    final root = await compute(
      getBip32RootWrapper,
      Tuple2(
        mnemonic!,
        _network,
      ),
    );
    final waitLelantusEntries = lelantusCoins.map((coin) async {
      final keyPair = await compute(
        getBip32NodeFromRootWrapper,
        Tuple3(
          MINT_INDEX,
          coin.index,
          root,
        ),
      );
      if (keyPair.privateKey == null) {
        Logging.instance.log("error bad key", level: LogLevel.Error);
        return DartLelantusEntry(1, 0, 0, 0, 0, '');
      }
      final String privateKey = Format.uint8listToString(keyPair.privateKey!);
      return DartLelantusEntry(coin.isUsed ? 1 : 0, 0, coin.anonymitySetId,
          coin.value, coin.index, privateKey);
    }).toList();

    final lelantusEntries = await Future.wait(waitLelantusEntries);

    if (lelantusEntries.isNotEmpty) {
      lelantusEntries.removeWhere((element) => element.amount == 0);
    }

    return lelantusEntries;
  }

  List<Map<dynamic, LelantusCoin>> getLelantusCoinMap() {
    final _l = DB.instance
        .get<dynamic>(boxName: walletId, key: '_lelantus_coins') as List?;
    final List<Map<dynamic, LelantusCoin>> lelantusCoins = [];
    for (var el in _l ?? []) {
      lelantusCoins.add({el.keys.first: el.values.first as LelantusCoin});
    }
    return lelantusCoins;
  }

  Future<List<LelantusCoin>> _getUnspentCoins() async {
    final List<Map<dynamic, LelantusCoin>> lelantusCoins = getLelantusCoinMap();
    if (lelantusCoins.isNotEmpty) {
      lelantusCoins.removeWhere((element) =>
          element.values.any((elementCoin) => elementCoin.value == 0));
    }
    final jindexes =
        DB.instance.get<dynamic>(boxName: walletId, key: 'jindex') as List?;
    final data = await _txnData;
    final lelantusData = await lelantusTransactionData;
    List<LelantusCoin> coins = [];

    List<LelantusCoin> lelantusCoinsList =
        lelantusCoins.fold(<LelantusCoin>[], (previousValue, element) {
      previousValue.add(element.values.first);
      return previousValue;
    });
    for (int i = 0; i < lelantusCoinsList.length; i++) {
      // Logging.instance.log("lelantusCoinsList[$i]: ${lelantusCoinsList[i]}");
      final txn = await cachedElectrumXClient.getTransaction(
        txHash: lelantusCoinsList[i].txId,
        verbose: true,
        coin: coin,
      );
      final confirmations = txn["confirmations"];
      bool isUnconfirmed = confirmations is int && confirmations < 1;
      if (!jindexes!.contains(lelantusCoinsList[i].index) &&
          data.findTransaction(lelantusCoinsList[i].txId) == null) {
        isUnconfirmed = true;
      }
      if ((data.findTransaction(lelantusCoinsList[i].txId) != null &&
              !data
                  .findTransaction(lelantusCoinsList[i].txId)!
                  .confirmedStatus) ||
          (lelantusData.findTransaction(lelantusCoinsList[i].txId) != null &&
              !lelantusData
                  .findTransaction(lelantusCoinsList[i].txId)!
                  .confirmedStatus)) {
        continue;
      }
      if (!lelantusCoinsList[i].isUsed &&
          lelantusCoinsList[i].anonymitySetId != ANONYMITY_SET_EMPTY_ID &&
          !isUnconfirmed) {
        coins.add(lelantusCoinsList[i]);
      }
    }
    return coins;
  }

  // index 0 and 1 for the funds available to spend.
  // index 2 and 3 for all the funds in the wallet (including the undependable ones)
  Future<List<Decimal>> _getFullBalance() async {
    try {
      final List<Map<dynamic, LelantusCoin>> lelantusCoins =
          getLelantusCoinMap();
      if (lelantusCoins.isNotEmpty) {
        lelantusCoins.removeWhere((element) =>
            element.values.any((elementCoin) => elementCoin.value == 0));
      }
      final utxos = await utxoData;
      final Decimal price = await firoPrice;
      final data = await _txnData;
      final lData = await lelantusTransactionData;
      final jindexes =
          DB.instance.get<dynamic>(boxName: walletId, key: 'jindex') as List?;
      int intLelantusBalance = 0;
      int unconfirmedLelantusBalance = 0;

      for (var element in lelantusCoins) {
        element.forEach((key, value) {
          final tx = data.findTransaction(value.txId);
          models.Transaction? ltx;
          ltx = lData.findTransaction(value.txId);
          // Logging.instance.log("$value $tx $ltx");
          if (!jindexes!.contains(value.index) && tx == null) {
            // This coin is not confirmed and may be replaced
          } else if (jindexes.contains(value.index) &&
              tx == null &&
              !value.isUsed &&
              ltx != null &&
              !ltx.confirmedStatus) {
            unconfirmedLelantusBalance += value.value;
          } else if (jindexes.contains(value.index) && !value.isUsed) {
            intLelantusBalance += value.value;
          } else if (!value.isUsed &&
              (tx == null ? true : tx.confirmedStatus != false)) {
            intLelantusBalance += value.value;
          } else if (tx != null && tx.confirmedStatus == false) {
            unconfirmedLelantusBalance += value.value;
          }
        });
      }

      final int utxosIntValue = utxos.satoshiBalance;
      final Decimal utxosValue = Format.satoshisToAmount(utxosIntValue);

      List<Decimal> balances = List.empty(growable: true);

      Decimal lelantusBalance = Format.satoshisToAmount(intLelantusBalance);

      balances.add(lelantusBalance);

      balances.add(lelantusBalance * price);

      Decimal _unconfirmedLelantusBalance =
          Format.satoshisToAmount(unconfirmedLelantusBalance);

      balances.add(lelantusBalance + utxosValue + _unconfirmedLelantusBalance);

      balances.add(
          (lelantusBalance + utxosValue + _unconfirmedLelantusBalance) * price);

      int availableSats =
          utxos.satoshiBalance - utxos.satoshiBalanceUnconfirmed;
      if (availableSats < 0) {
        availableSats = 0;
      }
      balances.add(Format.satoshisToAmount(availableSats));

      Logging.instance.log("balances $balances", level: LogLevel.Info);
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: 'totalBalance',
          value: balances[2].toString());
      return balances;
    } catch (e, s) {
      Logging.instance.log("Exception rethrown in getFullBalance(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> anonymizeAllPublicFunds() async {
    try {
      var mintResult = await _mintSelection();
      if (mintResult.isEmpty) {
        Logging.instance.log("nothing to mint", level: LogLevel.Info);
        return;
      }
      await _submitLelantusToNetwork(mintResult);
      unawaited(refresh());
    } catch (e, s) {
      Logging.instance.log(
          "Exception caught in anonymizeAllPublicFunds(): $e\n$s",
          level: LogLevel.Warning);
      rethrow;
    }
  }

  /// Returns the mint transaction hex to mint all of the available funds.
  Future<Map<String, dynamic>> _mintSelection() async {
    final List<UtxoObject> availableOutputs = _outputsList;
    final List<UtxoObject?> spendableOutputs = [];

    // Build list of spendable outputs and totaling their satoshi amount
    for (var i = 0; i < availableOutputs.length; i++) {
      if (availableOutputs[i].blocked == false &&
          availableOutputs[i].status.confirmed == true &&
          !(availableOutputs[i].isCoinbase &&
              availableOutputs[i].status.confirmations <= 101)) {
        spendableOutputs.add(availableOutputs[i]);
      }
    }

    final List<Map<dynamic, LelantusCoin>> lelantusCoins = getLelantusCoinMap();
    if (lelantusCoins.isNotEmpty) {
      lelantusCoins.removeWhere((element) =>
          element.values.any((elementCoin) => elementCoin.value == 0));
    }
    final data = await _txnData;
    final dataMap = data.getAllTransactions();
    dataMap.forEach((key, value) {
      if (value.inputs.isNotEmpty) {
        for (var element in value.inputs) {
          if (lelantusCoins
                  .any((element) => element.keys.contains(value.txid)) &&
              spendableOutputs.firstWhere(
                      (output) => output?.txid == element.txid,
                      orElse: () => null) !=
                  null) {
            spendableOutputs
                .removeWhere((output) => output!.txid == element.txid);
          }
        }
      }
    });

    // If there is no Utxos to mint then stop the function.
    if (spendableOutputs.isEmpty) {
      Logging.instance.log("_mintSelection(): No spendable outputs found",
          level: LogLevel.Info);
      return {};
    }

    int satoshisBeingUsed = 0;
    List<UtxoObject> utxoObjectsToUse = [];

    for (var i = 0; i < spendableOutputs.length; i++) {
      final spendable = spendableOutputs[i];
      if (spendable != null) {
        utxoObjectsToUse.add(spendable);
        satoshisBeingUsed += spendable.value;
      }
    }

    var mintsWithoutFee = await createMintsFromAmount(satoshisBeingUsed);

    var tmpTx = await buildMintTransaction(
        utxoObjectsToUse, satoshisBeingUsed, mintsWithoutFee);

    int vsize = (tmpTx['transaction'] as Transaction).virtualSize();
    final Decimal dvsize = Decimal.fromInt(vsize);

    final feesObject = await fees;

    final Decimal fastFee = Format.satoshisToAmount(feesObject.fast);
    int firoFee =
        (dvsize * fastFee * Decimal.fromInt(100000)).toDouble().ceil();
    // int firoFee = (vsize * feesObject.fast * (1 / 1000.0) * 100000000).ceil();

    if (firoFee < vsize) {
      firoFee = vsize + 1;
    }
    firoFee = firoFee + 10;
    int satoshiAmountToSend = satoshisBeingUsed - firoFee;

    var mintsWithFee = await createMintsFromAmount(satoshiAmountToSend);

    Map<String, dynamic> transaction = await buildMintTransaction(
        utxoObjectsToUse, satoshiAmountToSend, mintsWithFee);
    transaction['transaction'] = "";
    Logging.instance.log(transaction.toString(), level: LogLevel.Info);
    Logging.instance.log(transaction['txHex'], level: LogLevel.Info);
    return transaction;
  }

  Future<List<Map<String, dynamic>>> createMintsFromAmount(int total) async {
    var tmpTotal = total;
    var index = 0;
    var mints = <Map<String, dynamic>>[];
    final nextFreeMintIndex =
        DB.instance.get<dynamic>(boxName: walletId, key: 'mintIndex') as int;
    while (tmpTotal > 0) {
      final mintValue = min(tmpTotal, MINT_LIMIT);
      final mint = await _getMintHex(
        mintValue,
        nextFreeMintIndex + index,
      );
      mints.add({
        "value": mintValue,
        "script": mint,
        "index": nextFreeMintIndex + index,
        "publicCoin": "",
      });
      tmpTotal = tmpTotal - MINT_LIMIT;
      index++;
    }
    return mints;
  }

  /// returns a valid txid if successful
  Future<String> submitHexToNetwork(String hex) async {
    try {
      final txid = await electrumXClient.broadcastTransaction(rawTx: hex);
      return txid;
    } catch (e, s) {
      Logging.instance.log(
          "Caught exception in submitHexToNetwork(\"$hex\"): $e $s",
          printFullLength: true,
          level: LogLevel.Info);
      // return an invalid tx
      return "transaction submission failed";
    }
  }

  /// Builds and signs a transaction
  Future<Map<String, dynamic>> buildMintTransaction(List<UtxoObject> utxosToUse,
      int satoshisPerRecipient, List<Map<String, dynamic>> mintsMap) async {
    debugPrint(utxosToUse.toString());
    List<String> addressesToDerive = [];

    // Populating the addresses to derive
    for (var i = 0; i < utxosToUse.length; i++) {
      final txid = utxosToUse[i].txid;
      final outputIndex = utxosToUse[i].vout;

      // txid may not work for this as txid may not always be the same as tx_hash?
      final tx = await cachedElectrumXClient.getTransaction(
        txHash: txid,
        verbose: true,
        coin: coin,
      );

      final vouts = tx["vout"] as List?;
      if (vouts != null && outputIndex < vouts.length) {
        final address =
            vouts[outputIndex]["scriptPubKey"]["addresses"][0] as String?;
        if (address != null) {
          addressesToDerive.add(address);
        }
      }
    }

    List<ECPair> elipticCurvePairArray = [];
    List<Uint8List> outputDataArray = [];

    final receiveDerivationsString =
        await _secureStore.read(key: "${walletId}_receiveDerivations");
    final changeDerivationsString =
        await _secureStore.read(key: "${walletId}_changeDerivations");

    final receiveDerivations = Map<String, dynamic>.from(
        jsonDecode(receiveDerivationsString ?? "{}") as Map);
    final changeDerivations = Map<String, dynamic>.from(
        jsonDecode(changeDerivationsString ?? "{}") as Map);

    for (var i = 0; i < addressesToDerive.length; i++) {
      final addressToCheckFor = addressesToDerive[i];

      for (var i = 0; i < receiveDerivations.length; i++) {
        final receive = receiveDerivations["$i"];
        final change = changeDerivations["$i"];

        if (receive['address'] == addressToCheckFor) {
          Logging.instance
              .log('Receiving found on loop $i', level: LogLevel.Info);
          // Logging.instance.log(
          //     'decoded receive[\'wif\'] version: ${wif.decode(receive['wif'] as String)}, _network: $_network');
          elipticCurvePairArray
              .add(ECPair.fromWIF(receive['wif'] as String, network: _network));
          outputDataArray.add(P2PKH(
                  network: _network,
                  data: PaymentData(
                      pubkey: Format.stringToUint8List(
                          receive['publicKey'] as String)))
              .data
              .output!);
          break;
        }
        if (change['address'] == addressToCheckFor) {
          Logging.instance.log('Change found on loop $i', level: LogLevel.Info);
          // Logging.instance.log(
          //     'decoded change[\'wif\'] version: ${wif.decode(change['wif'] as String)}, _network: $_network');
          elipticCurvePairArray
              .add(ECPair.fromWIF(change['wif'] as String, network: _network));

          outputDataArray.add(P2PKH(
                  network: _network,
                  data: PaymentData(
                      pubkey: Format.stringToUint8List(
                          change['publicKey'] as String)))
              .data
              .output!);
          break;
        }
      }
    }

    final txb = TransactionBuilder(network: _network);
    txb.setVersion(2);

    int height = await getBlockHead(electrumXClient);
    txb.setLockTime(height);
    int amount = 0;
    // Add transaction inputs
    for (var i = 0; i < utxosToUse.length; i++) {
      txb.addInput(
          utxosToUse[i].txid, utxosToUse[i].vout, null, outputDataArray[i]);
      amount += utxosToUse[i].value;
    }

    final index =
        DB.instance.get<dynamic>(boxName: walletId, key: 'mintIndex') as int;
    Logging.instance.log("index of mint $index", level: LogLevel.Info);

    for (var mintsElement in mintsMap) {
      Logging.instance.log("using $mintsElement", level: LogLevel.Info);
      Uint8List mintu8 =
          Format.stringToUint8List(mintsElement['script'] as String);
      txb.addOutput(mintu8, mintsElement['value'] as int);
    }

    for (var i = 0; i < utxosToUse.length; i++) {
      txb.sign(
        vin: i,
        keyPair: elipticCurvePairArray[i],
        witnessValue: utxosToUse[i].value,
      );
    }
    var incomplete = txb.buildIncomplete();
    var txId = incomplete.getId();
    var txHex = incomplete.toHex();
    int fee = amount - incomplete.outs[0].value!;

    var price = await firoPrice;
    var builtHex = txb.build();
    // return builtHex;
    final locale = await Devicelocale.currentLocale;
    return {
      "transaction": builtHex,
      "txid": txId,
      "txHex": txHex,
      "value": amount - fee,
      "fees": Format.satoshisToAmount(fee).toDouble(),
      "publicCoin": "",
      "height": height,
      "txType": "Sent",
      "confirmed_status": false,
      "amount": Format.satoshisToAmount(amount).toDouble(),
      "worthNow": Format.localizedStringAsFixed(
          value: ((Decimal.fromInt(amount) * price) /
                  Decimal.fromInt(Constants.satsPerCoin))
              .toDecimal(scaleOnInfinitePrecision: 2),
          decimalPlaces: 2,
          locale: locale!),
      "timestamp": DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "subType": "mint",
      "mintsMap": mintsMap,
    };
  }

  Future<models.TransactionData> _refreshLelantusData() async {
    final List<Map<dynamic, LelantusCoin>> lelantusCoins = getLelantusCoinMap();
    final jindexes =
        DB.instance.get<dynamic>(boxName: walletId, key: 'jindex') as List?;

    // Get all joinsplit transaction ids
    final lelantusTxData = await lelantusTransactionData;

    final listLelantusTxData = lelantusTxData.getAllTransactions();
    List<String> joinsplits = [];
    for (final tx in listLelantusTxData.values) {
      if (tx.subType == "join") {
        joinsplits.add(tx.txid);
      }
    }
    for (final coin
        in lelantusCoins.fold(<LelantusCoin>[], (previousValue, element) {
      (previousValue as List<LelantusCoin>).add(element.values.first);
      return previousValue;
    })) {
      if (jindexes != null) {
        if (jindexes.contains(coin.index) && !joinsplits.contains(coin.txId)) {
          joinsplits.add(coin.txId);
        }
      }
    }

    final currentPrice = await firoPrice;
    // Grab the most recent information on all the joinsplits

    final locale = await Devicelocale.currentLocale;
    final updatedJSplit = await getJMintTransactions(cachedElectrumXClient,
        joinsplits, _prefs.currency, coin, currentPrice, locale!);

    // update all of joinsplits that are now confirmed.
    for (final tx in updatedJSplit) {
      final currentTx = listLelantusTxData[tx.txid];
      if (currentTx == null) {
        // this send was accidentally not included in the list
        listLelantusTxData[tx.txid] = tx;
        continue;
      }
      if (currentTx.confirmedStatus != tx.confirmedStatus) {
        listLelantusTxData[tx.txid] = tx;
      }
    }

    final txData = await _txnData;

    // Logging.instance.log(txData.txChunks);
    final listTxData = txData.getAllTransactions();
    listTxData.forEach((key, value) {
      // ignore change addresses
      // bool hasAtLeastOneReceive = false;
      // int howManyReceiveInputs = 0;
      // for (var element in value.inputs) {
      //   if (listLelantusTxData.containsKey(element.txid) &&
      //           listLelantusTxData[element.txid]!.txType == "Received"
      //       // &&
      //       // listLelantusTxData[element.txid].subType != "mint"
      //       ) {
      //     // hasAtLeastOneReceive = true;
      //     // howManyReceiveInputs++;
      //   }
      // }

      if (value.txType == "Received" && value.subType != "mint") {
        // Every receive other than a mint should be shown. Mints will be collected and shown from the send side
        listLelantusTxData[value.txid] = value;
      } else if (value.txType == "Sent") {
        // all sends should be shown, mints will be displayed correctly in the ui
        listLelantusTxData[value.txid] = value;
      }
    });

    // update the _lelantusTransactionData
    final models.TransactionData newTxData =
        models.TransactionData.fromMap(listLelantusTxData);
    // Logging.instance.log(newTxData.txChunks);
    _lelantusTransactionData = Future(() => newTxData);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'latest_lelantus_tx_model', value: newTxData);
    return newTxData;
  }

  Future<String> _getMintHex(int amount, int index) async {
    final mnemonic = await _secureStore.read(key: '${_walletId}_mnemonic');
    final mintKeyPair = await compute(
      getBip32NodeWrapper,
      Tuple4(
        MINT_INDEX,
        index,
        mnemonic!,
        _network,
      ),
    );
    String keydata = Format.uint8listToString(mintKeyPair.privateKey!);
    String seedID = Format.uint8listToString(mintKeyPair.identifier);

    String mintHex = await compute(
      _getMintScriptWrapper,
      Tuple5(
        amount,
        keydata,
        index,
        seedID,
        coin == Coin.firoTestNet,
      ),
    );
    return mintHex;
  }

  Future<bool> _submitLelantusToNetwork(
      Map<String, dynamic> transactionInfo) async {
    final latestSetId = await getLatestSetId();
    final txid = await submitHexToNetwork(transactionInfo['txHex'] as String);
    // success if txid matches the generated txid
    Logging.instance.log(
        "_submitLelantusToNetwork txid: ${transactionInfo['txid']}",
        level: LogLevel.Info);
    if (txid == transactionInfo['txid']) {
      final index =
          DB.instance.get<dynamic>(boxName: walletId, key: 'mintIndex') as int?;
      final List<Map<dynamic, LelantusCoin>> lelantusCoins =
          getLelantusCoinMap();
      List<Map<dynamic, LelantusCoin>> coins;
      if (lelantusCoins.isEmpty) {
        coins = [];
      } else {
        coins = [...lelantusCoins];
      }

      if (transactionInfo['spendCoinIndexes'] != null) {
        // This is a joinsplit

        // Update all of the coins that have been spent.
        for (final lCoinMap in coins) {
          final lCoin = lCoinMap.values.first;
          if ((transactionInfo['spendCoinIndexes'] as List<int>)
              .contains(lCoin.index)) {
            lCoinMap[lCoinMap.keys.first] = LelantusCoin(
                lCoin.index,
                lCoin.value,
                lCoin.publicCoin,
                lCoin.txId,
                lCoin.anonymitySetId,
                true);
          }
        }

        // if a jmint was made add it to the unspent coin index
        LelantusCoin jmint = LelantusCoin(
            index!,
            transactionInfo['jmintValue'] as int? ?? 0,
            transactionInfo['publicCoin'] as String,
            transactionInfo['txid'] as String,
            latestSetId,
            false);
        if (jmint.value > 0) {
          coins.add({jmint.txId: jmint});
          final jindexes = DB.instance
              .get<dynamic>(boxName: walletId, key: 'jindex') as List?;
          jindexes!.add(index);
          await DB.instance
              .put<dynamic>(boxName: walletId, key: 'jindex', value: jindexes);
          await DB.instance.put<dynamic>(
              boxName: walletId, key: 'mintIndex', value: index + 1);
        }
        await DB.instance.put<dynamic>(
            boxName: walletId, key: '_lelantus_coins', value: coins);

        // add the send transaction
        models.TransactionData data = await lelantusTransactionData;
        Map<String, models.Transaction> transactions =
            data.getAllTransactions();
        transactions[transactionInfo['txid'] as String] =
            models.Transaction.fromLelantusJson(transactionInfo);
        final models.TransactionData newTxData =
            models.TransactionData.fromMap(transactions);
        await DB.instance.put<dynamic>(
            boxName: walletId,
            key: 'latest_lelantus_tx_model',
            value: newTxData);
        final ldata = DB.instance.get<dynamic>(
            boxName: walletId,
            key: 'latest_lelantus_tx_model') as models.TransactionData;
        _lelantusTransactionData = Future(() => ldata);
      } else {
        // This is a mint
        Logging.instance.log("this is a mint", level: LogLevel.Info);

        // TODO: transactionInfo['mintsMap']
        for (final mintMap
            in transactionInfo['mintsMap'] as List<Map<String, dynamic>>) {
          final index = mintMap['index'] as int?;
          LelantusCoin mint = LelantusCoin(
            index!,
            mintMap['value'] as int,
            mintMap['publicCoin'] as String,
            transactionInfo['txid'] as String,
            latestSetId,
            false,
          );
          if (mint.value > 0) {
            coins.add({mint.txId: mint});
            await DB.instance.put<dynamic>(
                boxName: walletId, key: 'mintIndex', value: index + 1);
          }
        }
        // Logging.instance.log(coins);
        await DB.instance.put<dynamic>(
            boxName: walletId, key: '_lelantus_coins', value: coins);
      }
      return true;
    } else {
      // Failed to send to network
      return false;
    }
  }

  Future<FeeObject> _getFees() async {
    try {
      //TODO adjust numbers for different speeds?
      const int f = 1, m = 5, s = 20;

      final fast = await electrumXClient.estimateFee(blocks: f);
      final medium = await electrumXClient.estimateFee(blocks: m);
      final slow = await electrumXClient.estimateFee(blocks: s);

      final feeObject = FeeObject(
        numberOfBlocksFast: f,
        numberOfBlocksAverage: m,
        numberOfBlocksSlow: s,
        fast: Format.decimalAmountToSatoshis(fast),
        medium: Format.decimalAmountToSatoshis(medium),
        slow: Format.decimalAmountToSatoshis(slow),
      );

      Logging.instance.log("fetched fees: $feeObject", level: LogLevel.Info);
      return feeObject;

      // final result = await electrumXClient.getFeeRate();
      //
      // final locale = await Devicelocale.currentLocale;
      // final String fee =
      //     Format.satoshiAmountToPrettyString(result["rate"] as int, locale!);
      //
      // final fees = {
      //   "fast": fee,
      //   "average": fee,
      //   "slow": fee,
      // };
      // final FeeObject feeObject = FeeObject.fromJson(fees);
      // return feeObject;
    } catch (e) {
      Logging.instance
          .log("Exception rethrown from _getFees(): $e", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<ElectrumXNode> _getCurrentNode() async {
    final node = NodeService().getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);

    return ElectrumXNode(
      address: node.host,
      port: node.port,
      name: node.name,
      useSSL: node.useSSL,
      id: node.id,
    );
  }

  //TODO call get transaction and check each tx to see if it is a "received" tx?
  Future<int> _getReceivedTxCount({required String address}) async {
    try {
      final scripthash = AddressUtils.convertToScriptHash(address, _network);
      final transactions =
          await electrumXClient.getHistory(scripthash: scripthash);
      return transactions.length;
    } catch (e) {
      Logging.instance.log(
          "Exception rethrown in _getReceivedTxCount(address: $address): $e",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> checkReceivingAddressForTransactions() async {
    try {
      final String currentExternalAddr = await _getCurrentAddressForChain(0);
      final int numtxs =
          await _getReceivedTxCount(address: currentExternalAddr);
      Logging.instance.log(
          'Number of txs for current receiving: $currentExternalAddr: $numtxs',
          level: LogLevel.Info);

      if (numtxs >= 1) {
        await incrementAddressIndexForChain(
            0); // First increment the receiving index
        final newReceivingIndex =
            DB.instance.get<dynamic>(boxName: walletId, key: 'receivingIndex')
                as int; // Check the new receiving index
        final newReceivingAddress = await _generateAddressForChain(0,
            newReceivingIndex); // Use new index to derive a new receiving address
        await addToAddressesArrayForChain(newReceivingAddress,
            0); // Add that new receiving address to the array of receiving addresses
        _currentReceivingAddress = Future(() =>
            newReceivingAddress); // Set the new receiving address that the service
      }
    } on SocketException catch (se, s) {
      Logging.instance.log(
          "SocketException caught in checkReceivingAddressForTransactions(): $se\n$s",
          level: LogLevel.Error);
      return;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from checkReceivingAddressForTransactions(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> checkChangeAddressForTransactions() async {
    try {
      final String currentExternalAddr = await _getCurrentAddressForChain(1);
      final int numtxs =
          await _getReceivedTxCount(address: currentExternalAddr);
      Logging.instance.log(
          'Number of txs for current change address: $currentExternalAddr: $numtxs',
          level: LogLevel.Info);

      if (numtxs >= 1) {
        await incrementAddressIndexForChain(
            0); // First increment the change index
        final newReceivingIndex =
            DB.instance.get<dynamic>(boxName: walletId, key: 'changeIndex')
                as int; // Check the new change index
        final newReceivingAddress = await _generateAddressForChain(0,
            newReceivingIndex); // Use new index to derive a new change address
        await addToAddressesArrayForChain(newReceivingAddress,
            0); // Add that new receiving address to the array of change addresses
      }
    } on SocketException catch (se, s) {
      Logging.instance.log(
          "SocketException caught in checkChangeAddressForTransactions(): $se\n$s",
          level: LogLevel.Error);
      return;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from checkChangeAddressForTransactions(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<List<String>> _fetchAllOwnAddresses() async {
    final List<String> allAddresses = [];
    final receivingAddresses =
        DB.instance.get<dynamic>(boxName: walletId, key: 'receivingAddresses')
            as List<dynamic>;
    final changeAddresses =
        DB.instance.get<dynamic>(boxName: walletId, key: 'changeAddresses')
            as List<dynamic>;

    for (var i = 0; i < receivingAddresses.length; i++) {
      allAddresses.add(receivingAddresses[i] as String);
    }
    for (var i = 0; i < changeAddresses.length; i++) {
      allAddresses.add(changeAddresses[i] as String);
    }
    return allAddresses;
  }

  Future<List<Map<String, dynamic>>> _fetchHistory(
      List<String> allAddresses) async {
    try {
      List<Map<String, dynamic>> allTxHashes = [];

      final Map<int, Map<String, List<dynamic>>> batches = {};
      final Map<String, String> requestIdToAddressMap = {};
      const batchSizeMax = 100;
      int batchNumber = 0;
      for (int i = 0; i < allAddresses.length; i++) {
        if (batches[batchNumber] == null) {
          batches[batchNumber] = {};
        }
        final scripthash =
            AddressUtils.convertToScriptHash(allAddresses[i], _network);
        final id = Logger.isTestEnv ? "$i" : const Uuid().v1();
        requestIdToAddressMap[id] = allAddresses[i];
        batches[batchNumber]!.addAll({
          id: [scripthash]
        });
        if (i % batchSizeMax == batchSizeMax - 1) {
          batchNumber++;
        }
      }

      for (int i = 0; i < batches.length; i++) {
        final response =
            await _electrumXClient.getBatchHistory(args: batches[i]!);
        for (final entry in response.entries) {
          for (int j = 0; j < entry.value.length; j++) {
            entry.value[j]["address"] = requestIdToAddressMap[entry.key];
            if (!allTxHashes.contains(entry.value[j])) {
              allTxHashes.add(entry.value[j]);
            }
          }
        }
      }

      return allTxHashes;
    } catch (e, s) {
      Logging.instance.log("_fetchHistory: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<models.TransactionData> _fetchTransactionData() async {
    final changeAddresses =
        DB.instance.get<dynamic>(boxName: walletId, key: 'changeAddresses')
            as List<dynamic>;
    final List<String> allAddresses = await _fetchAllOwnAddresses();
    // Logging.instance.log("receiving addresses: $receivingAddresses");
    // Logging.instance.log("change addresses: $changeAddresses");

    List<Map<String, dynamic>> allTxHashes = await _fetchHistory(allAddresses);

    final cachedTransactions =
        DB.instance.get<dynamic>(boxName: walletId, key: 'latest_tx_model')
            as models.TransactionData?;
    int latestTxnBlockHeight =
        DB.instance.get<dynamic>(boxName: walletId, key: "storedTxnDataHeight")
                as int? ??
            0;

    final unconfirmedCachedTransactions =
        cachedTransactions?.getAllTransactions() ?? {};
    unconfirmedCachedTransactions
        .removeWhere((key, value) => value.confirmedStatus);

    if (cachedTransactions != null) {
      for (final tx in allTxHashes.toList(growable: false)) {
        final txHeight = tx["height"] as int;
        if (txHeight > 0 &&
            txHeight < latestTxnBlockHeight - MINIMUM_CONFIRMATIONS) {
          if (unconfirmedCachedTransactions[tx["tx_hash"] as String] == null) {
            allTxHashes.remove(tx);
          }
        }
      }
    }

    List<String> hashes = [];
    for (var element in allTxHashes) {
      hashes.add(element['tx_hash'] as String);
    }
    List<Map<String, dynamic>> allTransactions = await fastFetch(hashes);

    Logging.instance.log("allTransactions length: ${allTransactions.length}",
        level: LogLevel.Info);

    // sort thing stuff
    final currentPrice = await firoPrice;
    final List<Map<String, dynamic>> midSortedArray = [];

    final locale = await Devicelocale.currentLocale;

    Logging.instance.log("refresh the txs", level: LogLevel.Info);
    for (final txObject in allTransactions) {
      // Logging.instance.log(txObject);
      List<String> sendersArray = [];
      List<String> recipientsArray = [];

      // Usually only has value when txType = 'Send'
      int inputAmtSentFromWallet = 0;
      // Usually has value regardless of txType due to change addresses
      int outputAmtAddressedToWallet = 0;

      Map<String, dynamic> midSortedTx = {};
      List<dynamic> aliens = [];

      for (final input in txObject["vin"] as List) {
        final address = input["address"] as String?;
        if (address != null) {
          sendersArray.add(address);
        }
      }

      // Logging.instance.log("sendersArray: $sendersArray");

      for (final output in txObject["vout"] as List) {
        final addresses = output["scriptPubKey"]["addresses"] as List?;
        if (addresses != null && addresses.isNotEmpty) {
          recipientsArray.add(addresses[0] as String);
        }
      }
      // Logging.instance.log("recipientsArray: $recipientsArray");

      final foundInSenders =
          allAddresses.any((element) => sendersArray.contains(element));
      // Logging.instance.log("foundInSenders: $foundInSenders");

      String outAddress = "";

      int fees = 0;

      // If txType = Sent, then calculate inputAmtSentFromWallet, calculate who received how much in aliens array (check outputs)
      if (foundInSenders) {
        int outAmount = 0;
        int inAmount = 0;
        bool nFeesUsed = false;

        for (final input in txObject["vin"] as List) {
          final nFees = input["nFees"];
          if (nFees != null) {
            nFeesUsed = true;
            fees = (Decimal.parse(nFees.toString()) *
                    Decimal.fromInt(Constants.satsPerCoin))
                .toBigInt()
                .toInt();
          }
          final address = input["address"];
          final value = input["valueSat"];
          if (address != null && value != null) {
            if (allAddresses.contains(address)) {
              inputAmtSentFromWallet += value as int;
            }
          }

          if (value != null) {
            inAmount += value as int;
          }
        }

        for (final output in txObject["vout"] as List) {
          final addresses = output["scriptPubKey"]["addresses"] as List?;
          final value = output["value"];
          if (addresses != null && addresses.isNotEmpty) {
            final address = addresses[0] as String;
            if (value != null) {
              if (changeAddresses.contains(address)) {
                inputAmtSentFromWallet -= (Decimal.parse(value.toString()) *
                        Decimal.fromInt(Constants.satsPerCoin))
                    .toBigInt()
                    .toInt();
              } else {
                outAddress = address;
              }
            }
          }
          if (value != null) {
            outAmount += (Decimal.parse(value.toString()) *
                    Decimal.fromInt(Constants.satsPerCoin))
                .toBigInt()
                .toInt();
          }
        }

        fees = nFeesUsed ? fees : inAmount - outAmount;
        inputAmtSentFromWallet -= inAmount - outAmount;
      } else {
        for (final input in txObject["vin"] as List) {
          final nFees = input["nFees"];
          if (nFees != null) {
            fees += (Decimal.parse(nFees.toString()) *
                    Decimal.fromInt(Constants.satsPerCoin))
                .toBigInt()
                .toInt();
          }
        }

        for (final output in txObject["vout"] as List) {
          final addresses = output["scriptPubKey"]["addresses"] as List?;
          if (addresses != null && addresses.isNotEmpty) {
            final address = addresses[0] as String;
            final value = output["value"];
            // Logging.instance.log(address + value.toString());

            if (allAddresses.contains(address)) {
              outputAmtAddressedToWallet += (Decimal.parse(value.toString()) *
                      Decimal.fromInt(Constants.satsPerCoin))
                  .toBigInt()
                  .toInt();
              outAddress = address;
            }
          }
        }
      }

      final int confirms = txObject["confirmations"] as int? ?? 0;

      // create final tx map
      midSortedTx["txid"] = txObject["txid"];
      midSortedTx["confirmed_status"] = confirms >= MINIMUM_CONFIRMATIONS;
      midSortedTx["confirmations"] = confirms;
      midSortedTx["timestamp"] = txObject["blocktime"] ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      if (foundInSenders) {
        midSortedTx["txType"] = "Sent";
        midSortedTx["amount"] = inputAmtSentFromWallet;
        final String worthNow = Format.localizedStringAsFixed(
            value: ((currentPrice * Decimal.fromInt(inputAmtSentFromWallet)) /
                    Decimal.fromInt(Constants.satsPerCoin))
                .toDecimal(scaleOnInfinitePrecision: 2),
            decimalPlaces: 2,
            locale: locale!);
        midSortedTx["worthNow"] = worthNow;
        midSortedTx["worthAtBlockTimestamp"] = worthNow;
        if (txObject["vout"][0]["scriptPubKey"]["type"] == "lelantusmint") {
          midSortedTx["subType"] = "mint";
        }
      } else {
        midSortedTx["txType"] = "Received";
        midSortedTx["amount"] = outputAmtAddressedToWallet;
        final worthNow = Format.localizedStringAsFixed(
            value:
                ((currentPrice * Decimal.fromInt(outputAmtAddressedToWallet)) /
                        Decimal.fromInt(Constants.satsPerCoin))
                    .toDecimal(scaleOnInfinitePrecision: 2),
            decimalPlaces: 2,
            locale: locale!);
        midSortedTx["worthNow"] = worthNow;
        midSortedTx["worthAtBlockTimestamp"] = worthNow;
      }
      midSortedTx["aliens"] = aliens;
      midSortedTx["fees"] = fees;
      midSortedTx["address"] = outAddress;
      midSortedTx["inputSize"] = txObject["vin"].length;
      midSortedTx["outputSize"] = txObject["vout"].length;
      midSortedTx["inputs"] = txObject["vin"];
      midSortedTx["outputs"] = txObject["vout"];

      final int height = txObject["height"] as int? ?? 0;
      midSortedTx["height"] = height;

      if (height >= latestTxnBlockHeight) {
        latestTxnBlockHeight = height;
      }

      midSortedArray.add(midSortedTx);
    }

    // sort by date  ----  //TODO not sure if needed
    // shouldn't be any issues with a null timestamp but I got one at some point?
    midSortedArray.sort((a, b) {
      final aT = a["timestamp"];
      final bT = b["timestamp"];

      if (aT == null && bT == null) {
        return 0;
      } else if (aT == null) {
        return -1;
      } else if (bT == null) {
        return 1;
      } else {
        return (bT as int) - (aT as int);
      }
    });

    // buildDateTimeChunks
    final Map<String, dynamic> result = {"dateTimeChunks": <dynamic>[]};
    final dateArray = <dynamic>[];

    for (int i = 0; i < midSortedArray.length; i++) {
      final txObject = midSortedArray[i];
      final date =
          models.extractDateFromTimestamp(txObject["timestamp"] as int);
      final txTimeArray = [txObject["timestamp"], date];

      if (dateArray.contains(txTimeArray[1])) {
        result["dateTimeChunks"].forEach((dynamic chunk) {
          if (models.extractDateFromTimestamp(chunk["timestamp"] as int) ==
              txTimeArray[1]) {
            if (chunk["transactions"] == null) {
              chunk["transactions"] = <Map<String, dynamic>>[];
            }
            chunk["transactions"].add(txObject);
          }
        });
      } else {
        dateArray.add(txTimeArray[1]);
        final chunk = {
          "timestamp": txTimeArray[0],
          "transactions": [txObject],
        };
        result["dateTimeChunks"].add(chunk);
      }
    }

    final transactionsMap = cachedTransactions?.getAllTransactions() ?? {};
    transactionsMap
        .addAll(models.TransactionData.fromJson(result).getAllTransactions());

    final txModel = models.TransactionData.fromMap(transactionsMap);

    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'storedTxnDataHeight',
        value: latestTxnBlockHeight);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'latest_tx_model', value: txModel);

    return txModel;
  }

  Future<UtxoData> _fetchUtxoData() async {
    final List<String> allAddresses = await _fetchAllOwnAddresses();

    try {
      final fetchedUtxoList = <List<Map<String, dynamic>>>[];

      final Map<int, Map<String, List<dynamic>>> batches = {};
      const batchSizeMax = 100;
      int batchNumber = 0;
      for (int i = 0; i < allAddresses.length; i++) {
        if (batches[batchNumber] == null) {
          batches[batchNumber] = {};
        }
        final scripthash =
            AddressUtils.convertToScriptHash(allAddresses[i], _network);
        batches[batchNumber]!.addAll({
          scripthash: [scripthash]
        });
        if (i % batchSizeMax == batchSizeMax - 1) {
          batchNumber++;
        }
      }

      for (int i = 0; i < batches.length; i++) {
        final response =
            await _electrumXClient.getBatchUTXOs(args: batches[i]!);
        for (final entry in response.entries) {
          if (entry.value.isNotEmpty) {
            fetchedUtxoList.add(entry.value);
          }
        }
      }
      final priceData =
          await _priceAPI.getPricesAnd24hChange(baseCurrency: _prefs.currency);
      Decimal currentPrice = priceData[coin]?.item1 ?? Decimal.zero;
      final List<Map<String, dynamic>> outputArray = [];
      int satoshiBalance = 0;
      int satoshiBalancePending = 0;

      for (int i = 0; i < fetchedUtxoList.length; i++) {
        for (int j = 0; j < fetchedUtxoList[i].length; j++) {
          int value = fetchedUtxoList[i][j]["value"] as int;
          satoshiBalance += value;

          final txn = await cachedElectrumXClient.getTransaction(
            txHash: fetchedUtxoList[i][j]["tx_hash"] as String,
            verbose: true,
            coin: coin,
          );

          final Map<String, dynamic> utxo = {};
          final int confirmations = txn["confirmations"] as int? ?? 0;
          final bool confirmed = confirmations >= MINIMUM_CONFIRMATIONS;
          if (!confirmed) {
            satoshiBalancePending += value;
          }

          utxo["txid"] = txn["txid"];
          utxo["vout"] = fetchedUtxoList[i][j]["tx_pos"];
          utxo["value"] = value;

          utxo["status"] = <String, dynamic>{};
          utxo["status"]["confirmed"] = confirmed;
          utxo["status"]["confirmations"] = confirmations;
          utxo["status"]["confirmed"] =
              txn["confirmations"] == null ? false : txn["confirmations"] > 0;

          utxo["status"]["block_height"] = fetchedUtxoList[i][j]["height"];
          utxo["status"]["block_hash"] = txn["blockhash"];
          utxo["status"]["block_time"] = txn["blocktime"];

          final fiatValue = ((Decimal.fromInt(value) * currentPrice) /
                  Decimal.fromInt(Constants.satsPerCoin))
              .toDecimal(scaleOnInfinitePrecision: 2);
          utxo["rawWorth"] = fiatValue;
          utxo["fiatWorth"] = fiatValue.toString();
          utxo["is_coinbase"] = txn['vin'][0]['coinbase'] != null;
          outputArray.add(utxo);
        }
      }

      Decimal currencyBalanceRaw =
          ((Decimal.fromInt(satoshiBalance) * currentPrice) /
                  Decimal.fromInt(Constants.satsPerCoin))
              .toDecimal(scaleOnInfinitePrecision: 2);

      final Map<String, dynamic> result = {
        "total_user_currency": currencyBalanceRaw.toString(),
        "total_sats": satoshiBalance,
        "total_btc": (Decimal.fromInt(satoshiBalance) /
                Decimal.fromInt(Constants.satsPerCoin))
            .toDecimal(scaleOnInfinitePrecision: Constants.decimalPlaces)
            .toString(),
        "outputArray": outputArray,
        "unconfirmed": satoshiBalancePending,
      };

      final dataModel = UtxoData.fromJson(result);

      final List<UtxoObject> allOutputs = dataModel.unspentOutputArray;
      Logging.instance
          .log('Outputs fetched: $allOutputs', level: LogLevel.Info);
      await _sortOutputs(allOutputs);
      await DB.instance.put<dynamic>(
          boxName: walletId, key: 'latest_utxo_model', value: dataModel);
      // await DB.instance.put<dynamic>(
      //     boxName: walletId,
      //     key: 'totalBalance',
      //     value: dataModel.satoshiBalance);
      return dataModel;
    } catch (e, s) {
      Logging.instance
          .log("Output fetch unsuccessful: $e\n$s", level: LogLevel.Error);
      final latestTxModel =
          DB.instance.get<dynamic>(boxName: walletId, key: 'latest_utxo_model')
              as models.UtxoData?;

      if (latestTxModel == null) {
        final emptyModel = {
          "total_user_currency": "0.00",
          "total_sats": 0,
          "total_btc": "0",
          "outputArray": <dynamic>[]
        };
        return UtxoData.fromJson(emptyModel);
      } else {
        Logging.instance
            .log("Old output model located", level: LogLevel.Warning);
        return latestTxModel;
      }
    }
  }

  Future<models.TransactionData> _getLelantusTransactionData() async {
    final latestModel = DB.instance.get<dynamic>(
        boxName: walletId,
        key: 'latest_lelantus_tx_model') as models.TransactionData?;

    if (latestModel == null) {
      final emptyModel = {"dateTimeChunks": <dynamic>[]};
      return models.TransactionData.fromJson(emptyModel);
    } else {
      Logging.instance
          .log("Old transaction model located", level: LogLevel.Warning);
      return latestModel;
    }
  }

  /// Returns the latest receiving/change (external/internal) address for the wallet depending on [chain]
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<String> _getCurrentAddressForChain(int chain) async {
    if (chain == 0) {
      final externalChainArray = (DB.instance.get<dynamic>(
          boxName: walletId, key: 'receivingAddresses')) as List<dynamic>;
      return externalChainArray.last as String;
    } else {
      // Here, we assume that chain == 1
      final internalChainArray =
          (DB.instance.get<dynamic>(boxName: walletId, key: 'changeAddresses'))
              as List<dynamic>;
      return internalChainArray.last as String;
    }
  }

  Future<void> fillAddresses(String suppliedMnemonic,
      {int perBatch = 50, int numberOfThreads = 4}) async {
    if (numberOfThreads <= 0) {
      numberOfThreads = 1;
    }
    if (Platform.environment["FLUTTER_TEST"] == "true" || integrationTestFlag) {
      perBatch = 10;
      numberOfThreads = 4;
    }

    final receiveDerivationsString =
        await _secureStore.read(key: "${walletId}_receiveDerivations");
    final changeDerivationsString =
        await _secureStore.read(key: "${walletId}_changeDerivations");

    var receiveDerivations = Map<String, dynamic>.from(
        jsonDecode(receiveDerivationsString ?? "{}") as Map);
    var changeDerivations = Map<String, dynamic>.from(
        jsonDecode(changeDerivationsString ?? "{}") as Map);

    final int start = receiveDerivations.length;

    List<ReceivePort> ports = List.empty(growable: true);
    for (int i = 0; i < numberOfThreads; i++) {
      ReceivePort receivePort = await getIsolate({
        "function": "isolateDerive",
        "mnemonic": suppliedMnemonic,
        "from": start + i * perBatch,
        "to": start + (i + 1) * perBatch,
        "network": _network,
      });
      ports.add(receivePort);
    }
    for (int i = 0; i < numberOfThreads; i++) {
      ReceivePort receivePort = ports.elementAt(i);
      var message = await receivePort.first;
      if (message is String) {
        Logging.instance.log("this is a string", level: LogLevel.Error);
        stop(receivePort);
        throw Exception("isolateDerive isolate failed");
      }
      stop(receivePort);
      Logging.instance.log('Closing isolateDerive!', level: LogLevel.Info);
      receiveDerivations.addAll(message['receive'] as Map<String, dynamic>);
      changeDerivations.addAll(message['change'] as Map<String, dynamic>);
    }
    Logging.instance.log("isolate derives", level: LogLevel.Info);
    // Logging.instance.log(receiveDerivations);
    // Logging.instance.log(changeDerivations);

    final newReceiveDerivationsString = jsonEncode(receiveDerivations);
    final newChangeDerivationsString = jsonEncode(changeDerivations);

    await _secureStore.write(
        key: "${walletId}_receiveDerivations",
        value: newReceiveDerivationsString);
    await _secureStore.write(
        key: "${walletId}_changeDerivations",
        value: newChangeDerivationsString);
  }

  /// Generates a new internal or external chain address for the wallet using a BIP84 derivation path.
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  /// [index] - This can be any integer >= 0
  Future<String> _generateAddressForChain(int chain, int index) async {
    // final wallet = await Hive.openBox(this._walletId);
    final mnemonic = await _secureStore.read(key: '${_walletId}_mnemonic');
    Map<String, dynamic>? derivations;
    if (chain == 0) {
      final receiveDerivationsString =
          await _secureStore.read(key: "${walletId}_receiveDerivations");
      derivations = Map<String, dynamic>.from(
          jsonDecode(receiveDerivationsString ?? "{}") as Map);
    } else if (chain == 1) {
      final changeDerivationsString =
          await _secureStore.read(key: "${walletId}_changeDerivations");
      derivations = Map<String, dynamic>.from(
          jsonDecode(changeDerivationsString ?? "{}") as Map);
    }

    if (derivations!.isNotEmpty) {
      if (derivations["$index"] == null) {
        await fillAddresses(mnemonic!,
            numberOfThreads: Platform.numberOfProcessors - isolates.length - 1);
        Logging.instance.log("calling _generateAddressForChain recursively",
            level: LogLevel.Info);
        return _generateAddressForChain(chain, index);
      }
      return derivations["$index"]['address'] as String;
    } else {
      final node = await compute(
          getBip32NodeWrapper, Tuple4(chain, index, mnemonic!, _network));
      return P2PKH(network: _network, data: PaymentData(pubkey: node.publicKey))
          .data
          .address!;
    }
  }

  /// Increases the index for either the internal or external chain, depending on [chain].
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<void> incrementAddressIndexForChain(int chain) async {
    if (chain == 0) {
      final newIndex =
          DB.instance.get<dynamic>(boxName: walletId, key: 'receivingIndex') +
              1;
      await DB.instance.put<dynamic>(
          boxName: walletId, key: 'receivingIndex', value: newIndex);
    } else {
      // Here we assume chain == 1 since it can only be either 0 or 1
      final newIndex =
          DB.instance.get<dynamic>(boxName: walletId, key: 'changeIndex') + 1;
      await DB.instance
          .put<dynamic>(boxName: walletId, key: 'changeIndex', value: newIndex);
    }
  }

  /// Adds [address] to the relevant chain's address array, which is determined by [chain].
  /// [address] - Expects a standard native segwit address
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<void> addToAddressesArrayForChain(String address, int chain) async {
    String chainArray = '';
    if (chain == 0) {
      chainArray = 'receivingAddresses';
    } else {
      chainArray = 'changeAddresses';
    }

    final addressArray =
        DB.instance.get<dynamic>(boxName: walletId, key: chainArray);
    if (addressArray == null) {
      Logging.instance.log(
          'Attempting to add the following to array for chain $chain:${[
            address
          ]}',
          level: LogLevel.Info);
      await DB.instance
          .put<dynamic>(boxName: walletId, key: chainArray, value: [address]);
    } else {
      // Make a deep copy of the existing list
      final List<String> newArray = [];
      addressArray
          .forEach((dynamic _address) => newArray.add(_address as String));
      newArray.add(address); // Add the address passed into the method
      await DB.instance
          .put<dynamic>(boxName: walletId, key: chainArray, value: newArray);
    }
  }

  /// Takes in a list of UtxoObjects and adds a name (dependent on object index within list)
  /// and checks for the txid associated with the utxo being blocked and marks it accordingly.
  /// Now also checks for output labeling.
  Future<void> _sortOutputs(List<UtxoObject> utxos) async {
    final blockedHashArray =
        DB.instance.get<dynamic>(boxName: walletId, key: 'blocked_tx_hashes')
            as List<dynamic>?;
    final List<String> lst = [];
    if (blockedHashArray != null) {
      for (var hash in blockedHashArray) {
        lst.add(hash as String);
      }
    }
    final labels =
        DB.instance.get<dynamic>(boxName: walletId, key: 'labels') as Map? ??
            {};

    _outputsList = [];

    for (var i = 0; i < utxos.length; i++) {
      if (labels[utxos[i].txid] != null) {
        utxos[i].txName = labels[utxos[i].txid] as String? ?? "";
      } else {
        utxos[i].txName = 'Output #$i';
      }

      if (utxos[i].status.confirmed == false) {
        _outputsList.add(utxos[i]);
      } else {
        if (lst.contains(utxos[i].txid)) {
          utxos[i].blocked = true;
          _outputsList.add(utxos[i]);
        } else if (!lst.contains(utxos[i].txid)) {
          _outputsList.add(utxos[i]);
        }
      }
    }
  }

  @override
  Future<void> fullRescan(
    int maxUnusedAddressGap,
    int maxNumberOfIndexesToCheck,
  ) async {
    Logging.instance.log("Starting full rescan!", level: LogLevel.Info);
    // timer?.cancel();
    // for (final isolate in isolates.values) {
    //   isolate.kill(priority: Isolate.immediate);
    // }
    // isolates.clear();
    longMutex = true;
    GlobalEventBus.instance.fire(
      WalletSyncStatusChangedEvent(
        WalletSyncStatus.syncing,
        walletId,
        coin,
      ),
    );

    // clear cache
    await _cachedElectrumXClient.clearSharedTransactionCache(coin: coin);

    // back up data
    await _rescanBackup();

    try {
      final mnemonic = await _secureStore.read(key: '${_walletId}_mnemonic');
      await _recoverWalletFromBIP32SeedPhrase(mnemonic!, maxUnusedAddressGap);

      longMutex = false;
      Logging.instance.log("Full rescan complete!", level: LogLevel.Info);
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );
    } catch (e, s) {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.unableToSync,
          walletId,
          coin,
        ),
      );

      // restore from backup
      await _rescanRestore();

      longMutex = false;
      Logging.instance.log("Exception rethrown from fullRescan(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _rescanBackup() async {
    Logging.instance.log("starting rescan backup", level: LogLevel.Info);

    // backup current and clear data
    final tempReceivingAddresses =
        DB.instance.get<dynamic>(boxName: walletId, key: 'receivingAddresses');
    await DB.instance.delete<dynamic>(
      key: 'receivingAddresses',
      boxName: walletId,
    );
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingAddresses_BACKUP',
        value: tempReceivingAddresses);

    final tempChangeAddresses =
        DB.instance.get<dynamic>(boxName: walletId, key: 'changeAddresses');
    await DB.instance.delete<dynamic>(
      key: 'changeAddresses',
      boxName: walletId,
    );
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'changeAddresses_BACKUP',
        value: tempChangeAddresses);

    final tempReceivingIndex =
        DB.instance.get<dynamic>(boxName: walletId, key: 'receivingIndex');
    await DB.instance.delete<dynamic>(
      key: 'receivingIndex',
      boxName: walletId,
    );
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingIndex_BACKUP',
        value: tempReceivingIndex);

    final tempChangeIndex =
        DB.instance.get<dynamic>(boxName: walletId, key: 'changeIndex');
    await DB.instance.delete<dynamic>(
      key: 'changeIndex',
      boxName: walletId,
    );
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'changeIndex_BACKUP', value: tempChangeIndex);

    final receiveDerivationsString =
        await _secureStore.read(key: "${walletId}_receiveDerivations");
    final changeDerivationsString =
        await _secureStore.read(key: "${walletId}_changeDerivations");

    await _secureStore.write(
        key: "${walletId}_receiveDerivations_BACKUP",
        value: receiveDerivationsString);
    await _secureStore.write(
        key: "${walletId}_changeDerivations_BACKUP",
        value: changeDerivationsString);

    await _secureStore.write(
        key: "${walletId}_receiveDerivations", value: null);
    await _secureStore.write(key: "${walletId}_changeDerivations", value: null);

    // back up but no need to delete
    final tempMintIndex =
        DB.instance.get<dynamic>(boxName: walletId, key: 'mintIndex');
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'mintIndex_BACKUP', value: tempMintIndex);

    final tempLelantusCoins =
        DB.instance.get<dynamic>(boxName: walletId, key: '_lelantus_coins');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: '_lelantus_coins_BACKUP',
        value: tempLelantusCoins);

    final tempJIndex =
        DB.instance.get<dynamic>(boxName: walletId, key: 'jindex');
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'jindex_BACKUP', value: tempJIndex);

    final tempLelantusTxModel = DB.instance
        .get<dynamic>(boxName: walletId, key: 'latest_lelantus_tx_model');
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'latest_lelantus_tx_model_BACKUP',
        value: tempLelantusTxModel);

    Logging.instance.log("rescan backup complete", level: LogLevel.Info);
  }

  Future<void> _rescanRestore() async {
    Logging.instance.log("starting rescan restore", level: LogLevel.Info);

    // restore from backup
    final tempReceivingAddresses = DB.instance
        .get<dynamic>(boxName: walletId, key: 'receivingAddresses_BACKUP');
    final tempChangeAddresses = DB.instance
        .get<dynamic>(boxName: walletId, key: 'changeAddresses_BACKUP');
    final tempReceivingIndex = DB.instance
        .get<dynamic>(boxName: walletId, key: 'receivingIndex_BACKUP');
    final tempChangeIndex =
        DB.instance.get<dynamic>(boxName: walletId, key: 'changeIndex_BACKUP');
    final tempMintIndex =
        DB.instance.get<dynamic>(boxName: walletId, key: 'mintIndex_BACKUP');
    final tempLelantusCoins = DB.instance
        .get<dynamic>(boxName: walletId, key: '_lelantus_coins_BACKUP');
    final tempJIndex =
        DB.instance.get<dynamic>(boxName: walletId, key: 'jindex_BACKUP');
    final tempLelantusTxModel = DB.instance.get<dynamic>(
        boxName: walletId, key: 'latest_lelantus_tx_model_BACKUP');

    final receiveDerivationsString =
        await _secureStore.read(key: "${walletId}_receiveDerivations_BACKUP");
    final changeDerivationsString =
        await _secureStore.read(key: "${walletId}_changeDerivations_BACKUP");

    await _secureStore.write(
        key: "${walletId}_receiveDerivations", value: receiveDerivationsString);
    await _secureStore.write(
        key: "${walletId}_changeDerivations", value: changeDerivationsString);

    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingAddresses',
        value: tempReceivingAddresses);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'changeAddresses', value: tempChangeAddresses);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'receivingIndex', value: tempReceivingIndex);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'changeIndex', value: tempChangeIndex);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'mintIndex', value: tempMintIndex);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: '_lelantus_coins', value: tempLelantusCoins);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: 'jindex', value: tempJIndex);
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'latest_lelantus_tx_model',
        value: tempLelantusTxModel);

    Logging.instance.log("rescan restore  complete", level: LogLevel.Info);
  }

  /// wrapper for _recoverWalletFromBIP32SeedPhrase()
  @override
  Future<void> recoverFromMnemonic({
    required String mnemonic,
    required int maxUnusedAddressGap,
    required int maxNumberOfIndexesToCheck,
    required int height,
  }) async {
    try {
      await compute(
        _setTestnetWrapper,
        coin == Coin.firoTestNet,
      );
      Logging.instance.log("IS_INTEGRATION_TEST: $integrationTestFlag",
          level: LogLevel.Info);
      if (!integrationTestFlag) {
        final features = await electrumXClient.getServerFeatures();
        Logging.instance.log("features: $features", level: LogLevel.Info);
        switch (coin) {
          case Coin.firo:
            if (features['genesis_hash'] != GENESIS_HASH_MAINNET) {
              throw Exception("genesis hash does not match main net!");
            }
            break;
          case Coin.firoTestNet:
            if (features['genesis_hash'] != GENESIS_HASH_TESTNET) {
              throw Exception("genesis hash does not match test net!");
            }
            break;
          default:
            throw Exception(
                "Attempted to generate a FiroWallet using a non firo coin type: ${coin.name}");
        }
        // if (_networkType == BasicNetworkType.main) {
        //   if (features['genesis_hash'] != GENESIS_HASH_MAINNET) {
        //     throw Exception("genesis hash does not match main net!");
        //   }
        // } else if (_networkType == BasicNetworkType.test) {
        //   if (features['genesis_hash'] != GENESIS_HASH_TESTNET) {
        //     throw Exception("genesis hash does not match test net!");
        //   }
        // }
      }
      // this should never fail
      if ((await _secureStore.read(key: '${_walletId}_mnemonic')) != null) {
        throw Exception("Attempted to overwrite mnemonic on restore!");
      }
      await _secureStore.write(
          key: '${_walletId}_mnemonic', value: mnemonic.trim());
      await _recoverWalletFromBIP32SeedPhrase(
          mnemonic.trim(), maxUnusedAddressGap);

      await compute(
        _setTestnetWrapper,
        false,
      );
    } catch (e, s) {
      await compute(
        _setTestnetWrapper,
        false,
      );
      Logging.instance.log(
          "Exception rethrown from recoverFromMnemonic(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  bool longMutex = false;

  Future<Map<int, dynamic>> getSetDataMap(int latestSetId) async {
    final Map<int, dynamic> setDataMap = {};
    final anonymitySets = await fetchAnonymitySets();
    for (int setId = 1; setId <= latestSetId; setId++) {
      final setData = anonymitySets
          .firstWhere((element) => element["setId"] == setId, orElse: () => {});

      if (setData.isNotEmpty) {
        setDataMap[setId] = setData;
      }
    }
    return setDataMap;
  }

  Future<void> _makeDerivations(
      String suppliedMnemonic, int maxUnusedAddressGap) async {
    List<String> receivingAddressArray = [];
    List<String> changeAddressArray = [];

    int receivingIndex = -1;
    int changeIndex = -1;

    // The gap limit will be capped at 20
    int receivingGapCounter = 0;
    int changeGapCounter = 0;

    await fillAddresses(suppliedMnemonic,
        numberOfThreads: Platform.numberOfProcessors - isolates.length - 1);

    final receiveDerivationsString =
        await _secureStore.read(key: "${walletId}_receiveDerivations");
    final changeDerivationsString =
        await _secureStore.read(key: "${walletId}_changeDerivations");

    final receiveDerivations = Map<String, dynamic>.from(
        jsonDecode(receiveDerivationsString ?? "{}") as Map);
    final changeDerivations = Map<String, dynamic>.from(
        jsonDecode(changeDerivationsString ?? "{}") as Map);

    // log("rcv: $receiveDerivations");
    // log("chg: $changeDerivations");

    // Deriving and checking for receiving addresses
    for (var i = 0; i < receiveDerivations.length; i++) {
      // Break out of loop when receivingGapCounter hits maxUnusedAddressGap
      // Same gap limit for change as for receiving, breaks when it hits maxUnusedAddressGap
      if (receivingGapCounter >= maxUnusedAddressGap &&
          changeGapCounter >= maxUnusedAddressGap) {
        break;
      }

      final receiveDerivation = receiveDerivations["$i"];
      final address = receiveDerivation['address'] as String;

      final changeDerivation = changeDerivations["$i"];
      final _address = changeDerivation['address'] as String;
      Future<int>? futureNumTxs;
      Future<int>? _futureNumTxs;
      if (receivingGapCounter < maxUnusedAddressGap) {
        futureNumTxs = _getReceivedTxCount(address: address);
      }
      if (changeGapCounter < maxUnusedAddressGap) {
        _futureNumTxs = _getReceivedTxCount(address: _address);
      }
      try {
        if (futureNumTxs != null) {
          int numTxs = await futureNumTxs;
          if (numTxs >= 1) {
            receivingIndex = i;
            receivingAddressArray.add(address);
          } else if (numTxs == 0) {
            receivingGapCounter += 1;
          }
        }
      } catch (e, s) {
        Logging.instance.log(
            "Exception rethrown from recoverWalletFromBIP32SeedPhrase(): $e\n$s",
            level: LogLevel.Error);
        rethrow;
      }

      try {
        if (_futureNumTxs != null) {
          int numTxs = await _futureNumTxs;
          if (numTxs >= 1) {
            changeIndex = i;
            changeAddressArray.add(_address);
          } else if (numTxs == 0) {
            changeGapCounter += 1;
          }
        }
      } catch (e, s) {
        Logging.instance.log(
            "Exception rethrown from recoverWalletFromBIP32SeedPhrase(): $e\n$s",
            level: LogLevel.Error);
        rethrow;
      }
    }

    // If restoring a wallet that never received any funds, then set receivingArray manually
    // If we didn't do this, it'd store an empty array
    if (receivingIndex == -1) {
      final String receivingAddress = await _generateAddressForChain(0, 0);
      receivingAddressArray.add(receivingAddress);
    }

    // If restoring a wallet that never sent any funds with change, then set changeArray
    // manually. If we didn't do this, it'd store an empty array.
    if (changeIndex == -1) {
      final String changeAddress = await _generateAddressForChain(1, 0);
      changeAddressArray.add(changeAddress);
    }

    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingAddresses',
        value: receivingAddressArray);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'changeAddresses', value: changeAddressArray);
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'receivingIndex',
        value: receivingIndex == -1 ? 0 : receivingIndex);
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'changeIndex',
        value: changeIndex == -1 ? 0 : changeIndex);
  }

  /// Recovers wallet from [suppliedMnemonic]. Expects a valid mnemonic.
  Future<void> _recoverWalletFromBIP32SeedPhrase(
      String suppliedMnemonic, int maxUnusedAddressGap) async {
    longMutex = true;
    Logging.instance
        .log("PROCESSORS ${Platform.numberOfProcessors}", level: LogLevel.Info);
    try {
      final latestSetId = await getLatestSetId();
      final setDataMap = getSetDataMap(latestSetId);
      final usedSerialNumbers = getUsedCoinSerials();
      final makeDerivations =
          _makeDerivations(suppliedMnemonic, maxUnusedAddressGap);

      await DB.instance
          .put<dynamic>(boxName: walletId, key: "id", value: _walletId);
      await DB.instance
          .put<dynamic>(boxName: walletId, key: "isFavorite", value: false);

      await Future.wait([usedSerialNumbers, setDataMap, makeDerivations]);

      await _restore(latestSetId, await setDataMap, await usedSerialNumbers);
      longMutex = false;
    } catch (e, s) {
      longMutex = false;
      Logging.instance.log(
          "Exception rethrown from recoverWalletFromBIP32SeedPhrase(): $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<void> _restore(int latestSetId, Map<dynamic, dynamic> setDataMap,
      dynamic usedSerialNumbers) async {
    final mnemonic = await _secureStore.read(key: '${_walletId}_mnemonic');
    final dataFuture = _txnData;
    final String currency = _prefs.currency;
    final Decimal currentPrice = await firoPrice;

    ReceivePort receivePort = await getIsolate({
      "function": "restore",
      "mnemonic": mnemonic,
      "coin": coin,
      "latestSetId": latestSetId,
      "setDataMap": setDataMap,
      "usedSerialNumbers": usedSerialNumbers,
      "network": _network,
    });

    await Future.wait([dataFuture]);
    var result = await receivePort.first;
    if (result is String) {
      Logging.instance
          .log("restore() ->> this is a string", level: LogLevel.Error);
      stop(receivePort);
      throw Exception("isolate restore failed.");
    }
    stop(receivePort);

    final message = await staticProcessRestore(
        (await dataFuture), result as Map<dynamic, dynamic>);

    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'mintIndex', value: message['mintIndex']);
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: '_lelantus_coins',
        value: message['_lelantus_coins']);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'jindex', value: message['jindex']);

    final transactionMap =
        message["newTxMap"] as Map<String, models.Transaction>;

    // Create the joinsplit transactions.
    final spendTxs = await getJMintTransactions(
        _cachedElectrumXClient,
        message["spendTxIds"] as List<String>,
        currency,
        coin,
        currentPrice,
        (await Devicelocale.currentLocale)!);
    Logging.instance.log(spendTxs, level: LogLevel.Info);
    for (var element in spendTxs) {
      transactionMap[element.txid] = element;
    }

    final models.TransactionData newTxData =
        models.TransactionData.fromMap(transactionMap);

    _lelantusTransactionData = Future(() => newTxData);

    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'latest_lelantus_tx_model', value: newTxData);
  }

  Future<List<Map<String, dynamic>>> fetchAnonymitySets() async {
    try {
      final latestSetId = await getLatestSetId();

      final List<Map<String, dynamic>> sets = [];
      List<Future<Map<String, dynamic>>> anonFutures = [];
      for (int i = 1; i <= latestSetId; i++) {
        final set = cachedElectrumXClient.getAnonymitySet(
          groupId: "$i",
          coin: coin,
        );
        anonFutures.add(set);
      }
      await Future.wait(anonFutures);
      for (int i = 1; i <= latestSetId; i++) {
        Map<String, dynamic> set = (await anonFutures[i - 1]);
        set["setId"] = i;
        sets.add(set);
      }
      return sets;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from refreshAnonymitySets: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<dynamic> _createJoinSplitTransaction(
      int spendAmount, String address, bool subtractFeeFromAmount) async {
    final price = await firoPrice;
    final mnemonic = await _secureStore.read(key: '${_walletId}_mnemonic');
    final index = DB.instance.get<dynamic>(boxName: walletId, key: 'mintIndex');
    final lelantusEntry = await _getLelantusEntry();
    final anonymitySets = await fetchAnonymitySets();
    final locktime = await getBlockHead(electrumXClient);
    final locale = await Devicelocale.currentLocale;

    ReceivePort receivePort = await getIsolate({
      "function": "createJoinSplit",
      "spendAmount": spendAmount,
      "address": address,
      "subtractFeeFromAmount": subtractFeeFromAmount,
      "mnemonic": mnemonic,
      "index": index,
      "price": price,
      "lelantusEntries": lelantusEntry,
      "locktime": locktime,
      "coin": coin,
      "network": _network,
      "_anonymity_sets": anonymitySets,
      "locale": locale,
    });
    var message = await receivePort.first;
    if (message is String) {
      Logging.instance
          .log("Error in CreateJoinSplit: $message", level: LogLevel.Error);
      stop(receivePort);
      return 3;
    }
    if (message is int) {
      stop(receivePort);
      return message;
    }
    stop(receivePort);
    Logging.instance.log('Closing createJoinSplit!', level: LogLevel.Info);
    return message;
  }

  Future<int> getLatestSetId() async {
    try {
      final id = await electrumXClient.getLatestCoinId();
      return id;
    } catch (e, s) {
      Logging.instance.log("Exception rethrown in firo_wallet.dart: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  Future<List<dynamic>> getUsedCoinSerials() async {
    try {
      final response = await cachedElectrumXClient.getUsedCoinSerials(
        coin: coin,
      );
      return response;
    } catch (e, s) {
      Logging.instance.log("Exception rethrown in firo_wallet.dart: $e\n$s",
          level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<void> exit() async {
    _hasCalledExit = true;
    timer?.cancel();
    timer = null;
    stopNetworkAlivePinging();
    for (final isolate in isolates.values) {
      isolate.kill(priority: Isolate.immediate);
    }
    isolates.clear();
    Logging.instance
        .log("$walletName firo_wallet exit finished", level: LogLevel.Info);
  }

  bool _hasCalledExit = false;

  @override
  bool get hasCalledExit => _hasCalledExit;

  bool isActive = false;

  @override
  void Function(bool)? get onIsActiveWalletChanged => (isActive) async {
        timer?.cancel();
        timer = null;
        if (isActive) {
          await compute(
            _setTestnetWrapper,
            coin == Coin.firoTestNet,
          );
        } else {
          await compute(
            _setTestnetWrapper,
            false,
          );
        }
        this.isActive = isActive;
      };

  Future<dynamic> getCoinsToJoinSplit(
    int required,
  ) async {
    List<DartLelantusEntry> coins = await _getLelantusEntry();
    if (required > LELANTUS_VALUE_SPEND_LIMIT_PER_TRANSACTION) {
      return false;
    }

    int availableBalance = coins.fold(
        0, (previousValue, element) => previousValue + element.amount);

    if (required > availableBalance) {
      return false;
    }

    // sort by biggest amount. if it is same amount we will prefer the older block
    coins.sort((a, b) =>
        (a.amount != b.amount ? a.amount > b.amount : a.height < b.height)
            ? -1
            : 1);
    int spendVal = 0;

    List<DartLelantusEntry> coinsToSpend = [];

    while (spendVal < required) {
      if (coins.isEmpty) {
        break;
      }

      DartLelantusEntry? chosen;
      int need = required - spendVal;

      var itr = coins.first;
      if (need >= itr.amount) {
        chosen = itr;
        coins.remove(itr);
      } else {
        for (int index = coins.length - 1; index != 0; index--) {
          var coinIt = coins[index];
          var nextItr = coins[index - 1];

          if (coinIt.amount >= need &&
              (index - 1 == 0 || nextItr.amount != coinIt.amount)) {
            chosen = coinIt;
            coins.remove(chosen);
            break;
          }
        }
      }

      // TODO: investigate the bug here where chosen is null, conditions, given one mint
      spendVal += chosen!.amount;
      coinsToSpend.insert(coinsToSpend.length, chosen);
    }

    // sort by group id ay ascending order. it is mandatory for creating proper joinsplit
    coinsToSpend.sort((a, b) => a.anonymitySetId < b.anonymitySetId ? 1 : -1);

    int changeToMint = spendVal - required;
    List<int> indices = [];
    for (var l in coinsToSpend) {
      indices.add(l.index);
    }
    List<DartLelantusEntry> coinsToBeSpentOut = [];
    coinsToBeSpentOut.addAll(coinsToSpend);

    return {"changeToMint": changeToMint, "coinsToSpend": coinsToBeSpentOut};
  }

  Future<int> estimateJoinSplitFee(
    int spendAmount,
  ) async {
    var lelantusEntry = await _getLelantusEntry();
    final balance = await availableBalance;
    int spendAmount =
        (balance * Decimal.fromInt(Constants.satsPerCoin)).toBigInt().toInt();
    if (spendAmount == 0 || lelantusEntry.isEmpty) {
      return LelantusFeeData(0, 0, []).fee;
    }
    ReceivePort receivePort = await getIsolate({
      "function": "estimateJoinSplit",
      "spendAmount": spendAmount,
      "subtractFeeFromAmount": true,
      "lelantusEntries": lelantusEntry,
      "coin": coin,
    });

    final message = await receivePort.first;
    if (message is String) {
      Logging.instance.log("this is a string", level: LogLevel.Error);
      stop(receivePort);
      throw Exception("_fetchMaxFee isolate failed");
    }
    stop(receivePort);
    Logging.instance.log('Closing estimateJoinSplit!', level: LogLevel.Info);
    return (message as LelantusFeeData).fee;
  }
  // int fee;
  // int size;
  //
  // for (fee = 0;;) {
  //   int currentRequired = spendAmount;
  //
  // TODO: investigate the bug here
  //   var map = await getCoinsToJoinSplit(currentRequired);
  //   if (map is bool && !map) {
  //     return 0;
  //   }
  //
  //   List<DartLelantusEntry> coinsToBeSpent =
  //       map['coinsToSpend'] as List<DartLelantusEntry>;
  //
  //   // 1054 is constant part, mainly Schnorr and Range proofs, 2560 is for each sigma/aux data
  //   // 179 other parts of tx, assuming 1 utxo and 1 jmint
  //   size = 1054 + 2560 * coinsToBeSpent.length + 180;
  //   //        uint64_t feeNeeded = GetMinimumFee(size, DEFAULT_TX_CONFIRM_TARGET);
  //   int feeNeeded =
  //       size; //TODO(Levon) temporary, use real estimation methods here
  //
  //   if (fee >= feeNeeded) {
  //     break;
  //   }
  //
  //   fee = feeNeeded;
  // }
  //
  // return fee;

  @override
  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) async {
    int fee = await estimateJoinSplitFee(satoshiAmount);
    return fee;
  }

  Future<int> estimateFeeForPublic(int satoshiAmount, int feeRate) async {
    final available =
        Format.decimalAmountToSatoshis(await availablePublicBalance());

    if (available == satoshiAmount) {
      return satoshiAmount - sweepAllEstimate(feeRate);
    } else if (satoshiAmount <= 0 || satoshiAmount > available) {
      return roughFeeEstimate(1, 2, feeRate);
    }

    int runningBalance = 0;
    int inputCount = 0;
    for (final output in _outputsList) {
      runningBalance += output.value;
      inputCount++;
      if (runningBalance > satoshiAmount) {
        break;
      }
    }

    final oneOutPutFee = roughFeeEstimate(inputCount, 1, feeRate);
    final twoOutPutFee = roughFeeEstimate(inputCount, 2, feeRate);

    if (runningBalance - satoshiAmount > oneOutPutFee) {
      if (runningBalance - satoshiAmount > oneOutPutFee + DUST_LIMIT) {
        final change = runningBalance - satoshiAmount - twoOutPutFee;
        if (change > DUST_LIMIT &&
            runningBalance - satoshiAmount - change == twoOutPutFee) {
          return runningBalance - satoshiAmount - change;
        } else {
          return runningBalance - satoshiAmount;
        }
      } else {
        return runningBalance - satoshiAmount;
      }
    } else if (runningBalance - satoshiAmount == oneOutPutFee) {
      return oneOutPutFee;
    } else {
      return twoOutPutFee;
    }
  }

  // TODO: correct formula for firo?
  int roughFeeEstimate(int inputCount, int outputCount, int feeRatePerKB) {
    return ((181 * inputCount) + (34 * outputCount) + 10) *
        (feeRatePerKB / 1000).ceil();
  }

  int sweepAllEstimate(int feeRate) {
    int available = 0;
    int inputCount = 0;
    for (final output in _outputsList) {
      if (output.status.confirmed) {
        available += output.value;
        inputCount++;
      }
    }

    // transaction will only have 1 output minus the fee
    final estimatedFee = roughFeeEstimate(inputCount, 1, feeRate);

    return available - estimatedFee;
  }

  Future<List<Map<String, dynamic>>> fastFetch(List<String> allTxHashes) async {
    List<Map<String, dynamic>> allTransactions = [];

    const futureLimit = 30;
    List<Future<Map<String, dynamic>>> transactionFutures = [];
    int currentFutureCount = 0;
    for (final txHash in allTxHashes) {
      Future<Map<String, dynamic>> transactionFuture =
          cachedElectrumXClient.getTransaction(
        txHash: txHash,
        verbose: true,
        coin: coin,
      );
      transactionFutures.add(transactionFuture);
      currentFutureCount++;
      if (currentFutureCount > futureLimit) {
        currentFutureCount = 0;
        await Future.wait(transactionFutures);
        for (final fTx in transactionFutures) {
          final tx = await fTx;
          // delete unused large parts
          tx.remove("hex");
          tx.remove("lelantusData");

          allTransactions.add(tx);
        }
      }
    }
    if (currentFutureCount != 0) {
      currentFutureCount = 0;
      await Future.wait(transactionFutures);
      for (final fTx in transactionFutures) {
        final tx = await fTx;
        // delete unused large parts
        tx.remove("hex");
        tx.remove("lelantusData");

        allTransactions.add(tx);
      }
    }
    return allTransactions;
  }

  Future<List<models.Transaction>> getJMintTransactions(
    CachedElectrumX cachedClient,
    List<String> transactions,
    String currency,
    Coin coin,
    Decimal currentPrice,
    String locale,
  ) async {
    try {
      List<models.Transaction> txs = [];
      List<Map<String, dynamic>> allTransactions =
          await fastFetch(transactions);

      for (int i = 0; i < allTransactions.length; i++) {
        try {
          final tx = allTransactions[i];

          tx["confirmed_status"] =
              tx["confirmations"] != null && tx["confirmations"] as int > 0;
          tx["timestamp"] = tx["time"];
          tx["txType"] = "Sent";

          var sendIndex = 1;
          if (tx["vout"][0]["value"] != null &&
              Decimal.parse(tx["vout"][0]["value"].toString()) > Decimal.zero) {
            sendIndex = 0;
          }
          tx["amount"] = tx["vout"][sendIndex]["value"];

          tx["address"] = tx["vout"][sendIndex]["scriptPubKey"]["addresses"][0];

          tx["fees"] = tx["vin"][0]["nFees"];
          tx["inputSize"] = tx["vin"].length;
          tx["outputSize"] = tx["vout"].length;

          final decimalAmount = Decimal.parse(tx["amount"].toString());

          tx["worthNow"] = Format.localizedStringAsFixed(
            value: currentPrice * decimalAmount,
            locale: locale,
            decimalPlaces: 2,
          );
          tx["worthAtBlockTimestamp"] = tx["worthNow"];

          tx["subType"] = "join";
          txs.add(models.Transaction.fromLelantusJson(tx));
        } catch (e, s) {
          Logging.instance.log(
              "Exception caught in getJMintTransactions(): $e\n$s",
              level: LogLevel.Info);
          rethrow;
        }
      }
      return txs;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown in getJMintTransactions(): $e\n$s",
          level: LogLevel.Info);
      rethrow;
    }
  }

  @override
  Future<bool> generateNewAddress() async {
    try {
      await incrementAddressIndexForChain(
          0); // First increment the receiving index
      final newReceivingIndex =
          DB.instance.get<dynamic>(boxName: walletId, key: 'receivingIndex')
              as int; // Check the new receiving index
      final newReceivingAddress = await _generateAddressForChain(0,
          newReceivingIndex); // Use new index to derive a new receiving address
      await addToAddressesArrayForChain(newReceivingAddress,
          0); // Add that new receiving address to the array of receiving addresses
      _currentReceivingAddress = Future(() =>
          newReceivingAddress); // Set the new receiving address that the service

      return true;
    } catch (e, s) {
      Logging.instance.log(
          "Exception rethrown from generateNewAddress(): $e\n$s",
          level: LogLevel.Error);
      return false;
    }
  }

  Future<Decimal> availablePrivateBalance() async {
    return (await balances)[0];
  }

  Future<Decimal> availablePublicBalance() async {
    return (await balances)[4];
  }
}
